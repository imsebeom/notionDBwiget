package com.example.flutter_app

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.flutter_app/widget"
    private var configureWidgetId: Int = AppWidgetManager.INVALID_APPWIDGET_ID
    private var methodChannel: MethodChannel? = null
    private var pendingIntent: Intent? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Setup method channel handler when Flutter engine is ready
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
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

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Save pending intent to handle after Flutter is ready
        pendingIntent = intent
    }
    
    override fun onResume() {
        super.onResume()
        
        // Handle pending intent when activity resumes and Flutter is ready
        // Add delay to ensure Flutter UI is fully initialized
        pendingIntent?.let { intent ->
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                handleIntent(intent)
                pendingIntent = null
            }, 1000) // 1 second delay
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        // Make sure method channel is ready
        if (methodChannel == null) {
            pendingIntent = intent
            return
        }
        
        when (intent?.action) {
            "ACTION_ADD_PAGE" -> {
                methodChannel?.invokeMethod("showAddPageDialog", null)
            }
            "ACTION_REFRESH_DATA" -> {
                methodChannel?.invokeMethod("refreshData", null)
            }
            "ACTION_CONFIGURE_WIDGET" -> {
                // Save widget ID for later use
                configureWidgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
                
                // Notify Flutter to show widget configuration screen
                val args = mapOf("widgetId" to configureWidgetId)
                methodChannel?.invokeMethod("configureWidget", args)
            }
        }
    }
    
    override fun onDestroy() {
        methodChannel?.setMethodCallHandler(null)
        super.onDestroy()
    }
}
