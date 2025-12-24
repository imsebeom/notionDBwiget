import 'package:flutter/material.dart';
import '../models/widget_config.dart';
import '../services/widget_config_storage.dart';
import '../services/token_storage_service.dart';
import '../services/notion_api_service.dart';
import '../services/widget_service.dart';
import 'widget_filter_screen.dart';

/// 위젯 관리 화면 - 여러 위젯 설정 관리
class WidgetManagementScreen extends StatefulWidget {
  final bool isSelectMode; // 위젯 선택 모드 여부
  final int? widgetId; // 설정할 위젯 ID
  
  const WidgetManagementScreen({
    super.key,
    this.isSelectMode = false,
    this.widgetId,
  });

  @override
  State<WidgetManagementScreen> createState() => _WidgetManagementScreenState();
}

class _WidgetManagementScreenState extends State<WidgetManagementScreen> {
  final _storage = WidgetConfigStorage();
  final _tokenStorage = TokenStorageService();
  final _widgetService = WidgetService();
  List<WidgetConfig> _configs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    setState(() => _isLoading = true);
    final configs = await _storage.getAllConfigs();
    setState(() {
      _configs = configs;
      _isLoading = false;
    });
  }

  Future<void> _createNewWidget() async {
    final result = await Navigator.of(context).push<WidgetConfig>(
      MaterialPageRoute(
        builder: (context) => const WidgetFilterScreen(),
      ),
    );

    if (result != null) {
      await _storage.saveConfig(result);
      await _loadConfigs();
    }
  }

  Future<void> _editWidget(WidgetConfig config) async {
    final result = await Navigator.of(context).push<WidgetConfig>(
      MaterialPageRoute(
        builder: (context) => WidgetFilterScreen(config: config),
      ),
    );

    if (result != null) {
      await _storage.saveConfig(result);
      await _loadConfigs();
    }
  }

  Future<void> _deleteWidget(WidgetConfig config) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Widget'),
        content: Text('Are you sure you want to delete "${config.configName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storage.deleteConfig(config.id);
      await _loadConfigs();
    }
  }

  Future<void> _setActiveWidget(WidgetConfig config) async {
    try {
      // 활성 위젯 설정
      await _storage.setActiveWidgetId(config.id);
      
      // 선택된 설정으로 위젯 데이터 업데이트
      final accessToken = await _tokenStorage.getAccessToken();
      if (accessToken != null) {
        final apiService = NotionApiService(accessToken: accessToken);
        
        // 필터와 정렬을 적용하여 페이지 가져오기
        final pages = await apiService.getDatabasePages(
          config.databaseId,
          filter: (config.filters != null && config.filters!.isNotEmpty) 
              ? {'and': config.filters} 
              : null,
          sorts: config.sorts,
        );
        
        // 위젯 업데이트
        await _widgetService.updateWidget(pages, config.databaseTitle);
      }
      
      // 선택 모드인 경우 결과 반환하고 닫기
      if (widget.isSelectMode) {
        if (mounted) {
          Navigator.of(context).pop(config);
        }
        return;
      }
      
      // 일반 모드인 경우 스낵바 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Active widget: ${config.configName}'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {}); // UI 새로고침
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to apply widget: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.isSelectMode ? 'Select Widget Configuration' : 'Widget Management'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _configs.isEmpty
              ? _buildEmptyState()
              : _buildWidgetList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewWidget,
        backgroundColor: const Color(0xFF2E2E2E),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Widget', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.widgets,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Widgets Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create a widget to display your\nNotion pages on home screen',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWidgetList() {
    return FutureBuilder<String?>(
      future: _storage.getActiveWidgetId(),
      builder: (context, snapshot) {
        final activeId = snapshot.data;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _configs.length,
          itemBuilder: (context, index) {
            final config = _configs[index];
            final isActive = config.id == activeId;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: isActive ? 4 : 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isActive ? const Color(0xFF2E2E2E) : Colors.grey.shade200,
                  width: isActive ? 2 : 1,
                ),
              ),
              child: InkWell(
                onTap: () => _editWidget(config),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // 아이콘
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F6F3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              config.databaseIcon ?? '🗄️',
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // 제목과 정보
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        config.configName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (isActive)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2E2E2E),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'ACTIVE',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  config.databaseTitle,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  config.summary,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // 액션 버튼들
                      const SizedBox(height: 12),
                      widget.isSelectMode
                          ? 
                          // 선택 모드: 선택 버튼만 표시
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _setActiveWidget(config),
                              icon: const Icon(Icons.check_circle, size: 20),
                              label: const Text('Select This Widget'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E2E2E),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          )
                          :
                          // 일반 모드: 편집/삭제 버튼 표시
                          Row(
                            children: [
                              if (!isActive)
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _setActiveWidget(config),
                                    icon: const Icon(Icons.check_circle_outline, size: 18),
                                    label: const Text('Set Active'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF2E2E2E),
                                    ),
                                  ),
                                ),
                              if (!isActive) const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _editWidget(config),
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: const Text('Edit'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.blue,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _deleteWidget(config),
                                  icon: const Icon(Icons.delete, size: 18),
                                  label: const Text('Delete'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
