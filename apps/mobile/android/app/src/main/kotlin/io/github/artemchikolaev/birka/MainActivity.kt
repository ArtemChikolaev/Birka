package io.github.artemchikolaev.birka

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.provider.ContactsContract.CommonDataKinds.Phone
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var picking: MethodChannel.Result? = null

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
    }

    // A number of a contact: the window gives Birka that one alone, so Birka
    // asks for no access to the address book.
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
    }
}
