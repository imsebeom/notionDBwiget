import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/notion_page.dart';
import '../models/notion_database.dart';
import '../models/notion_view.dart';

/// Notion API 서비스 (OAuth 토큰 사용)
class NotionApiService {
  static const String baseUrl = 'https://api.notion.com/v1';
  static const String notionVersion = '2022-06-28';

  final String accessToken;

  NotionApiService({required this.accessToken});

  /// HTTP 헤더 생성
  Map<String, String> _getHeaders() {
    return {
      'Authorization': 'Bearer $accessToken',
      'Notion-Version': notionVersion,
      'Content-Type': 'application/json',
    };
  }

  /// 디버그 로그 출력
  void _logDebug(String message, {dynamic data}) {
    if (kDebugMode) {
      if (data != null) {
        debugPrint('🔍 NotionApiService: $message - $data');
      } else {
        debugPrint('🔍 NotionApiService: $message');
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

  /// 데이터베이스의 페이지 목록 가져오기 (필터와 정렬 지원)
  Future<List<NotionPage>> getDatabasePages(
    String databaseId, {
    int pageSize = 100,
    Map<String, dynamic>? filter,
    List<Map<String, dynamic>>? sorts,
  }) async {
    try {
      _logDebug('Fetching pages from database', data: databaseId);
      
      // 쿼리 바디 구성
      final Map<String, dynamic> queryBody = {
        'page_size': pageSize,
      };
      
      // 필터 추가 (있는 경우)
      if (filter != null) {
        queryBody['filter'] = filter;
        _logDebug('Applying filter', data: filter);
      }
      
      // 정렬 추가
      if (sorts != null && sorts.isNotEmpty) {
        queryBody['sorts'] = sorts;
        _logDebug('Applying sorts', data: sorts);
      } else {
        // 기본 정렬: 최근 수정일 기준
        queryBody['sorts'] = [
          {
            'timestamp': 'last_edited_time',
            'direction': 'descending',
          }
        ];
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/databases/$databaseId/query'),
        headers: _getHeaders(),
        body: jsonEncode(queryBody),
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
  
  /// 데이터베이스 프로퍼티 정보 가져오기 (필터 설정에 필요)
  Future<Map<String, dynamic>?> getDatabaseProperties(String databaseId) async {
    try {
      _logDebug('Fetching database properties', data: databaseId);
      
      final response = await http.get(
        Uri.parse('$baseUrl/databases/$databaseId'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final properties = data['properties'] as Map<String, dynamic>;
        _logDebug('Properties fetched', data: properties.keys.toList());
        return properties;
      } else {
        _logDebug('Properties fetch failed', data: response.body);
        return null;
      }
    } catch (e) {
      _logDebug('Properties fetch error', data: e.toString());
      return null;
    }
  }

  /// 사용자가 접근 가능한 데이터베이스 검색
  Future<List<NotionDatabase>> searchDatabases() async {
    try {
      _logDebug('Searching databases');
      
      final response = await http.post(
        Uri.parse('$baseUrl/search'),
        headers: _getHeaders(),
        body: jsonEncode({
          'filter': {
            'property': 'object',
            'value': 'database',
          },
          'sort': {
            'direction': 'descending',
            'timestamp': 'last_edited_time',
          },
        }),
      );

      _logDebug('Search response status', data: response.statusCode);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List;
        
        _logDebug('Databases found', data: results.length);
        
        return results
            .map((item) => NotionDatabase.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _logDebug('Search failed', data: response.body);
        return [];
      }
    } catch (e) {
      _logDebug('Search error', data: e.toString());
      return [];
    }
  }

  /// 데이터베이스의 보기(View) 목록 가져오기
  /// 참고: Notion API는 공식적으로 View를 직접 조회하는 엔드포인트를 제공하지 않습니다.
  /// 데이터베이스 정보에서 View 정보를 추출합니다.
  Future<List<NotionView>> getDatabaseViews(String databaseId) async {
    try {
      _logDebug('Fetching database views', data: databaseId);
      
      final response = await http.get(
        Uri.parse('$baseUrl/databases/$databaseId'),
        headers: _getHeaders(),
      );

      _logDebug('Database views response status', data: response.statusCode);

      if (response.statusCode == 200) {
        // Notion API는 공식적으로 View 목록을 제공하지 않으므로
        // 기본 View를 생성하여 반환합니다
        final views = <NotionView>[
          NotionView(
            id: 'default',
            name: 'All Pages',
            type: 'table',
          ),
        ];
        
        _logDebug('Database views found', data: views.length);
        return views;
      } else {
        _logDebug('Database views fetch failed', data: response.body);
        return [];
      }
    } catch (e) {
      _logDebug('Database views fetch error', data: e.toString());
      return [];
    }
  }

  /// 특정 View의 페이지 목록 가져오기 (필터 적용)
  /// viewId가 'default'인 경우 모든 페이지를 반환
  Future<List<NotionPage>> getDatabasePagesByView(
    String databaseId,
    String viewId, {
    int pageSize = 100,
  }) async {
    try {
      _logDebug('Fetching pages from database view', data: '$databaseId / $viewId');
      
      // viewId가 'default'인 경우 기본 쿼리 사용
      if (viewId == 'default') {
        return getDatabasePages(databaseId, pageSize: pageSize);
      }
      
      // 실제 View 필터링은 Notion API의 제한으로 인해
      // 현재는 모든 페이지를 반환합니다
      return getDatabasePages(databaseId, pageSize: pageSize);
    } catch (e) {
      _logDebug('Pages by view fetch error', data: e.toString());
      return [];
    }
  }

  /// Access Token 유효성 검증
  Future<bool> validateToken() async {
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

  /// 데이터베이스에 새 페이지 생성
  Future<Map<String, dynamic>?> createPage({
    required String databaseId,
    required String title,
  }) async {
    try {
      _logDebug('Creating page in database', data: databaseId);
      
      final response = await http.post(
        Uri.parse('$baseUrl/pages'),
        headers: _getHeaders(),
        body: jsonEncode({
          'parent': {
            'database_id': databaseId,
          },
          'properties': {
            'title': {
              'title': [
                {
                  'text': {
                    'content': title,
                  },
                },
              ],
            },
          },
        }),
      );

      _logDebug('Create page response status', data: response.statusCode);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _logDebug('Page created', data: data['id']);
        return data;
      } else {
        _logDebug('Page creation failed', data: response.body);
        return null;
      }
    } catch (e) {
      _logDebug('Page creation error', data: e.toString());
      return null;
    }
  }
}
