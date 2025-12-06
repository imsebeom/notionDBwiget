import 'package:flutter/material.dart';
import '../models/notion_database.dart';
import '../models/notion_page.dart';
import '../models/widget_config.dart';
import '../services/notion_api_service.dart';
import '../services/token_storage_service.dart';

/// 위젯 설정 화면 - 데이터베이스 선택 및 필터/정렬 설정
class WidgetConfigScreen extends StatefulWidget {
  const WidgetConfigScreen({super.key});

  @override
  State<WidgetConfigScreen> createState() => _WidgetConfigScreenState();
}

class _WidgetConfigScreenState extends State<WidgetConfigScreen> {
  final TokenStorageService _tokenStorage = TokenStorageService();
  
  NotionApiService? _apiService;
  List<NotionDatabase> _databases = [];
  NotionDatabase? _selectedDatabase;
  Map<String, dynamic>? _databaseProperties;
  
  // 필터 설정
  String? _filterPropertyName;
  String? _filterType; // 'checkbox', 'select', 'multi_select', 'date', 'text'
  String? _filterValue;
  bool _filterBoolValue = false;
  
  // 정렬 설정
  String _sortBy = 'last_edited_time'; // 'created_time', 'last_edited_time', or property name
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
      await _loadDatabases();
    } catch (e) {
      setState(() {
        _error = 'Initialization failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDatabases() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final databases = await _apiService!.searchDatabases();
      setState(() {
        _databases = databases;
        _isLoading = false;
      });
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
      _databaseProperties = null;
      _filterPropertyName = null;
      _filterType = null;
      _filterValue = null;
    });

    // 데이터베이스 프로퍼티 정보 가져오기
    try {
      final properties = await _apiService!.getDatabaseProperties(database.id);
      setState(() {
        _databaseProperties = properties;
      });
      
      // 자동으로 미리보기 로드
      await _loadPreview();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load properties: $e')),
        );
      }
    }
  }

  Future<void> _loadPreview() async {
    if (_apiService == null || _selectedDatabase == null) return;

    setState(() {
      _isLoadingPreview = true;
    });

    try {
      // 필터 구성
      Map<String, dynamic>? filter;
      if (_filterPropertyName != null && _filterType != null) {
        filter = _buildFilter();
      }

      // 정렬 구성
      final sorts = _buildSorts();

      // 페이지 가져오기
      final pages = await _apiService!.getDatabasePages(
        _selectedDatabase!.id,
        pageSize: 10, // 미리보기는 10개만
        filter: filter,
        sorts: sorts,
      );

      setState(() {
        _previewPages = pages;
        _isLoadingPreview = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPreview = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load preview: $e')),
        );
      }
    }
  }

  Map<String, dynamic>? _buildFilter() {
    if (_filterPropertyName == null || _filterType == null) return null;

    switch (_filterType) {
      case 'checkbox':
        return FilterPresets.checkboxEquals(_filterPropertyName!, _filterBoolValue);
      case 'select':
        if (_filterValue != null) {
          return FilterPresets.selectEquals(_filterPropertyName!, _filterValue!);
        }
        break;
      case 'multi_select':
        if (_filterValue != null) {
          return FilterPresets.multiSelectContains(_filterPropertyName!, _filterValue!);
        }
        break;
      case 'text':
        if (_filterValue != null) {
          return FilterPresets.textContains(_filterPropertyName!, _filterValue!);
        }
        break;
    }

    return null;
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

  Future<void> _saveConfiguration() async {
    if (_selectedDatabase == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a database')),
      );
      return;
    }

    // 위젯 설정 생성
    final filter = _buildFilter();
    final config = WidgetConfig(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // 고유 ID 생성
      databaseId: _selectedDatabase!.id,
      databaseTitle: _selectedDatabase!.title,
      databaseIcon: _selectedDatabase!.icon,
      filters: filter != null ? [filter] : null, // filter를 filters 리스트로 변환
      sorts: _buildSorts(),
      configName: _selectedDatabase!.title,
    );

    // 설정 저장
    await _tokenStorage.saveDatabaseId(config.databaseId);
    await _tokenStorage.saveDatabaseTitle(config.databaseTitle);
    
    // 필터/정렬 정보도 저장 (JSON 형태로)
    // TODO: TokenStorageService에 위젯 설정 저장 메서드 추가
    
    if (!mounted) return;
    
    // 홈 화면으로 이동
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Widget Configuration'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_selectedDatabase != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveConfiguration,
              tooltip: 'Save Configuration',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadDatabases,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_selectedDatabase == null) {
      return _buildDatabaseSelection();
    }

    return _buildConfigurationPanel();
  }

  Widget _buildDatabaseSelection() {
    if (_databases.isEmpty) {
      return const Center(
        child: Text('No databases found'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Select a database',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _databases.length,
            itemBuilder: (context, index) {
              final database = _databases[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F6F3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        database.icon ?? '🗄️',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  title: Text(
                    database.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _selectDatabase(database),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConfigurationPanel() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 선택된 데이터베이스 표시
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  _selectedDatabase!.icon ?? '🗄️',
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedDatabase!.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Configure filters and sorting',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedDatabase = null;
                      _databaseProperties = null;
                    });
                  },
                  child: const Text('Change'),
                ),
              ],
            ),
          ),

          // 필터 설정
          _buildFilterSection(),

          const SizedBox(height: 16),

          // 정렬 설정
          _buildSortSection(),

          const SizedBox(height: 16),

          // 미리보기
          _buildPreviewSection(),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_alt, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Filter',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_filterPropertyName != null)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filterPropertyName = null;
                      _filterType = null;
                      _filterValue = null;
                    });
                    _loadPreview();
                  },
                  child: const Text('Clear'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (_databaseProperties != null && _databaseProperties!.isNotEmpty)
            DropdownButtonFormField<String>(
              initialValue: _filterPropertyName,
              decoration: const InputDecoration(
                labelText: 'Filter by property',
                border: OutlineInputBorder(),
              ),
              items: _databaseProperties!.keys.map((key) {
                final prop = _databaseProperties![key] as Map<String, dynamic>;
                final type = prop['type'] as String;
                return DropdownMenuItem(
                  value: key,
                  child: Text('$key ($type)'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  final prop = _databaseProperties![value] as Map<String, dynamic>;
                  final type = prop['type'] as String;
                  setState(() {
                    _filterPropertyName = value;
                    _filterType = type;
                    _filterValue = null;
                  });
                }
              },
            )
          else
            const Text('Loading properties...'),

          if (_filterPropertyName != null && _filterType != null) ...[
            const SizedBox(height: 12),
            _buildFilterValueInput(),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadPreview,
              child: const Text('Apply Filter'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterValueInput() {
    switch (_filterType) {
      case 'checkbox':
        return SwitchListTile(
          title: const Text('Value'),
          value: _filterBoolValue,
          onChanged: (value) {
            setState(() {
              _filterBoolValue = value;
            });
          },
        );
      case 'select':
      case 'multi_select':
      case 'rich_text':
      case 'title':
        return TextField(
          decoration: const InputDecoration(
            labelText: 'Filter value',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _filterValue = value;
            });
          },
        );
      default:
        return Text('Filter type "$_filterType" not supported yet');
    }
  }

  Widget _buildSortSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.sort, size: 20),
              SizedBox(width: 8),
              Text(
                'Sort',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          DropdownButtonFormField<String>(
            initialValue: _sortBy,
            decoration: const InputDecoration(
              labelText: 'Sort by',
              border: OutlineInputBorder(),
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
                  return DropdownMenuItem(
                    value: key,
                    child: Text(key),
                  );
                }),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _sortBy = value;
                });
                _loadPreview();
              }
            },
          ),
          const SizedBox(height: 12),
          
          SwitchListTile(
            title: const Text('Ascending order'),
            value: _sortAscending,
            onChanged: (value) {
              setState(() {
                _sortAscending = value;
              });
              _loadPreview();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.preview, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Preview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_isLoadingPreview)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (_previewPages.isEmpty && !_isLoadingPreview)
            const Text('No pages found with current filters')
          else if (!_isLoadingPreview)
            ..._previewPages.take(5).map((page) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Text(
                  page.icon ?? '📄',
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(
                  page.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  'Updated ${_formatDate(page.lastEditedTime)}',
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }),
            
          if (_previewPages.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'and ${_previewPages.length - 5} more items...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'just now';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
