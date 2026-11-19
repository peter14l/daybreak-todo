package com.daybreak.daybreak

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class FocusWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.focus_widget)
            val widgetData = HomeWidgetPlugin.getData(context)

            val topTask = widgetData.getString("daybreak_top_task", "Focus on your day")
            val total = widgetData.getInt("daybreak_total_count", 0)
            val completed = widgetData.getInt("daybreak_completed_count", 0)
            val remaining = (total - completed).coerceAtLeast(0)

            views.setTextViewText(R.id.focus_task_title, topTask)
            views.setTextViewText(R.id.focus_remaining_badge, "$remaining left")

            val intent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse("daybreak://view/my-day")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.focus_widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
