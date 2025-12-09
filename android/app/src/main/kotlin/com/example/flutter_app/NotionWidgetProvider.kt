package com.example.flutter_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.SystemClock
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
        
        // 주기적 업데이트 설정 (30분마다)
        setupPeriodicUpdate(context)
    }

    override fun onEnabled(context: Context) {
        // 첫 위젯 추가 시
        super.onEnabled(context)
        setupPeriodicUpdate(context)
    }

    override fun onDisabled(context: Context) {
        // 마지막 위젯 제거 시
        super.onDisabled(context)
        cancelPeriodicUpdate(context)
    }

    companion object {
        private const val ACTION_ITEM_CLICK = "com.example.flutter_app.ACTION_ITEM_CLICK"
        private const val ACTION_REFRESH = "com.example.flutter_app.ACTION_REFRESH"
        const val EXTRA_PAGE_URL = "page_url"
        private const val UPDATE_INTERVAL_MILLIS = 30 * 60 * 1000L // 30분

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

            // '+' 버튼 클릭 시 새 페이지 추가 다이얼로그 열기
            val addPageIntent = Intent(context, MainActivity::class.java).apply {
                action = "ACTION_ADD_PAGE"
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val addPagePendingIntent = PendingIntent.getActivity(
                context,
                1,
                addPageIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.add_page_button, addPagePendingIntent)

            // 새로고침 버튼 클릭 시 처리
            val refreshIntent = Intent(context, NotionWidgetProvider::class.java).apply {
                action = ACTION_REFRESH
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(appWidgetId))
            }
            val refreshPendingIntent = PendingIntent.getBroadcast(
                context,
                2,
                refreshIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.refresh_button, refreshPendingIntent)

            // 위젯 업데이트
            appWidgetManager.updateAppWidget(appWidgetId, views)
            appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.widget_list)
        }

        /**
         * 주기적 업데이트 설정 (30분마다)
         */
        private fun setupPeriodicUpdate(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, NotionWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            // 주기적 알람 설정 (30분마다)
            alarmManager.setRepeating(
                AlarmManager.ELAPSED_REALTIME,
                SystemClock.elapsedRealtime() + UPDATE_INTERVAL_MILLIS,
                UPDATE_INTERVAL_MILLIS,
                pendingIntent
            )
        }

        /**
         * 주기적 업데이트 취소
         */
        private fun cancelPeriodicUpdate(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, NotionWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            alarmManager.cancel(pendingIntent)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        when (intent.action) {
            ACTION_ITEM_CLICK -> {
                val pageUrl = intent.getStringExtra(EXTRA_PAGE_URL)
                if (pageUrl != null) {
                    // 브라우저에서 Notion 페이지 열기
                    val browserIntent = Intent(Intent.ACTION_VIEW, Uri.parse(pageUrl)).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                    context.startActivity(browserIntent)
                }
            }
            ACTION_REFRESH -> {
                // 새로고침: Flutter 앱에 데이터 갱신 요청
                val appIntent = Intent(context, MainActivity::class.java).apply {
                    action = "ACTION_REFRESH_DATA"
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                }
                context.startActivity(appIntent)
                
                // 위젯도 즉시 업데이트
                val appWidgetIds = intent.getIntArrayExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS)
                if (appWidgetIds != null) {
                    val appWidgetManager = AppWidgetManager.getInstance(context)
                    for (appWidgetId in appWidgetIds) {
                        updateAppWidget(context, appWidgetManager, appWidgetId)
                    }
                }
            }
        }
    }
}
