package io.github.artemchikolaev.birka

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import kotlin.math.roundToInt

/**
 * «Сегодня», 4 × 2 cells (ADR 0031): what can still be spent today out of the
 * share of the day, and a new expense or income in one tap. It turns coral
 * over the share and shows what today took without a salary to count until.
 */
class TodayWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) =
        draw(context, manager, ids)

    companion object {
        /** Draws every «Сегодня» on the home screen again. */
        fun drawAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            draw(context, manager, manager.getAppWidgetIds(ComponentName(context, TodayWidgetProvider::class.java)))
        }

        fun draw(context: Context, manager: AppWidgetManager, ids: IntArray) {
            if (ids.isEmpty()) return
            val snapshot = WidgetSnapshot.read(context)
            val day = snapshot?.today()
            fun word(key: String, fallback: Int): String =
                snapshot?.word(key, context.getString(fallback)) ?: context.getString(fallback)
            val bar = day != null && !day.spentOnly
            val over = day?.over == true
            val views = RemoteViews(context.packageName, R.layout.widget_today)
            views.setTextViewText(R.id.today_label, (day?.label ?: word("label", R.string.widget_label)).uppercase())
            views.setTextViewText(R.id.today_figure, day?.figure ?: "—")
            views.setTextColor(
                R.id.today_figure,
                context.getColor(if (over) R.color.widget_coral else R.color.widget_ink),
            )
            views.setTextViewText(R.id.today_of, day?.of ?: word("open", R.string.widget_open))
            val progress = ((day?.share ?: 0.0).coerceIn(0.0, 1.0) * 100).roundToInt()
            views.setProgressBar(R.id.today_bar, 100, progress, false)
            views.setProgressBar(R.id.today_bar_over, 100, 100, false)
            views.setViewVisibility(R.id.today_bar, if (bar && !over) View.VISIBLE else View.GONE)
            views.setViewVisibility(R.id.today_bar_over, if (bar && over) View.VISIBLE else View.GONE)
            views.setTextViewText(R.id.today_spent, day?.spent ?: "")
            views.setViewVisibility(R.id.today_spent, if (bar) View.VISIBLE else View.GONE)
            views.setTextViewText(R.id.today_expense, word("expense", R.string.widget_expense))
            views.setTextViewText(R.id.today_income, word("income", R.string.widget_income))
            views.setOnClickPendingIntent(
                R.id.today_root,
                opening(context, if (day?.spentOnly == true) "payday" else "overview"),
            )
            views.setOnClickPendingIntent(R.id.today_expense, opening(context, "expense"))
            views.setOnClickPendingIntent(R.id.today_income, opening(context, "income"))
            manager.updateAppWidget(ids, views)
        }

        /** Opens Birka on [action], as the shortcuts of its icon do. */
        fun opening(context: Context, action: String): PendingIntent {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse("birka://$action"), context, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            return PendingIntent.getActivity(
                context,
                action.hashCode(),
                intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
        }
    }
}
