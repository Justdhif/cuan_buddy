package com.cuanbuddy.cuan_buddy_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class SavingsWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_savings_layout).apply {
                val emoji = widgetData.getString("savings_emoji", "🎯")
                val name = widgetData.getString("savings_name", "No Goal Selected")
                val progressText = widgetData.getString("savings_progress_text", "Rp 0 / Rp 0")
                val percentString = widgetData.getString("savings_percent", "0")
                val percent = percentString?.toIntOrNull() ?: 0

                setTextViewText(R.id.widget_savings_emoji, emoji)
                setTextViewText(R.id.widget_savings_name, name)
                setTextViewText(R.id.widget_savings_progress_text, progressText)
                setProgressBar(R.id.widget_savings_progress_bar, 100, percent, false)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
