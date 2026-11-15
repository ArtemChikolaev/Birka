package io.github.artemchikolaev.birka

import android.content.Context
import org.json.JSONException
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/** The figures of one day, as the app writes them (ADR 0031, version 1). */
data class WidgetDay(
    val day: String,
    val kind: String,
    val label: String,
    val labelShort: String,
    val figure: String,
    val of: String,
    val ofShort: String,
    val spent: String,
    val spentShort: String,
    val share: Double,
) {
    /** Whether the day shows what today took, with no salary to count until. */
    val spentOnly: Boolean get() = kind == "spent"

    /** Whether today took more than its share. */
    val over: Boolean get() = kind == "over"
}

/**
 * What the app handed over last: today and tomorrow, and the words of the
 * widgets in the language of the app. The widgets never read the ledger.
 */
class WidgetSnapshot(val days: List<WidgetDay>, private val words: Map<String, String>) {
    /** The figures of today in the calendar of the phone, if the app sent them. */
    fun today(): WidgetDay? {
        val key = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        return days.firstOrNull { it.day == key }
    }

    /** The word [key] of the app, or [fallback] in the language of the phone. */
    fun word(key: String, fallback: String): String = words[key] ?: fallback

    companion object {
        /** Where the app keeps the snapshot for its widgets. */
        const val PREFERENCES = "birka_widgets"

        /** The key of the snapshot there. */
        const val KEY = "snapshot"

        /** The snapshot the app wrote last, if this version can read it. */
        fun read(context: Context): WidgetSnapshot? {
            val json = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
                .getString(KEY, null) ?: return null
            return try {
                parse(JSONObject(json))
            } catch (error: JSONException) {
                null
            }
        }

        private fun parse(json: JSONObject): WidgetSnapshot? {
            if (json.optInt("v") != 1) return null
            val days = json.optJSONArray("days") ?: return null
            val list = (0 until days.length()).map { index ->
                val day = days.getJSONObject(index)
                WidgetDay(
                    day = day.getString("day"),
                    kind = day.getString("kind"),
                    label = day.getString("label"),
                    labelShort = day.getString("labelShort"),
                    figure = day.getString("figure"),
                    of = day.getString("of"),
                    ofShort = day.getString("ofShort"),
                    spent = day.getString("spent"),
                    spentShort = day.getString("spentShort"),
                    share = day.optDouble("share", 0.0),
                )
            }
            val words = json.optJSONObject("words")?.let { given ->
                given.keys().asSequence().associateWith { given.getString(it) }
            } ?: emptyMap()
            return WidgetSnapshot(list, words)
        }
    }
}
