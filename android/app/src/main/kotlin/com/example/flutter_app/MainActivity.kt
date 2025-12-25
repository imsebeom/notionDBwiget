package com.example.flutter_app

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.flutter_app/widget"
    private var configureWidgetId: Int = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Handle intent when activity is created
        handleIntent(intent)
        
        // Setup method channel handler
        flutterEngine?.dartExecutor?.binaryMessenger?.let {
            MethodChannel(it, CHANNEL).setMethodCallHandler { call, result ->
                when (call.method) {
                    "widgetConfigured" -> {
                        val widgetId = call.argument<Int>("widgetId")
                        val success = call.argument<Boolean>("success") ?: false
                        
                        if (widgetId != null && widgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
                            if (success) {
                                // Update widget
                                val appWidgetManager = AppWidgetManager.getInstance(this)
                                NotionWidgetProvider.updateAppWidget(this, appWidgetManager, widgetId)
                                
                                // Set result OK
                                val resultValue = Intent().apply {
                                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                                }
                                setResult(Activity.RESULT_OK, resultValue)
                            } else {
                                setResult(Activity.RESULT_CANCELED)
                            }
                            
                            // Close activity if it was launched for configuration
                            if (configureWidgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
                                finish()
                            }
                        }
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        when (intent?.action) {
            "ACTION_ADD_PAGE" -> {
                // Notify Flutter to show add page dialog
                flutterEngine?.dartExecutor?.binaryMessenger?.let {
                    MethodChannel(it, CHANNEL).invokeMethod("showAddPageDialog", null)
                }
            }
            "ACTION_REFRESH_DATA" -> {
                // Notify Flutter to refresh data
                flutterEngine?.dartExecutor?.binaryMessenger?.let {
                    MethodChannel(it, CHANNEL).invokeMethod("refreshData", null)
                }
            }
            "ACTION_CONFIGURE_WIDGET" -> {
                // Save widget ID for later use
                configureWidgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
                
                // Notify Flutter to show widget configuration screen
                flutterEngine?.dartExecutor?.binaryMessenger?.let {
                    val args = mapOf("widgetId" to configureWidgetId)
                    MethodChannel(it, CHANNEL).invokeMethod("configureWidget", args)
                }
            }
        }
    }
}
