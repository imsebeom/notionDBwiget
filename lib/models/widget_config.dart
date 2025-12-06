import 'dart:convert';

/// 위젯 설정 모델 (데이터베이스, 필터, 정렬 정보 저장)
class WidgetConfig {
  final String id; // 위젯 고유 ID (위젯 여러개 관리)
  final String databaseId;
  final String databaseTitle;
  final String? databaseIcon;
  final List<Map<String, dynamic>>? filters; // 여러 필터 지원 (변경: filter -> filters, List로 변경)
  final List<Map<String, dynamic>>? sorts;
  final String configName; // 설정 이름 (예: "진행중인 작업", "완료된 프로젝트")
  
  WidgetConfig({
    required this.id,
    required this.databaseId,
    required this.databaseTitle,
    this.databaseIcon,
    this.filters,
    this.sorts,
    this.configName = 'Default View',
  });

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'databaseId': databaseId,
      'databaseTitle': databaseTitle,
      'databaseIcon': databaseIcon,
      'filters': filters,
      'sorts': sorts,
      'configName': configName,
    };
  }

  /// JSON에서 생성
  factory WidgetConfig.fromJson(Map<String, dynamic> json) {
    return WidgetConfig(
      id: json['id'] as String,
      databaseId: json['databaseId'] as String,
      databaseTitle: json['databaseTitle'] as String,
      databaseIcon: json['databaseIcon'] as String?,
      filters: (json['filters'] as List?)?.map((e) => e as Map<String, dynamic>).toList(),
      sorts: (json['sorts'] as List?)?.map((e) => e as Map<String, dynamic>).toList(),
      configName: json['configName'] as String? ?? 'Default View',
    );
  }

  /// 문자열로 직렬화
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// 문자열에서 역직렬화
  factory WidgetConfig.fromJsonString(String jsonString) {
    return WidgetConfig.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  /// 복사본 생성
  WidgetConfig copyWith({
    String? id,
    String? databaseId,
    String? databaseTitle,
    String? databaseIcon,
    List<Map<String, dynamic>>? filters,
    List<Map<String, dynamic>>? sorts,
    String? configName,
  }) {
    return WidgetConfig(
      id: id ?? this.id,
      databaseId: databaseId ?? this.databaseId,
      databaseTitle: databaseTitle ?? this.databaseTitle,
      databaseIcon: databaseIcon ?? this.databaseIcon,
      filters: filters ?? this.filters,
      sorts: sorts ?? this.sorts,
      configName: configName ?? this.configName,
    );
  }

  /// 필터가 적용되었는지 확인
  bool get hasFilters => filters != null && filters!.isNotEmpty;

  /// 정렬이 적용되었는지 확인
  bool get hasSorts => sorts != null && sorts!.isNotEmpty;

  /// 설정 요약 텍스트
  String get summary {
    final parts = <String>[];
    
    if (hasFilters) {
      parts.add('${filters!.length} filter(s)');
    }
    
    if (hasSorts) {
      parts.add('Sorted');
    }
    
    if (parts.isEmpty) {
      return 'All items';
    }
    
    return parts.join(' • ');
  }
  
  /// Notion API 필터 형식으로 변환 (여러 필터를 AND로 결합)
  Map<String, dynamic>? toNotionFilter() {
    if (filters == null || filters!.isEmpty) return null;
    if (filters!.length == 1) return filters!.first;
    return {'and': filters};
  }
}

/// 일반적인 필터 프리셋
class FilterPresets {
  /// 체크박스 필터: 완료된 항목만
  static Map<String, dynamic> checkboxEquals(String propertyName, bool value) {
    return {
      'property': propertyName,
      'checkbox': {
        'equals': value,
      },
    };
  }

  /// 선택(Select) 필터: 특정 옵션
  static Map<String, dynamic> selectEquals(String propertyName, String value) {
    return {
      'property': propertyName,
      'select': {
        'equals': value,
      },
    };
  }

  /// 다중선택(Multi-select) 필터: 특정 옵션 포함
  static Map<String, dynamic> multiSelectContains(String propertyName, String value) {
    return {
      'property': propertyName,
      'multi_select': {
        'contains': value,
      },
    };
  }

  /// 날짜 필터: 지난 주
  static Map<String, dynamic> dateLastWeek(String propertyName) {
    return {
      'property': propertyName,
      'date': {
        'past_week': {},
      },
    };
  }

  /// 날짜 필터: 다음 주
  static Map<String, dynamic> dateNextWeek(String propertyName) {
    return {
      'property': propertyName,
      'date': {
        'next_week': {},
      },
    };
  }

  /// 텍스트 필터: 포함
  static Map<String, dynamic> textContains(String propertyName, String value) {
    return {
      'property': propertyName,
      'rich_text': {
        'contains': value,
      },
    };
  }

  /// AND 조건으로 여러 필터 결합
  static Map<String, dynamic> and(List<Map<String, dynamic>> filters) {
    return {
      'and': filters,
    };
  }

  /// OR 조건으로 여러 필터 결합
  static Map<String, dynamic> or(List<Map<String, dynamic>> filters) {
    return {
      'or': filters,
    };
  }
}

/// 일반적인 정렬 프리셋
class SortPresets {
  /// 생성일 기준 정렬
  static Map<String, dynamic> createdTime({bool ascending = false}) {
    return {
      'timestamp': 'created_time',
      'direction': ascending ? 'ascending' : 'descending',
    };
  }

  /// 수정일 기준 정렬
  static Map<String, dynamic> lastEditedTime({bool ascending = false}) {
    return {
      'timestamp': 'last_edited_time',
      'direction': ascending ? 'ascending' : 'descending',
    };
  }

  /// 프로퍼티 기준 정렬
  static Map<String, dynamic> property(String propertyName, {bool ascending = true}) {
    return {
      'property': propertyName,
      'direction': ascending ? 'ascending' : 'descending',
    };
  }
}
