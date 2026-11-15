package io.github.artemchikolaev.birka

import android.app.Activity
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.ContactsContract.CommonDataKinds.Phone
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var picking: MethodChannel.Result? = null

    // The widgets of the home screen and what opens Birka from outside its
    // window (ADR 0031): the action waits here until Dart asks for it, and
    // the later ones go to Dart as they come.
    private var widgets: MethodChannel? = null
    private var pendingAction: String? = null
    private var listening = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        take(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        take(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // The people of the debts (ADR 0030): the window of the contacts, an
        // SMS and the window of sharing.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "birka/people")
            .setMethodCallHandler { call, result ->
                val text = call.argument<String>("text").orEmpty()
                when (call.method) {
                    "pickContact" -> pickContact(result)
                    "sendSms" -> {
                        sendSms(call.argument<String>("number").orEmpty(), text)
                        result.success(null)
                    }
                    "share" -> {
                        share(text)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        // The settings of Birka, where its camera can be allowed (ADR 0032).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "birka/settings")
            .setMethodCallHandler { call, result ->
                if (call.method == "open") {
                    openSettings()
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
        widgets = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "birka/widgets").apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "show" -> {
                        (call.arguments as? String)?.let { keep(it) }
                        result.success(null)
                    }
                    "canPin" -> result.success(canPin())
                    "pin" -> result.success(pin())
                    "takeAction" -> {
                        listening = true
                        result.success(pendingAction)
                        pendingAction = null
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    // `birka://<action>` from a widget or a shortcut of the icon, and
    // `birka://pinned` once the launcher added «Сегодня».
    private fun take(intent: Intent?) {
        val uri = intent?.data ?: return
        if (uri.scheme != "birka") return
        val action = uri.host ?: return
        when {
            action == PINNED -> widgets?.invokeMethod("pinned", null)
            listening -> widgets?.invokeMethod("open", action)
            else -> pendingAction = action
        }
    }

    // The figures of the day go where the widgets read them, and they draw
    // them at once.
    private fun keep(snapshot: String) {
        getSharedPreferences(WidgetSnapshot.PREFERENCES, MODE_PRIVATE).edit()
            .putString(WidgetSnapshot.KEY, snapshot).apply()
        TodayWidgetProvider.drawAll(this)
        RecordWidgetProvider.drawAll(this)
    }

    private fun canPin(): Boolean =
        Build.VERSION.SDK_INT >= 26 && AppWidgetManager.getInstance(this).isRequestPinAppWidgetSupported

    // Asks the launcher to add «Сегодня»; it comes back as birka://pinned
    // once it did.
    private fun pin(): Boolean {
        if (!canPin()) return false
        val callback = PendingIntent.getActivity(
            this,
            PINNED.hashCode(),
            Intent(Intent.ACTION_VIEW, Uri.parse("birka://$PINNED"), this, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        return AppWidgetManager.getInstance(this).requestPinAppWidget(
            ComponentName(this, TodayWidgetProvider::class.java),
            null,
            callback,
        )
    }

    // A number of a contact: the window gives Birka that one alone, so Birka
    // asks for no access to the address book.
    private fun openSettings() {
        val intent = Intent(
            android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.fromParts("package", packageName, null),
        )
        try {
            startActivity(intent)
        } catch (_: ActivityNotFoundException) {
            // A phone without the page of the app keeps the scanner open.
        }
    }

    private fun pickContact(result: MethodChannel.Result) {
        if (picking != null) return result.success(null)
        picking = result
        try {
            @Suppress("DEPRECATION")
            startActivityForResult(Intent(Intent.ACTION_PICK, Phone.CONTENT_URI), PICK_CONTACT)
        } catch (error: ActivityNotFoundException) {
            finishPicking(null)
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != PICK_CONTACT) return
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) return finishPicking(null)
        val columns = arrayOf(Phone.DISPLAY_NAME, Phone.NUMBER, Phone.TYPE, Phone.LABEL)
        val picked = contentResolver.query(uri, columns, null, null, null)?.use { cursor ->
            if (!cursor.moveToFirst()) return@use null
            val name = cursor.getString(0).orEmpty()
            val label = Phone.getTypeLabel(resources, cursor.getInt(2), cursor.getString(3))
            mapOf(
                "name" to name,
                "givenName" to name.trim().substringBefore(' '),
                "numbers" to listOf(
                    mapOf("label" to label.toString(), "number" to cursor.getString(1).orEmpty()),
                ),
            )
        }
        finishPicking(picked)
    }

    private fun finishPicking(value: Any?) {
        picking?.success(value)
        picking = null
    }

    private fun sendSms(number: String, text: String) {
        val sms = Intent(Intent.ACTION_SENDTO, Uri.parse("smsto:" + Uri.encode(number)))
            .putExtra("sms_body", text)
        try {
            startActivity(sms)
        } catch (error: ActivityNotFoundException) {
            share(text)
        }
    }

    private fun share(text: String) {
        val send = Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT, text)
        startActivity(Intent.createChooser(send, null))
    }

    private companion object {
        const val PICK_CONTACT = 4130

        // What the launcher says once it added «Сегодня» (ADR 0031).
        const val PINNED = "pinned"
    }
}
