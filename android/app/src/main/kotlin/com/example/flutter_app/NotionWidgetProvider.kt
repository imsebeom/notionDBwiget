package com.example.flutter_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class NotionWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val widgetData = HomeWidgetPlugin.getData(context)
        val views = RemoteViews(context.packageName, R.layout.notion_widget_layout)

        // 데이터베이스 제목 설정
        val databaseTitle = widgetData.getString("database_title", "Notion Pages")
        views.setTextViewText(R.id.widget_title, databaseTitle)

        // 페이지 개수 설정
        val pageCount = widgetData.getInt("page_count", 0)
        views.setTextViewText(R.id.widget_count, pageCount.toString())

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
