import 'package:flutter/foundation.dart';

/// Notion 페이지 모델
class NotionPage {
  final String id;
  final String title;
  final String? icon;
  final DateTime createdTime;
  final DateTime lastEditedTime;
  final String url;

  NotionPage({
    required this.id,
    required this.title,
    this.icon,
    required this.createdTime,
    required this.lastEditedTime,
    required this.url,
  });

  factory NotionPage.fromJson(Map<String, dynamic> json) {
    // 제목 추출 - 노션 기본 템플릿 지원
    String title = 'Untitled';
    try {
      final properties = json['properties'] as Map<String, dynamic>?;
      if (properties != null) {
        // 모든 가능한 제목 속성 타입 확인
        for (var entry in properties.entries) {
          final prop = entry.value as Map<String, dynamic>?;
          if (prop != null && prop['type'] == 'title') {
            final titleList = prop['title'] as List?;
            if (titleList != null && titleList.isNotEmpty) {
              title = titleList[0]['plain_text'] as String? ?? 'Untitled';
              break;
            }
          }
        }
        
        // 여전히 제목을 못 찾았다면 Name/Title 속성 확인
        if (title == 'Untitled') {
          final nameProperty = properties['Name'] ?? properties['Title'] ?? properties['이름'];
          if (nameProperty != null) {
            final titleList = nameProperty['title'] as List?;
            if (titleList != null && titleList.isNotEmpty) {
              title = titleList[0]['plain_text'] as String? ?? 'Untitled';
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Title extraction error: $e');
      }
      title = 'Untitled';
    }

    // 아이콘 추출
    String? icon;
    try {
      final iconData = json['icon'];
      if (iconData != null && iconData is Map) {
        if (iconData['type'] == 'emoji') {
          icon = iconData['emoji'] as String?;
        } else if (iconData['type'] == 'external') {
          icon = iconData['external']?['url'] as String?;
        } else if (iconData['type'] == 'file') {
          icon = iconData['file']?['url'] as String?;
        }
      }
    } catch (e) {
      // 아이콘 추출 실패 시 null 유지
    }

    return NotionPage(
      id: json['id'] as String,
      title: title,
      icon: icon,
      createdTime: DateTime.parse(json['created_time'] as String),
      lastEditedTime: DateTime.parse(json['last_edited_time'] as String),
      url: json['url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'icon': icon,
      'created_time': createdTime.toIso8601String(),
      'last_edited_time': lastEditedTime.toIso8601String(),
      'url': url,
    };
  }
}
