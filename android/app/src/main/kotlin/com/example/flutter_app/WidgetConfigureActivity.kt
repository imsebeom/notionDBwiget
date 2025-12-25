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
        // MainActivity가 결과를 처리하고 자동으로 종료됨
        val intent = Intent(this, MainActivity::class.java).apply {
            action = "ACTION_CONFIGURE_WIDGET"
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            // MainActivity가 설정을 완료하면 자동으로 finish()됨
        }
        
        startActivity(intent)
        // WidgetConfigureActivity 즉시 종료
        // MainActivity가 설정 완료 후 자동으로 결과를 홈 화면에 전달함
        finish()
    }
}
