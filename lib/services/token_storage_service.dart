import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 안전한 토큰 저장 서비스
class TokenStorageService {
  static const String _keyAccessToken = 'notion_access_token';
  static const String _keyDatabaseId = 'notion_database_id';
  static const String _keyDatabaseTitle = 'notion_database_title';
  static const String _keyViewId = 'notion_view_id';
  static const String _keyViewName = 'notion_view_name';
  static const String _keyWorkspaceId = 'notion_workspace_id';
  static const String _keyWorkspaceName = 'notion_workspace_name';
  static const String _keyBotId = 'notion_bot_id';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  /// Access Token 저장
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _keyAccessToken, value: token);
  }

  /// Access Token 가져오기
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  /// Database ID 저장
  Future<void> saveDatabaseId(String databaseId) async {
    await _storage.write(key: _keyDatabaseId, value: databaseId);
  }

  /// Database ID 가져오기
  Future<String?> getDatabaseId() async {
    return await _storage.read(key: _keyDatabaseId);
  }

  /// Database Title 저장
  Future<void> saveDatabaseTitle(String title) async {
    await _storage.write(key: _keyDatabaseTitle, value: title);
  }

  /// Database Title 가져오기
  Future<String?> getDatabaseTitle() async {
    return await _storage.read(key: _keyDatabaseTitle);
  }

  /// Workspace ID 저장
  Future<void> saveWorkspaceId(String workspaceId) async {
    await _storage.write(key: _keyWorkspaceId, value: workspaceId);
  }

  /// Workspace ID 가져오기
  Future<String?> getWorkspaceId() async {
    return await _storage.read(key: _keyWorkspaceId);
  }

  /// Workspace Name 저장
  Future<void> saveWorkspaceName(String workspaceName) async {
    await _storage.write(key: _keyWorkspaceName, value: workspaceName);
  }

  /// Workspace Name 가져오기
  Future<String?> getWorkspaceName() async {
    return await _storage.read(key: _keyWorkspaceName);
  }

  /// Bot ID 저장
  Future<void> saveBotId(String botId) async {
    await _storage.write(key: _keyBotId, value: botId);
  }

  /// Bot ID 가져오기
  Future<String?> getBotId() async {
    return await _storage.read(key: _keyBotId);
  }

  /// View ID 저장
  Future<void> saveViewId(String viewId) async {
    await _storage.write(key: _keyViewId, value: viewId);
  }

  /// View ID 가져오기
  Future<String?> getViewId() async {
    return await _storage.read(key: _keyViewId);
  }

  /// View Name 저장
  Future<void> saveViewName(String viewName) async {
    await _storage.write(key: _keyViewName, value: viewName);
  }

  /// View Name 가져오기
  Future<String?> getViewName() async {
    return await _storage.read(key: _keyViewName);
  }

  /// 모든 데이터 삭제
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// 인증 여부 확인
  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// 데이터베이스 선택 여부 확인
  Future<bool> isDatabaseSelected() async {
    final databaseId = await getDatabaseId();
    return databaseId != null && databaseId.isNotEmpty;
  }

  /// View 선택 여부 확인
  Future<bool> isViewSelected() async {
    final viewId = await getViewId();
    return viewId != null && viewId.isNotEmpty;
  }
}
