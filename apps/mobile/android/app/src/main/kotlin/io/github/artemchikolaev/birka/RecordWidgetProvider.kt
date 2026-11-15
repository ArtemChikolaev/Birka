package io.github.artemchikolaev.birka

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.widget.RemoteViews

/** «Запись», 2 × 1 cells (ADR 0031): a new operation in one tap, with no amounts. */
class RecordWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) =
        draw(context, manager, ids)

    companion object {
        /** Draws every «Запись» on the home screen again, in the language of the app. */
        fun drawAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            draw(context, manager, manager.getAppWidgetIds(ComponentName(context, RecordWidgetProvider::class.java)))
        }

        fun draw(context: Context, manager: AppWidgetManager, ids: IntArray) {
            if (ids.isEmpty()) return
            val fallback = context.getString(R.string.widget_new_operation)
            val views = RemoteViews(context.packageName, R.layout.widget_record)
            views.setTextViewText(
                R.id.record_label,
                WidgetSnapshot.read(context)?.word("newOperation", fallback) ?: fallback,
            )
            views.setOnClickPendingIntent(R.id.record_root, TodayWidgetProvider.opening(context, "expense"))
            manager.updateAppWidget(ids, views)
        }
    }
}
