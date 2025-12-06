import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/token_storage_service.dart';
import '../services/notion_api_service.dart';

/// 새 페이지 추가 다이얼로그
class AddPageDialog extends StatefulWidget {
  const AddPageDialog({super.key});

  @override
  State<AddPageDialog> createState() => _AddPageDialogState();
}

class _AddPageDialogState extends State<AddPageDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _tokenStorage = TokenStorageService();
  
  bool _isCreating = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _createPage() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isCreating = true;
      _error = null;
    });

    try {
      final accessToken = await _tokenStorage.getAccessToken();
      final databaseId = await _tokenStorage.getDatabaseId();

      if (accessToken == null || databaseId == null) {
        throw Exception('Authentication required');
      }

      final apiService = NotionApiService(accessToken: accessToken);
      
      // Notion API를 통해 새 페이지 생성
      final response = await apiService.createPage(
        databaseId: databaseId,
        title: _titleController.text.trim(),
      );

      if (response != null && mounted) {
        // 생성된 페이지 URL 열기
        final pageUrl = response['url'] as String?;
        if (pageUrl != null) {
          final uri = Uri.parse(pageUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }

        // 다이얼로그 닫기
        if (mounted) {
          Navigator.of(context).pop(true); // true를 반환하여 새로고침 트리거
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to create page: $e';
        _isCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2E2E2E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text('New Page'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _titleController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Page Title',
                hintText: 'Enter page title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.edit),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _createPage(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isCreating ? null : _createPage,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E2E2E),
            foregroundColor: Colors.white,
          ),
          child: _isCreating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
