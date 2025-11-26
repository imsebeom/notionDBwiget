import 'package:flutter/material.dart';
import '../models/notion_view.dart';
import '../services/notion_api_service.dart';
import '../services/token_storage_service.dart';

/// Notion 데이터베이스 View 선택 화면
class ViewSelectScreen extends StatefulWidget {
  const ViewSelectScreen({super.key});

  @override
  State<ViewSelectScreen> createState() => _ViewSelectScreenState();
}

class _ViewSelectScreenState extends State<ViewSelectScreen> {
  final TokenStorageService _tokenStorage = TokenStorageService();
  
  List<NotionView> _views = [];
  bool _isLoading = true;
  String? _error;
  String _databaseTitle = '';

  @override
  void initState() {
    super.initState();
    _loadViews();
  }

  /// View 목록 불러오기
  Future<void> _loadViews() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final accessToken = await _tokenStorage.getAccessToken();
      final databaseId = await _tokenStorage.getDatabaseId();
      final databaseTitle = await _tokenStorage.getDatabaseTitle();
      
      if (accessToken == null || databaseId == null) {
        setState(() {
          _error = 'No access token or database found';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _databaseTitle = databaseTitle ?? 'Unknown Database';
      });

      final apiService = NotionApiService(accessToken: accessToken);
      final views = await apiService.getDatabaseViews(databaseId);

      setState(() {
        _views = views;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load views: $e';
        _isLoading = false;
      });
    }
  }

  /// View 선택 처리
  Future<void> _selectView(NotionView view) async {
    try {
      await _tokenStorage.saveViewId(view.id);
      await _tokenStorage.saveViewName(view.name);

      if (!mounted) return;

      // 홈 화면으로 이동
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to select view: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 뒤로 가기 (데이터베이스 재선택)
  void _goBack() {
    Navigator.of(context).pushReplacementNamed('/database-select');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Select View'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading views...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
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
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadViews,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_views.isEmpty) {
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
                'No views found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This database has no available views',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadViews,
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 데이터베이스 정보
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.storage, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Database',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _databaseTitle,
                      style: TextStyle(
                        color: Colors.blue.shade900,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 안내 메시지
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Select a view to display on your widget',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // View 개수
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '${_views.length} view${_views.length != 1 ? 's' : ''} available',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // View 목록
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadViews,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _views.length,
              itemBuilder: (context, index) {
                final view = _views[index];
                return _ViewListTile(
                  view: view,
                  onTap: () => _selectView(view),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// View 목록 항목
class _ViewListTile extends StatelessWidget {
  final NotionView view;
  final VoidCallback onTap;

  const _ViewListTile({
    required this.view,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 아이콘
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F6F3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    view.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // 제목
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      view.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      view.typeDisplayName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              // 화살표
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
