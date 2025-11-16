import 'package:shared_preferences/shared_preferences.dart';

/// 로컬 저장소 서비스
class StorageService {
  static const String _keyApiKey = 'notion_api_key';
  static const String _keyDatabaseId = 'notion_database_id';

  /// API 키 저장
  Future<bool> saveApiKey(String apiKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_keyApiKey, apiKey);
    } catch (e) {
      return false;
    }
  }

  /// API 키 가져오기
  Future<String?> getApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyApiKey);
    } catch (e) {
      return null;
    }
  }

  /// 데이터베이스 ID 저장
  Future<bool> saveDatabaseId(String databaseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_keyDatabaseId, databaseId);
    } catch (e) {
      return false;
    }
  }

  /// 데이터베이스 ID 가져오기
  Future<String?> getDatabaseId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyDatabaseId);
    } catch (e) {
      return null;
    }
  }

  /// 모든 데이터 삭제
  Future<bool> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyApiKey);
      await prefs.remove(_keyDatabaseId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 설정이 완료되었는지 확인
  Future<bool> isConfigured() async {
    final apiKey = await getApiKey();
    final databaseId = await getDatabaseId();
    return apiKey != null && apiKey.isNotEmpty && 
           databaseId != null && databaseId.isNotEmpty;
  }
}
