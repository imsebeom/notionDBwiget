import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

/// Notion OAuth 2.0 인증 서비스
class NotionOAuthService {
  // Notion OAuth 설정
  static const String clientId = 'YOUR_CLIENT_ID'; // 여기에 실제 Client ID 입력
  static const String clientSecret = 'YOUR_CLIENT_SECRET'; // 여기에 실제 Client Secret 입력
  static const String redirectUri = 'notionwidget://oauth-callback';
  static const String authorizationEndpoint = 'https://api.notion.com/v1/oauth/authorize';
  static const String tokenEndpoint = 'https://api.notion.com/v1/oauth/token';
  
  final Uuid _uuid = const Uuid();
  String? _currentState;

  /// OAuth 로그인 시작
  Future<bool> startOAuthFlow() async {
    try {
      // CSRF 공격 방지를 위한 state 생성
      _currentState = _uuid.v4();
      
      // OAuth 인증 URL 생성
      final authUrl = Uri.parse(authorizationEndpoint).replace(
        queryParameters: {
          'client_id': clientId,
          'redirect_uri': redirectUri,
          'response_type': 'code',
          'owner': 'user',
          'state': _currentState!,
        },
      );

      if (kDebugMode) {
        debugPrint('🔐 Opening OAuth URL: $authUrl');
      }

      // 브라우저에서 노션 로그인 페이지 열기
      final launched = await launchUrl(
        authUrl,
        mode: LaunchMode.externalApplication,
      );

      return launched;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ OAuth start error: $e');
      }
      return false;
    }
  }

  /// OAuth 콜백 처리
  Future<String?> handleOAuthCallback(Uri callbackUri) async {
    try {
      // State 검증
      final state = callbackUri.queryParameters['state'];
      if (state != _currentState) {
        if (kDebugMode) {
          debugPrint('❌ State mismatch! Possible CSRF attack');
        }
        return null;
      }

      // Authorization code 추출
      final code = callbackUri.queryParameters['code'];
      if (code == null) {
        if (kDebugMode) {
          debugPrint('❌ No authorization code received');
        }
        return null;
      }

      if (kDebugMode) {
        debugPrint('✅ Authorization code received: ${code.substring(0, 10)}...');
      }

      // Access token 교환
      final accessToken = await _exchangeCodeForToken(code);
      return accessToken;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ OAuth callback error: $e');
      }
      return null;
    }
  }

  /// Authorization code를 access token으로 교환
  Future<String?> _exchangeCodeForToken(String code) async {
    try {
      // Base64 인코딩된 credentials
      final credentials = base64Encode(utf8.encode('$clientId:$clientSecret'));

      final response = await http.post(
        Uri.parse(tokenEndpoint),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': redirectUri,
        }),
      );

      if (kDebugMode) {
        debugPrint('🔑 Token exchange response: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final accessToken = data['access_token'] as String?;
        
        if (kDebugMode) {
          debugPrint('✅ Access token obtained');
          debugPrint('   Bot ID: ${data['bot_id']}');
          debugPrint('   Workspace ID: ${data['workspace_id']}');
          debugPrint('   Workspace Name: ${data['workspace_name']}');
        }

        return accessToken;
      } else {
        if (kDebugMode) {
          debugPrint('❌ Token exchange failed: ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Token exchange error: $e');
      }
      return null;
    }
  }

  /// 사용자가 접근 가능한 데이터베이스 목록 가져오기
  Future<List<Map<String, dynamic>>> searchDatabases(String accessToken) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.notion.com/v1/search'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Notion-Version': '2022-06-28',
          'Content-Type': 'application/json',
        },
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

      if (kDebugMode) {
        debugPrint('🗄️ Database search response: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List;
        
        if (kDebugMode) {
          debugPrint('✅ Found ${results.length} databases');
        }

        return results.map((db) => db as Map<String, dynamic>).toList();
      } else {
        if (kDebugMode) {
          debugPrint('❌ Database search failed: ${response.body}');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Database search error: $e');
      }
      return [];
    }
  }
}
