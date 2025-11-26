/// Notion 데이터베이스 보기(View) 모델
class NotionView {
  final String id;
  final String name;
  final String type; // table, board, list, calendar, gallery, timeline
  
  NotionView({
    required this.id,
    required this.name,
    required this.type,
  });

  factory NotionView.fromJson(Map<String, dynamic> json) {
    return NotionView(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Untitled View',
      type: json['type'] as String? ?? 'table',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
    };
  }

  /// View 타입에 따른 아이콘 반환
  String get icon {
    switch (type) {
      case 'table':
        return '📋';
      case 'board':
        return '📊';
      case 'list':
        return '📝';
      case 'calendar':
        return '📅';
      case 'gallery':
        return '🖼️';
      case 'timeline':
        return '📈';
      default:
        return '👁️';
    }
  }

  /// View 타입의 한글 이름
  String get typeDisplayName {
    switch (type) {
      case 'table':
        return 'Table';
      case 'board':
        return 'Board';
      case 'list':
        return 'List';
      case 'calendar':
        return 'Calendar';
      case 'gallery':
        return 'Gallery';
      case 'timeline':
        return 'Timeline';
      default:
        return type;
    }
  }
}
