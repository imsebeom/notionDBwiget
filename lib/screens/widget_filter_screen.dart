import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/widget_config.dart';
import '../models/notion_database.dart';
import '../models/notion_page.dart';
import '../services/notion_api_service.dart';
import '../services/token_storage_service.dart';

/// 위젯 필터 설정 화면
class WidgetFilterScreen extends StatefulWidget {
  final WidgetConfig? config; // 편집 모드인 경우

  const WidgetFilterScreen({super.key, this.config});

  @override
  State<WidgetFilterScreen> createState() => _WidgetFilterScreenState();
}

class _WidgetFilterScreenState extends State<WidgetFilterScreen> {
  final _tokenStorage = TokenStorageService();
  final _nameController = TextEditingController();
  
  NotionApiService? _apiService;
  List<NotionDatabase> _databases = [];
  NotionDatabase? _selectedDatabase;
  Map<String, dynamic>? _databaseProperties;
  
  // 필터 목록 (여러 개 지원)
  List<FilterItem> _filters = [];
  
  // 정렬 설정
  String _sortBy = 'last_edited_time';
  bool _sortAscending = false;
  
  // 미리보기
  List<NotionPage> _previewPages = [];
  bool _isLoadingPreview = false;
  
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      final accessToken = await _tokenStorage.getAccessToken();
      if (accessToken == null) {
        setState(() {
          _error = 'No access token found';
          _isLoading = false;
        });
        return;
      }

      _apiService = NotionApiService(accessToken: accessToken);
      
      // 편집 모드인 경우 기존 설정 로드
      if (widget.config != null) {
        _nameController.text = widget.config!.configName;
        _sortBy = widget.config!.sorts?.first['timestamp'] ?? 
                  widget.config!.sorts?.first['property'] ?? 
                  'last_edited_time';
        _sortAscending = widget.config!.sorts?.first['direction'] == 'ascending';
        
        // 기존 필터 로드
        if (widget.config!.filters != null) {
          _filters = widget.config!.filters!.map((f) => FilterItem.fromMap(f)).toList();
        }
      }
      
      await _loadDatabases();
    } catch (e) {
      setState(() {
        _error = 'Initialization failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDatabases() async {
    setState(() => _isLoading = true);

    try {
      final databases = await _apiService!.searchDatabases();
      setState(() {
        _databases = databases;
        _isLoading = false;
      });
      
      // 편집 모드인 경우 기존 데이터베이스 선택
      if (widget.config != null) {
        final db = databases.firstWhere(
          (d) => d.id == widget.config!.databaseId,
          orElse: () => databases.first,
        );
        await _selectDatabase(db);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load databases: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDatabase(NotionDatabase database) async {
    setState(() {
      _selectedDatabase = database;
      if (_nameController.text.isEmpty) {
        _nameController.text = database.title;
      }
    });

    try {
      final properties = await _apiService!.getDatabaseProperties(database.id);
      setState(() => _databaseProperties = properties);
      await _loadPreview();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load properties: $e')),
        );
      }
    }
  }

  void _addFilter() {
    setState(() {
      _filters.add(FilterItem());
    });
  }

  void _removeFilter(int index) {
    setState(() {
      _filters.removeAt(index);
    });
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    if (_apiService == null || _selectedDatabase == null) return;

    setState(() => _isLoadingPreview = true);

    try {
      final filterMaps = _filters
          .where((f) => f.isValid())
          .map((f) => f.toMap())
          .toList();

      final combinedFilter = filterMaps.isEmpty
          ? null
          : filterMaps.length == 1
              ? filterMaps.first
              : {'and': filterMaps};

      final sorts = _buildSorts();

      final pages = await _apiService!.getDatabasePages(
        _selectedDatabase!.id,
        pageSize: 10,
        filter: combinedFilter,
        sorts: sorts,
      );

      setState(() {
        _previewPages = pages;
        _isLoadingPreview = false;
      });
    } catch (e) {
      setState(() => _isLoadingPreview = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load preview: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> _buildSorts() {
    if (_sortBy == 'created_time') {
      return [SortPresets.createdTime(ascending: _sortAscending)];
    } else if (_sortBy == 'last_edited_time') {
      return [SortPresets.lastEditedTime(ascending: _sortAscending)];
    } else {
      return [SortPresets.property(_sortBy, ascending: _sortAscending)];
    }
  }

  Future<void> _saveConfig() async {
    if (_selectedDatabase == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a database')),
      );
      return;
    }

    final filterMaps = _filters
        .where((f) => f.isValid())
        .map((f) => f.toMap())
        .toList();

    final config = WidgetConfig(
      id: widget.config?.id ?? const Uuid().v4(),
      databaseId: _selectedDatabase!.id,
      databaseTitle: _selectedDatabase!.title,
      databaseIcon: _selectedDatabase!.icon,
      filters: filterMaps.isEmpty ? null : filterMaps,
      sorts: _buildSorts(),
      configName: _nameController.text.isEmpty 
          ? _selectedDatabase!.title 
          : _nameController.text,
    );

    Navigator.of(context).pop(config);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.config == null ? 'New Widget' : 'Edit Widget'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveConfig,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 위젯 이름
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Widget Name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),

          // 데이터베이스 선택
          if (_selectedDatabase == null) ...[
            const Text(
              'Select Database',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._databases.map((db) => Card(
                  child: ListTile(
                    leading: Text(db.icon ?? '🗄️', style: const TextStyle(fontSize: 24)),
                    title: Text(db.title),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _selectDatabase(db),
                  ),
                )),
          ] else ...[
            Card(
              color: Colors.blue.shade50,
              child: ListTile(
                leading: Text(_selectedDatabase!.icon ?? '🗄️',
                    style: const TextStyle(fontSize: 24)),
                title: Text(_selectedDatabase!.title),
                trailing: TextButton(
                  onPressed: () => setState(() {
                    _selectedDatabase = null;
                    _databaseProperties = null;
                  }),
                  child: const Text('Change'),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 필터 섹션
            Row(
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addFilter,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Filter'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._filters.asMap().entries.map((entry) {
              return _FilterItemWidget(
                key: ValueKey(entry.key),
                filter: entry.value,
                properties: _databaseProperties,
                onChanged: () => _loadPreview(),
                onRemove: () => _removeFilter(entry.key),
              );
            }),
            const SizedBox(height: 24),

            // 정렬 섹션
            const Text(
              'Sort',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _sortBy,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: [
                const DropdownMenuItem(
                  value: 'last_edited_time',
                  child: Text('Last Edited Time'),
                ),
                const DropdownMenuItem(
                  value: 'created_time',
                  child: Text('Created Time'),
                ),
                if (_databaseProperties != null)
                  ..._databaseProperties!.keys.map((key) {
                    return DropdownMenuItem(value: key, child: Text(key));
                  }),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _sortBy = value);
                  _loadPreview();
                }
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Ascending Order'),
              value: _sortAscending,
              onChanged: (value) {
                setState(() => _sortAscending = value);
                _loadPreview();
              },
            ),
            const SizedBox(height: 24),

            // 미리보기
            const Text(
              'Preview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_isLoadingPreview)
              const Center(child: CircularProgressIndicator())
            else if (_previewPages.isEmpty)
              const Text('No pages found')
            else
              ..._previewPages.take(5).map((page) => ListTile(
                    leading: Text(page.icon ?? '📄', style: const TextStyle(fontSize: 20)),
                    title: Text(page.title),
                    dense: true,
                  )),
          ],
        ],
      ),
    );
  }
}

// 필터 아이템 모델
class FilterItem {
  String? propertyName;
  String? filterType;
  String? filterValue;
  bool boolValue = false;

  FilterItem();

  factory FilterItem.fromMap(Map<String, dynamic> map) {
    final filter = FilterItem();
    filter.propertyName = map['property'] as String?;
    
    // 필터 타입 감지
    if (map.containsKey('checkbox')) {
      filter.filterType = 'checkbox';
      filter.boolValue = map['checkbox']['equals'] as bool? ?? false;
    } else if (map.containsKey('select')) {
      filter.filterType = 'select';
      filter.filterValue = map['select']['equals'] as String?;
    } else if (map.containsKey('multi_select')) {
      filter.filterType = 'multi_select';
      filter.filterValue = map['multi_select']['contains'] as String?;
    } else if (map.containsKey('rich_text')) {
      filter.filterType = 'rich_text';
      filter.filterValue = map['rich_text']['contains'] as String?;
    }
    
    return filter;
  }

  bool isValid() {
    if (propertyName == null || filterType == null) return false;
    if (filterType == 'checkbox') return true;
    return filterValue != null && filterValue!.isNotEmpty;
  }

  Map<String, dynamic> toMap() {
    switch (filterType) {
      case 'checkbox':
        return FilterPresets.checkboxEquals(propertyName!, boolValue);
      case 'select':
        return FilterPresets.selectEquals(propertyName!, filterValue!);
      case 'multi_select':
        return FilterPresets.multiSelectContains(propertyName!, filterValue!);
      case 'rich_text':
        return FilterPresets.textContains(propertyName!, filterValue!);
      default:
        return {};
    }
  }
}

// 필터 아이템 위젯
class _FilterItemWidget extends StatefulWidget {
  final FilterItem filter;
  final Map<String, dynamic>? properties;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _FilterItemWidget({
    super.key,
    required this.filter,
    required this.properties,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<_FilterItemWidget> createState() => _FilterItemWidgetState();
}

class _FilterItemWidgetState extends State<_FilterItemWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: widget.filter.propertyName,
                    decoration: const InputDecoration(
                      labelText: 'Property',
                      isDense: true,
                    ),
                    items: widget.properties?.keys.map((key) {
                      final prop = widget.properties![key] as Map<String, dynamic>;
                      final type = prop['type'] as String;
                      return DropdownMenuItem(
                        value: key,
                        child: Text('$key ($type)'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        final prop = widget.properties![value] as Map<String, dynamic>;
                        setState(() {
                          widget.filter.propertyName = value;
                          widget.filter.filterType = prop['type'] as String;
                          widget.filter.filterValue = null;
                        });
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            if (widget.filter.propertyName != null && widget.filter.filterType != null)
              _buildValueInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildValueInput() {
    switch (widget.filter.filterType) {
      case 'checkbox':
        return SwitchListTile(
          title: const Text('Value'),
          value: widget.filter.boolValue,
          onChanged: (value) {
            setState(() => widget.filter.boolValue = value);
            widget.onChanged();
          },
        );
      case 'select':
      case 'multi_select':
      case 'rich_text':
      case 'title':
        return TextField(
          decoration: const InputDecoration(labelText: 'Filter value'),
          onChanged: (value) {
            widget.filter.filterValue = value;
            widget.onChanged();
          },
          controller: TextEditingController(text: widget.filter.filterValue),
        );
      default:
        return Text('Filter type "${widget.filter.filterType}" not supported');
    }
  }
}
