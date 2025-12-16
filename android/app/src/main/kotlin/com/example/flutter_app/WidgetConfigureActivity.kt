package com.example.flutter_app

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle

/**
 * 위젯 설정 액티비티
 * 위젯 추가 시 Flutter 앱의 위젯 관리 화면을 열어 사용자가 위젯 설정을 선택하도록 함
 */
class WidgetConfigureActivity : Activity() {
    
    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // 위젯 추가 취소 시 결과 설정
        setResult(RESULT_CANCELED)
        
        // 위젯 ID 가져오기
        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID
        
        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }
        
        // Flutter 앱의 위젯 관리 화면으로 이동
        val intent = Intent(this, MainActivity::class.java).apply {
            action = "ACTION_CONFIGURE_WIDGET"
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        
        startActivityForResult(intent, REQUEST_WIDGET_CONFIG)
    }
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == REQUEST_WIDGET_CONFIG) {
            if (resultCode == RESULT_OK) {
                // 위젯 설정 완료
                val appWidgetManager = AppWidgetManager.getInstance(this)
                NotionWidgetProvider.updateAppWidget(this, appWidgetManager, appWidgetId)
                
                // 결과 반환
                val resultValue = Intent().apply {
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                }
                setResult(RESULT_OK, resultValue)
            } else {
                // 위젯 설정 취소
                setResult(RESULT_CANCELED)
            }
            finish()
        }
    }
    
    companion object {
        private const val REQUEST_WIDGET_CONFIG = 1001
    }
}
