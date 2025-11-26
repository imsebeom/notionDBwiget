import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/notion_provider.dart';
import 'screens/login_screen.dart';
import 'screens/database_select_screen.dart';
import 'screens/view_select_screen.dart';
import 'screens/widget_config_screen.dart';
import 'screens/home_screen.dart';
import 'services/token_storage_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => NotionProvider(),
      child: MaterialApp(
        title: 'Notion Widget',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2E2E2E),
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white,
        ),
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/database-select': (context) => const DatabaseSelectScreen(),
          '/view-select': (context) => const ViewSelectScreen(),
          '/widget-config': (context) => const WidgetConfigScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}

/// 스플래시 화면 - 인증 상태 확인
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final TokenStorageService _tokenStorage = TokenStorageService();

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      // 약간의 지연 (스플래시 화면 표시)
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      // 인증 상태 확인
      final isAuthenticated = await _tokenStorage.isAuthenticated();
      final isDatabaseSelected = await _tokenStorage.isDatabaseSelected();
      final isViewSelected = await _tokenStorage.isViewSelected();

      if (!mounted) return;

      if (!isAuthenticated) {
        // 로그인 필요
        Navigator.of(context).pushReplacementNamed('/login');
      } else if (!isDatabaseSelected) {
        // 데이터베이스 선택 필요
        Navigator.of(context).pushReplacementNamed('/database-select');
      } else if (!isViewSelected) {
        // View 선택 필요
        Navigator.of(context).pushReplacementNamed('/view-select');
      } else {
        // 홈 화면으로 이동
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      // 에러 발생 시 로그인 화면으로
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 앱 아이콘/로고
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF2E2E2E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.dashboard_customize,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // 앱 이름
            const Text(
              'Notion Widget',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E2E2E),
              ),
            ),
            const SizedBox(height: 32),

            // 로딩 인디케이터
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E2E2E)),
            ),
          ],
        ),
      ),
    );
  }
}
