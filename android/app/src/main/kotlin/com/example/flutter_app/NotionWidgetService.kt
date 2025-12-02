package com.example.flutter_app

import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * RemoteViewsService for ListView in Widget
 */
class NotionWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return NotionWidgetFactory(this.applicationContext)
    }
}

class NotionWidgetFactory(private val context: Context) : RemoteViewsService.RemoteViewsFactory {
    
    private data class PageItem(
        val title: String,
        val icon: String,
        val id: String,
        val url: String
    )
    
    private var pages: List<PageItem> = emptyList()

    override fun onCreate() {
        // Factory 생성 시
    }

    override fun onDataSetChanged() {
        // 데이터 업데이트 시 호출됨
        loadPages()
    }

    override fun onDestroy() {
        // Factory 파괴 시
        pages = emptyList()
    }

    override fun getCount(): Int {
        return pages.size
    }

    override fun getViewAt(position: Int): RemoteViews? {
        if (position >= pages.size) return null

        val page = pages[position]
        val views = RemoteViews(context.packageName, R.layout.notion_widget_item)

        // 페이지 정보 설정
        views.setTextViewText(R.id.page_icon, page.icon)
        views.setTextViewText(R.id.page_title, page.title)

        // 클릭 시 전달할 Intent
        val fillIntent = Intent().apply {
            putExtra(NotionWidgetProvider.EXTRA_PAGE_URL, page.url)
        }
        views.setOnClickFillInIntent(R.id.page_item_container, fillIntent)

        return views
    }

    override fun getLoadingView(): RemoteViews? {
        return null // 기본 로딩 뷰 사용
    }

    override fun getViewTypeCount(): Int {
        return 1 // 단일 뷰 타입
    }

    override fun getItemId(position: Int): Long {
        return position.toLong()
    }

    override fun hasStableIds(): Boolean {
        return true
    }

    private fun loadPages() {
        val widgetData = HomeWidgetPlugin.getData(context)
        val pageCount = widgetData.getInt("page_count", 0)
        
        val loadedPages = mutableListOf<PageItem>()
        
        for (i in 0 until pageCount) {
            val title = widgetData.getString("page_${i}_title", "Untitled") ?: "Untitled"
            val icon = widgetData.getString("page_${i}_icon", "📄") ?: "📄"
            val id = widgetData.getString("page_${i}_id", "") ?: ""
            val url = widgetData.getString("page_${i}_url", "") ?: ""
            
            if (id.isNotEmpty() && url.isNotEmpty()) {
                loadedPages.add(PageItem(title, icon, id, url))
            }
        }
        
        pages = loadedPages
    }
}
