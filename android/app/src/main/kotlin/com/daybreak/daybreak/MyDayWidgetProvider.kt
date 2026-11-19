package com.daybreak.daybreak

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class MyDayWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.my_day_widget)
            val widgetData = HomeWidgetPlugin.getData(context)

            val greeting = widgetData.getString("daybreak_greeting", "My Day 🌅")
            val date = widgetData.getString("daybreak_date", "Today")
            val total = widgetData.getInt("daybreak_total_count", 0)
            val completed = widgetData.getInt("daybreak_completed_count", 0)
            val topTask = widgetData.getString("daybreak_top_task", "No tasks in My Day yet")

            views.setTextViewText(R.id.widget_greeting, greeting)
            views.setTextViewText(R.id.widget_date, date)
            views.setTextViewText(R.id.widget_progress, "$completed/$total")
            views.setTextViewText(R.id.widget_task_headline, topTask)

            // Launch app on tap
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
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            // Quick add button launches app to quick add
            val addIntent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse("daybreak://action/add-task")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val addPendingIntent = PendingIntent.getActivity(
                context,
                1,
                addIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_btn_add, addPendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
