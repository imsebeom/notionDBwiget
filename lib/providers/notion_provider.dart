import 'package:flutter/foundation.dart';
import '../models/notion_page.dart';
import '../models/notion_database.dart';
import '../services/notion_service.dart';
import '../services/storage_service.dart';

/// Notion 데이터 상태 관리 Provider
class NotionProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  
  NotionService? _notionService;
  NotionDatabase? _database;
  List<NotionPage> _pages = [];
  bool _isLoading = false;
  String? _error;

  NotionDatabase? get database => _database;
  List<NotionPage> get pages => _pages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isConfigured => _notionService != null;

  /// 초기화 - 저장된 설정 불러오기
  Future<void> initialize() async {
    final apiKey = await _storageService.getApiKey();
    final databaseId = await _storageService.getDatabaseId();

    if (apiKey != null && databaseId != null) {
      _notionService = NotionService(apiKey: apiKey);
      await loadDatabase(databaseId);
    }
  }

  /// API 키와 데이터베이스 ID 설정
  Future<bool> configure(String apiKey, String databaseId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // API 키 형식 정리 (secret_ 접두사 제거)
      String cleanApiKey = apiKey.trim();
      if (cleanApiKey.startsWith('secret_')) {
        cleanApiKey = cleanApiKey;
      }

      // 데이터베이스 ID 형식 정리 (URL에서 ID 추출)
      String cleanDatabaseId = databaseId.trim();
      if (cleanDatabaseId.contains('notion.so/')) {
        // URL에서 데이터베이스 ID 추출
        final parts = cleanDatabaseId.split('?')[0].split('/');
        if (parts.isNotEmpty) {
          cleanDatabaseId = parts.last.replaceAll('-', '');
        }
      } else {
        cleanDatabaseId = cleanDatabaseId.replaceAll('-', '');
      }

      // Notion 서비스 생성
      final service = NotionService(apiKey: cleanApiKey);

      // API 키 검증
      if (kDebugMode) {
        debugPrint('🔑 Validating API key...');
      }
      final isValidKey = await service.validateApiKey();
      if (!isValidKey) {
        _error = '❌ Invalid API key\n\nPlease check:\n1. Token starts with "secret_"\n2. Integration has proper permissions\n3. Token is not expired';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      if (kDebugMode) {
        debugPrint('✅ API key validated');
      }

      // 데이터베이스 ID 검증
      if (kDebugMode) {
        debugPrint('🗄️ Fetching database: $cleanDatabaseId');
      }
      final database = await service.getDatabase(cleanDatabaseId);
      if (database == null) {
        _error = '❌ Database not found\n\nPlease check:\n1. Database ID is correct\n2. Integration is connected to this database\n3. Database is not deleted';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      if (kDebugMode) {
        debugPrint('✅ Database found: ${database.title}');
      }

      // 설정 저장
      await _storageService.saveApiKey(cleanApiKey);
      await _storageService.saveDatabaseId(cleanDatabaseId);

      // 상태 업데이트
      _notionService = service;
      _database = database;

      // 페이지 목록 불러오기
      await loadPages(cleanDatabaseId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Configuration failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 데이터베이스 정보 불러오기
  Future<void> loadDatabase(String databaseId) async {
    if (_notionService == null) return;

    try {
      _database = await _notionService!.getDatabase(databaseId);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading database: $e');
      }
    }
  }

  /// 페이지 목록 불러오기
  Future<void> loadPages(String databaseId) async {
    if (_notionService == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _pages = await _notionService!.getDatabasePages(databaseId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load pages: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 새로고침
  Future<void> refresh() async {
    final databaseId = await _storageService.getDatabaseId();
    if (databaseId != null) {
      await loadPages(databaseId);
    }
  }

  /// 설정 초기화
  Future<void> resetConfiguration() async {
    await _storageService.clearAll();
    _notionService = null;
    _database = null;
    _pages = [];
    _error = null;
    notifyListeners();
  }
}
