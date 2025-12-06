import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/notion_page.dart';
import '../models/notion_database.dart';
import '../services/notion_api_service.dart';
import '../services/token_storage_service.dart';
import '../services/widget_service.dart';

/// 홈 화면 - 페이지 목록 표시
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TokenStorageService _tokenStorage = TokenStorageService();
  final WidgetService _widgetService = WidgetService();
  
  NotionDatabase? _database;
  List<NotionPage> _pages = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final accessToken = await _tokenStorage.getAccessToken();
      final databaseId = await _tokenStorage.getDatabaseId();
      final viewId = await _tokenStorage.getViewId();

      if (accessToken == null || databaseId == null || viewId == null) {
        setState(() {
          _error = 'Authentication or selection required';
          _isLoading = false;
        });
        return;
      }

      final apiService = NotionApiService(accessToken: accessToken);
      
      // 데이터베이스 정보 및 선택된 View의 페이지 목록 가져오기
      final database = await apiService.getDatabase(databaseId);
      final pages = await apiService.getDatabasePagesByView(databaseId, viewId);

      setState(() {
        _database = database;
        _pages = pages;
        _isLoading = false;
      });

      // 위젯 업데이트
      if (database != null && pages.isNotEmpty) {
        final viewName = await _tokenStorage.getViewName();
        final widgetTitle = viewName != null 
            ? '${database.title} - $viewName' 
            : database.title;
        await _widgetService.updateWidget(pages, widgetTitle);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    await _loadData();
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.view_agenda),
              label: const Text('Change View'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed('/view-select');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.storage),
              label: const Text('Change Database'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed('/database-select');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              onPressed: () async {
                await _tokenStorage.clearAll();
                await _widgetService.clearWidget();
                
                if (!mounted) return;
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: FutureBuilder<String?>(
          future: _tokenStorage.getViewName(),
          builder: (context, snapshot) {
            final viewName = snapshot.data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Notion Widget'),
                if (_database != null)
                  Text(
                    viewName != null 
                        ? '${_database!.title} - $viewName'
                        : _database!.title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: Colors.grey,
                    ),
                  ),
              ],
            );
          },
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleRefresh,
        backgroundColor: const Color(0xFF2E2E2E),
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _handleRefresh,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_pages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.inbox,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'No pages found in the database',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _handleRefresh,
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.builder(
        itemCount: _pages.length,
        itemBuilder: (context, index) {
          final page = _pages[index];
          return _PageListTile(page: page);
        },
      ),
    );
  }
}

/// 페이지 목록 항목
class _PageListTile extends StatelessWidget {
  final NotionPage page;

  const _PageListTile({required this.page});

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(date);
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F6F3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            page.icon ?? '📄',
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
      title: Text(
        page.title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        'Updated ${_formatDate(page.lastEditedTime)}',
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.grey,
      ),
      onTap: () async {
        final uri = Uri.parse(page.url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cannot open: ${page.title}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
  }
}
