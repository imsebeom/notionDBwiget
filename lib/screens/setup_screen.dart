import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notion_provider.dart';
import '../widgets/setup_guide_dialog.dart';

/// 노션 설정 화면
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  final _databaseIdController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _apiKeyController.dispose();
    _databaseIdController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<NotionProvider>(context, listen: false);
    final success = await provider.configure(
      _apiKeyController.text,
      _databaseIdController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Successfully connected to Notion!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Configuration failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Notion Widget Setup'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const SetupGuideDialog(),
              );
            },
            tooltip: 'Setup Guide',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 로고/아이콘
                const Icon(
                  Icons.dashboard_customize,
                  size: 80,
                  color: Color(0xFF2E2E2E),
                ),
                const SizedBox(height: 24),

                // 제목
                const Text(
                  'Connect to Notion',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E2E2E),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // 설명
                const Text(
                  'Enter your Notion integration token and database ID to display your pages on the home screen widget.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                // 가이드 링크
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const SetupGuideDialog(),
                    );
                  },
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text(
                    'Need help? View setup guide',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),

                // API Key 입력
                const Text(
                  'Integration Token',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _apiKeyController,
                  decoration: InputDecoration(
                    hintText: 'secret_xxxxxxxxxxxxx',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF7F6F3),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your integration token';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // API Key 가이드 링크
                InkWell(
                  onTap: () {
                    // 가이드 보기
                  },
                  child: const Text(
                    'How to get an integration token?',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Database ID 입력
                const Text(
                  'Database ID',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _databaseIdController,
                  decoration: InputDecoration(
                    hintText: 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF7F6F3),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter database ID';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Database ID 가이드 링크
                InkWell(
                  onTap: () {
                    // 가이드 보기
                  },
                  child: const Text(
                    'How to find database ID?',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // 연결 버튼
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E2E2E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Connect',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
