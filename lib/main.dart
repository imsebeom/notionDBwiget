import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/notion_provider.dart';
import 'screens/login_screen.dart';
import 'screens/database_select_screen.dart';
import 'screens/view_select_screen.dart';
import 'screens/widget_config_screen.dart';
import 'screens/widget_management_screen.dart';
import 'screens/home_screen.dart';
import 'services/token_storage_service.dart';
import 'widgets/add_page_dialog.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const platform = MethodChannel('com.example.flutter_app/widget');
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _setupMethodChannel();
  }

  void _setupMethodChannel() {
    platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'showAddPageDialog':
          _showAddPageDialog();
          break;
        case 'refreshData':
          _refreshData();
          break;
        case 'configureWidget':
          final widgetId = call.arguments['widgetId'] as int?;
          _showWidgetConfiguration(widgetId);
          break;
      }
    });
  }

  void _showAddPageDialog() {
    final context = navigatorKey.currentContext;
    if (context != null) {
      showDialog(
        context: context,
        builder: (context) => const AddPageDialog(),
      ).then((result) {
        // 페이지가 생성되었으면 홈 화면 새로고침
        if (result == true) {
          _refreshData();
        }
      });
    }
  }

  void _refreshData() {
    final context = navigatorKey.currentContext;
    if (context != null) {
      // 현재 화면이 HomeScreen인지 확인하고 새로고침
      // Navigator를 통해 HomeScreen 찾기 (추후 개선 가능)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Refreshing widget data...'),
          duration: Duration(seconds: 1),
        ),
      );
      
      // 홈 화면으로 이동하고 새로고침
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }

  void _showWidgetConfiguration(int? widgetId) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      // 위젯 관리 화면으로 이동
      Navigator.of(context).pushNamed('/widget-management').then((_) {
        // 위젯 설정이 완료되면 위젯 업데이트
        _refreshData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => NotionProvider(),
      child: MaterialApp(
        navigatorKey: navigatorKey,
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
          '/widget-management': (context) => const WidgetManagementScreen(),
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

      if (!mounted) return;

      if (!isAuthenticated) {
        // 로그인 필요
        Navigator.of(context).pushReplacementNamed('/login');
      } else if (!isDatabaseSelected) {
        // 데이터베이스 선택 필요
        Navigator.of(context).pushReplacementNamed('/database-select');
      } else {
        // 홈 화면으로 이동 (View 선택 단계 제거)
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
