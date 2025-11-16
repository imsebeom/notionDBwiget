# Notion Widget App

노션 데이터베이스의 페이지 목록을 안드로이드 홈 화면 위젯으로 표시하는 Flutter 앱입니다.

## 🚀 주요 기능

- ✅ **노션 OAuth 로그인** - 노션 계정 연동
- ✅ **자동 데이터베이스 연결** - 사용자가 접근 가능한 모든 데이터베이스 검색
- ✅ **홈 화면 위젯** - 안드로이드 홈 화면에 페이지 목록 표시
- ✅ **실시간 동기화** - 페이지 목록 자동 업데이트
- ✅ **안전한 토큰 저장** - Flutter Secure Storage 사용

## 📱 스크린샷

### 로그인 화면
노션 계정으로 로그인합니다.

### 데이터베이스 선택
접근 가능한 데이터베이스 목록에서 선택합니다.

### 페이지 목록
선택한 데이터베이스의 페이지를 표시합니다.

### 홈 화면 위젯
안드로이드 홈 화면에 위젯을 추가하여 페이지 목록을 확인합니다.

## 🛠️ 기술 스택

- **Framework**: Flutter 3.35.4
- **Language**: Dart 3.9.2
- **State Management**: Provider 6.1.5
- **HTTP Client**: http 1.5.0
- **Secure Storage**: flutter_secure_storage 9.0.0
- **Home Widget**: home_widget 0.7.0

## 📋 사전 준비

### 1. Notion Public Integration 생성

1. https://www.notion.so/my-integrations 접속
2. "New integration" 클릭
3. **Type**: "Public" 선택 (중요!)
4. Integration 이름 입력 (예: "Notion Widget")
5. Associated workspace 선택
6. Capabilities 설정:
   - ✅ Read content
   - ✅ No user information
7. Submit 클릭

### 2. OAuth 설정

1. Integration 설정 페이지에서 "OAuth Domain & URIs" 섹션 이동
2. **Redirect URIs** 추가:
   ```
   notionwidget://oauth-callback
   ```
3. **Client ID**와 **Client Secret** 복사
4. 저장

### 3. 코드에 값 입력

`lib/services/notion_oauth_service.dart` 파일을 열고:

```dart
// 이 값들을 실제 값으로 교체
static const String clientId = 'YOUR_CLIENT_ID';
static const String clientSecret = 'YOUR_CLIENT_SECRET';
```

## 🏗️ 빌드 방법

### APK 빌드

```bash
flutter build apk --release
```

출력: `build/app/outputs/flutter-apk/app-release.apk`

### AAB 빌드 (Google Play Store)

```bash
flutter build appbundle --release
```

출력: `build/app/outputs/bundle/release/app-release.aab`

## 📦 설치 방법

1. APK 파일을 안드로이드 기기로 전송
2. 파일 관리자에서 APK 파일 실행
3. "알 수 없는 출처" 허용 (설정 → 보안)
4. 설치 진행

## 🎯 사용 방법

### 1. 첫 실행 - 로그인
1. 앱 실행
2. "Continue with Notion" 버튼 클릭
3. 노션 로그인 페이지에서 로그인
4. 권한 부여 (데이터베이스 접근 허용)
5. 자동으로 앱으로 복귀

### 2. 데이터베이스 선택
1. 접근 가능한 데이터베이스 목록 표시
2. 원하는 데이터베이스 선택
3. 페이지 목록 화면으로 이동

### 3. 위젯 추가
1. 안드로이드 홈 화면 롱프레스
2. "위젯" 선택
3. "Notion Widget" 찾아서 추가
4. 앱에서 새로고침하면 위젯 자동 업데이트

## 📁 프로젝트 구조

```
lib/
├── main.dart                          # 앱 진입점
├── models/
│   ├── notion_page.dart              # 페이지 모델
│   └── notion_database.dart          # 데이터베이스 모델
├── services/
│   ├── notion_oauth_service.dart     # OAuth 2.0 인증
│   ├── notion_api_service.dart       # Notion API 호출
│   ├── token_storage_service.dart    # 토큰 안전 저장
│   └── widget_service.dart           # 위젯 업데이트
├── providers/
│   └── notion_provider.dart          # 상태 관리
└── screens/
    ├── login_screen.dart             # 로그인 화면
    ├── database_select_screen.dart   # DB 선택 화면
    └── home_screen.dart              # 페이지 목록 화면

android/
└── app/src/main/
    ├── AndroidManifest.xml          # Deep Link 설정
    ├── kotlin/.../
    │   └── NotionWidgetProvider.kt  # 위젯 Provider
    └── res/
        ├── xml/notion_widget_info.xml
        └── layout/
            ├── notion_widget_layout.xml
            └── notion_widget_item.xml
```

## 🔐 보안

- ✅ **CSRF 보호**: OAuth state 파라미터 사용
- ✅ **안전한 토큰 저장**: AES 암호화 (Flutter Secure Storage)
- ✅ **HTTPS 강제**: 모든 API 통신
- ✅ **최소 권한**: 필요한 권한만 요청

## ⚠️ 제한 사항

- **웹 버전**: OAuth Deep Link가 작동하지 않음 (APK에서만 가능)
- **iOS**: 현재 안드로이드만 지원

## 🐛 문제 해결

### "OAuth 로그인 실패"
- Client ID와 Client Secret을 확인하세요
- Redirect URI가 정확한지 확인하세요: `notionwidget://oauth-callback`
- Public Integration으로 생성되었는지 확인하세요

### "데이터베이스가 표시되지 않음"
- Integration이 해당 데이터베이스에 연결되었는지 확인하세요
- 노션에서 데이터베이스 페이지 → "..." → "Connections" → Integration 추가

### "위젯이 업데이트되지 않음"
- 앱에서 Pull-to-refresh로 새로고침하세요
- 위젯을 제거하고 다시 추가해보세요

## 📝 라이선스

이 프로젝트는 MIT 라이선스 하에 있습니다.

## 🤝 기여

Pull Request를 환영합니다! 기여하기 전에 이슈를 먼저 열어주세요.

## 📧 문의

문제가 있거나 제안 사항이 있으면 GitHub Issues를 사용해주세요.

---

Made with ❤️ using Flutter
