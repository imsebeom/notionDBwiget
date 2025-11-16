/// Notion 데이터베이스 모델
class NotionDatabase {
  final String id;
  final String title;
  final String? icon;
  final DateTime createdTime;
  final DateTime lastEditedTime;

  NotionDatabase({
    required this.id,
    required this.title,
    this.icon,
    required this.createdTime,
    required this.lastEditedTime,
  });

  factory NotionDatabase.fromJson(Map<String, dynamic> json) {
    // 제목 추출
    String title = 'Untitled Database';
    try {
      final titleList = json['title'] as List?;
      if (titleList != null && titleList.isNotEmpty) {
        title = titleList[0]['plain_text'] as String? ?? 'Untitled Database';
      }
    } catch (e) {
      title = 'Untitled Database';
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

    return NotionDatabase(
      id: json['id'] as String,
      title: title,
      icon: icon,
      createdTime: DateTime.parse(json['created_time'] as String),
      lastEditedTime: DateTime.parse(json['last_edited_time'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'icon': icon,
      'created_time': createdTime.toIso8601String(),
      'last_edited_time': lastEditedTime.toIso8601String(),
    };
  }
}
