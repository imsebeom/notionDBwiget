import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/notion_page.dart';
import '../models/notion_database.dart';

/// Notion API 서비스
class NotionService {
  static const String baseUrl = 'https://api.notion.com/v1';
  static const String notionVersion = '2022-06-28';

  final String apiKey;

  NotionService({required this.apiKey});

  /// HTTP 헤더 생성
  Map<String, String> _getHeaders() {
    return {
      'Authorization': 'Bearer $apiKey',
      'Notion-Version': notionVersion,
      'Content-Type': 'application/json',
    };
  }

  /// 디버그 로그 출력
  void _logDebug(String message, {dynamic data}) {
    if (kDebugMode) {
      if (data != null) {
        debugPrint('🔍 NotionService: $message - $data');
      } else {
        debugPrint('🔍 NotionService: $message');
      }
    }
  }

  /// 데이터베이스 정보 가져오기
  Future<NotionDatabase?> getDatabase(String databaseId) async {
    try {
      _logDebug('Fetching database', data: databaseId);
      
      final response = await http.get(
        Uri.parse('$baseUrl/databases/$databaseId'),
        headers: _getHeaders(),
      );

      _logDebug('Database response status', data: response.statusCode);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _logDebug('Database data received', data: data['title']);
        return NotionDatabase.fromJson(data);
      } else {
        _logDebug('Database fetch failed', data: response.body);
        return null;
      }
    } catch (e) {
      _logDebug('Database fetch error', data: e.toString());
      return null;
    }
  }

  /// 데이터베이스의 페이지 목록 가져오기
  Future<List<NotionPage>> getDatabasePages(String databaseId, {int pageSize = 100}) async {
    try {
      _logDebug('Fetching pages from database', data: databaseId);
      
      final response = await http.post(
        Uri.parse('$baseUrl/databases/$databaseId/query'),
        headers: _getHeaders(),
        body: jsonEncode({
          'page_size': pageSize,
          'sorts': [
            {
              'timestamp': 'last_edited_time',
              'direction': 'descending',
            }
          ],
        }),
      );

      _logDebug('Pages response status', data: response.statusCode);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List;
        
        _logDebug('Pages count', data: results.length);
        
        return results
            .map((item) => NotionPage.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _logDebug('Pages fetch failed', data: response.body);
        return [];
      }
    } catch (e) {
      _logDebug('Pages fetch error', data: e.toString());
      return [];
    }
  }

  /// API 키 유효성 검증
  Future<bool> validateApiKey() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// 데이터베이스 ID 유효성 검증
  Future<bool> validateDatabaseId(String databaseId) async {
    try {
      final database = await getDatabase(databaseId);
      return database != null;
    } catch (e) {
      return false;
    }
  }
}
