package com.example.flutter_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Notion Widget Provider - 홈화면 위젯
 */
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

    override fun onEnabled(context: Context) {
        // 첫 위젯 추가 시
        super.onEnabled(context)
    }

    override fun onDisabled(context: Context) {
        // 마지막 위젯 제거 시
        super.onDisabled(context)
    }

    companion object {
        private const val ACTION_ITEM_CLICK = "com.example.flutter_app.ACTION_ITEM_CLICK"
        const val EXTRA_PAGE_URL = "page_url"

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.notion_widget_layout)

            // 데이터베이스 제목 설정
            val databaseTitle = widgetData.getString("database_title", "Notion Widget")
            views.setTextViewText(R.id.widget_title, databaseTitle)

            // 페이지 개수
            val pageCount = widgetData.getInt("page_count", 0)
            val countText = if (pageCount > 0) "$pageCount items" else "No pages"
            views.setTextViewText(R.id.widget_count, countText)

            // ListView를 위한 RemoteViews Service 설정
            val serviceIntent = Intent(context, NotionWidgetService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
            }
            views.setRemoteAdapter(R.id.widget_list, serviceIntent)

            // ListView 아이템 클릭 시 처리할 Intent Template
            val clickIntent = Intent(context, NotionWidgetProvider::class.java).apply {
                action = ACTION_ITEM_CLICK
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            }
            val clickPendingIntent = PendingIntent.getBroadcast(
                context,
                0,
                clickIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            )
            views.setPendingIntentTemplate(R.id.widget_list, clickPendingIntent)

            // 헤더 클릭 시 앱 열기
            val appIntent = Intent(context, MainActivity::class.java)
            val appPendingIntent = PendingIntent.getActivity(
                context,
                0,
                appIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_header, appPendingIntent)

            // 위젯 업데이트
            appWidgetManager.updateAppWidget(appWidgetId, views)
            appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.widget_list)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        if (intent.action == ACTION_ITEM_CLICK) {
            val pageUrl = intent.getStringExtra(EXTRA_PAGE_URL)
            if (pageUrl != null) {
                // 브라우저에서 Notion 페이지 열기
                val browserIntent = Intent(Intent.ACTION_VIEW, Uri.parse(pageUrl)).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                context.startActivity(browserIntent)
            }
        }
    }
}
