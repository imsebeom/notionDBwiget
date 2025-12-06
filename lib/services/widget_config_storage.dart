import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/widget_config.dart';

/// 여러 위젯 설정을 저장/관리하는 서비스
class WidgetConfigStorage {
  static const String _keyWidgetConfigs = 'widget_configs';
  static const String _keyActiveWidgetId = 'active_widget_id';

  /// 모든 위젯 설정 가져오기
  Future<List<WidgetConfig>> getAllConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyWidgetConfigs);
    
    if (jsonString == null) return [];
    
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => WidgetConfig.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 위젯 설정 저장
  Future<void> saveConfig(WidgetConfig config) async {
    final configs = await getAllConfigs();
    
    // 기존 설정 업데이트 또는 새로 추가
    final index = configs.indexWhere((c) => c.id == config.id);
    if (index >= 0) {
      configs[index] = config;
    } else {
      configs.add(config);
    }
    
    await _saveAllConfigs(configs);
  }

  /// 위젯 설정 삭제
  Future<void> deleteConfig(String configId) async {
    final configs = await getAllConfigs();
    configs.removeWhere((c) => c.id == configId);
    await _saveAllConfigs(configs);
  }

  /// ID로 위젯 설정 가져오기
  Future<WidgetConfig?> getConfig(String configId) async {
    final configs = await getAllConfigs();
    try {
      return configs.firstWhere((c) => c.id == configId);
    } catch (e) {
      return null;
    }
  }

  /// 활성 위젯 ID 저장
  Future<void> setActiveWidgetId(String configId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActiveWidgetId, configId);
  }

  /// 활성 위젯 ID 가져오기
  Future<String?> getActiveWidgetId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyActiveWidgetId);
  }

  /// 활성 위젯 설정 가져오기
  Future<WidgetConfig?> getActiveConfig() async {
    final activeId = await getActiveWidgetId();
    if (activeId == null) return null;
    return await getConfig(activeId);
  }

  /// 모든 설정 저장 (내부 메서드)
  Future<void> _saveAllConfigs(List<WidgetConfig> configs) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = configs.map((c) => c.toJson()).toList();
    await prefs.setString(_keyWidgetConfigs, jsonEncode(jsonList));
  }

  /// 모든 설정 삭제
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyWidgetConfigs);
    await prefs.remove(_keyActiveWidgetId);
  }
}
