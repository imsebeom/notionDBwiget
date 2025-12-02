import 'package:home_widget/home_widget.dart';
import '../models/notion_page.dart';

/// 안드로이드 홈 화면 위젯 서비스
class WidgetService {
  static const String _widgetName = 'NotionWidgetProvider';

  /// 위젯에 페이지 목록 업데이트
  Future<void> updateWidget(List<NotionPage> pages, String databaseTitle) async {
    try {
      // 위젯에 표시할 데이터 준비 (최대 10개)
      final displayPages = pages.take(10).toList();
      
      // 데이터베이스 제목 저장
      await HomeWidget.saveWidgetData<String>('database_title', databaseTitle);
      
      // 페이지 개수 저장
      await HomeWidget.saveWidgetData<int>('page_count', displayPages.length);
      
      // 각 페이지 정보 저장
      for (int i = 0; i < displayPages.length; i++) {
        final page = displayPages[i];
        await HomeWidget.saveWidgetData<String>('page_${i}_title', page.title);
        await HomeWidget.saveWidgetData<String>('page_${i}_icon', page.icon ?? '📄');
        await HomeWidget.saveWidgetData<String>('page_${i}_id', page.id);
        
        // Notion 페이지 URL 저장 (웹에서 열기 위함)
        final pageUrl = 'https://www.notion.so/${page.id.replaceAll("-", "")}';
        await HomeWidget.saveWidgetData<String>('page_${i}_url', pageUrl);
      }
      
      // 마지막 업데이트 시간
      await HomeWidget.saveWidgetData<String>(
        'last_update',
        DateTime.now().toIso8601String(),
      );
      
      // 위젯 업데이트 트리거
      await HomeWidget.updateWidget(
        name: _widgetName,
        androidName: _widgetName,
      );
    } catch (e) {
      // 위젯 업데이트 실패 시 무시
    }
  }

  /// 위젯 데이터 초기화
  Future<void> clearWidget() async {
    try {
      await HomeWidget.saveWidgetData<String>('database_title', 'Not Connected');
      await HomeWidget.saveWidgetData<int>('page_count', 0);
      
      await HomeWidget.updateWidget(
        name: _widgetName,
        androidName: _widgetName,
      );
    } catch (e) {
      // 위젯 초기화 실패 시 무시
    }
  }

  /// 위젯에서 앱 실행 시 처리할 액션 등록
  Future<void> registerInteractivity() async {
    try {
      HomeWidget.widgetClicked.listen((uri) {
        // 위젯 클릭 시 처리
        // URI를 통해 어떤 페이지가 클릭되었는지 확인 가능
      });
    } catch (e) {
      // 인터랙션 등록 실패 시 무시
    }
  }
}
