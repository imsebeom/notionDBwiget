import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/notion_api_service.dart';
import '../services/token_storage_service.dart';
import 'database_select_screen.dart';

/// 노션 토큰 입력 화면 (Internal Integration)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TokenStorageService _tokenStorage = TokenStorageService();
  final TextEditingController _tokenController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _obscureToken = true;
  String? _error;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  /// 토큰 검증 및 로그인
  Future<void> _validateAndLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = _tokenController.text.trim();
      
      // Notion API 서비스 생성 및 토큰 검증
      final apiService = NotionApiService(accessToken: token);
      final isValid = await apiService.validateToken();

      if (!isValid) {
        setState(() {
          _error = 'Invalid token. Please check your Integration Token.';
          _isLoading = false;
        });
        return;
      }

      // 토큰 저장
      await _tokenStorage.saveAccessToken(token);

      if (!mounted) return;

      // 데이터베이스 선택 화면으로 이동
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const DatabaseSelectScreen(),
        ),
      );
    } catch (e) {
      setState(() {
        _error = 'Connection error. Please try again.';
        _isLoading = false;
      });
    }
  }

  /// 도움말 다이얼로그 표시
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Color(0xFF2E2E2E)),
            SizedBox(width: 12),
            Text('How to get Integration Token'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '1. Go to Notion Settings & Members',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Open Notion → Click "Settings & members" in the left sidebar'),
              const SizedBox(height: 16),
              
              const Text(
                '2. Create Integration',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Click "Connections" → "Develop or manage integrations"'),
              const SizedBox(height: 16),
              
              const Text(
                '3. Create New Integration',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Click "New integration" → Enter name → Select workspace'),
              const SizedBox(height: 16),
              
              const Text(
                '4. Copy Integration Token',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Copy the "Internal Integration Token" and paste it here'),
              const SizedBox(height: 16),
              
              const Text(
                '5. Share Database',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Go to your database → Click "..." → "Add connections" → Select your integration'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // 앱 아이콘/로고
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E2E2E),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.dashboard_customize,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 앱 이름
                const Text(
                  'Notion Widget',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E2E2E),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // 설명
                const Text(
                  'Display your Notion pages\non your home screen',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // 토큰 입력 안내
                Row(
                  children: [
                    const Text(
                      'Integration Token',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E2E2E),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _showHelpDialog,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.help_outline,
                          size: 18,
                          color: Color(0xFF2E2E2E),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 토큰 입력 필드
                TextFormField(
                  controller: _tokenController,
                  obscureText: _obscureToken,
                  decoration: InputDecoration(
                    hintText: 'secret_xxxxxxxxxxxxxxxxxxxxx',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2E2E2E), width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red.shade300),
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            _obscureToken ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureToken = !_obscureToken;
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.paste, color: Colors.grey),
                          onPressed: () async {
                            final data = await Clipboard.getData('text/plain');
                            if (data?.text != null) {
                              _tokenController.text = data!.text!;
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your Integration Token';
                    }
                    if (!value.startsWith('secret_')) {
                      return 'Token must start with "secret_"';
                    }
                    return null;
                  },
                  maxLines: 3,
                  minLines: 1,
                ),
                const SizedBox(height: 24),

                // 에러 메시지
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 로그인 버튼
                ElevatedButton(
                  onPressed: _isLoading ? null : _validateAndLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E2E2E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Connect to Notion',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                const SizedBox(height: 32),

                // 개인정보 보호 안내
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.security,
                        size: 20,
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your token is stored securely on your device',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
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
