#!/bin/bash
# =====================================================
# XTREAM PLAYER UYGULAMASI - TAM KODLU SH DOSYASI
# =====================================================

echo ">>> [1/4] Xtream Player uygulaması hazırlanıyor..."

# GEREKLİ KLASÖRLERİN OLUŞTURULMASI
mkdir -p lib/screens lib/services lib/models lib/widgets assets panel .github/workflows

# pubspec.yaml oluşturma
cat > pubspec.yaml <<'EOF'
name: xtream_player
description: Xtream ve M3U destekli IPTV Player
publish_to: "none"
version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
  video_player: ^2.9.0
  shared_preferences: ^2.2.3
  google_mobile_ads: ^2.5.1
  provider: ^6.1.0
  url_launcher: ^6.3.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0

flutter:
  uses-material-design: true
  assets:
    - assets/
EOF

# Ana uygulama dosyası
cat > lib/main.dart <<'EOF'
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(XtreamPlayerApp());
}

class XtreamPlayerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Xtream Player',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Color(0xFF1C1C1C),
        primaryColor: Color(0xFF00FF7F),
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF00FF7F),
          secondary: Color(0xFF800000),
        ),
      ),
      home: LoginScreen(),
    );
  }
}
EOF

# Login ekranı (Xtream veya M3U girişi)
cat > lib/screens/login_screen.dart <<'EOF'
import 'package:flutter/material.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _selectedTab = 0;
  final _xtreamUrl = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _m3uUrl = TextEditingController();

  void _login() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network('https://youriconurl.com/icon.png', height: 80),
            SizedBox(height: 30),
            ToggleButtons(
              children: [Text("Xtream"), Text("M3U")],
              isSelected: [_selectedTab == 0, _selectedTab == 1],
              onPressed: (i) {
                setState(() => _selectedTab = i);
              },
            ),
            SizedBox(height: 20),
            _selectedTab == 0
                ? Column(
                    children: [
                      TextField(controller: _xtreamUrl, decoration: InputDecoration(labelText: 'Server URL')),
                      TextField(controller: _username, decoration: InputDecoration(labelText: 'Kullanıcı Adı')),
                      TextField(controller: _password, decoration: InputDecoration(labelText: 'Şifre')),
                    ],
                  )
                : TextField(controller: _m3uUrl, decoration: InputDecoration(labelText: 'M3U Link')),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: _login,
              child: Text("Giriş Yap"),
            ),
            SizedBox(height: 20),
            Container(
              height: 50,
              color: Colors.green.withOpacity(0.2),
              alignment: Alignment.center,
              child: Text("Banner Reklam Alanı"),
            ),
          ],
        ),
      ),
    );
  }
}
EOF

# Ana menü ekranı
cat > lib/screens/home_screen.dart <<'EOF'
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final pages = ["Canlı TV", "Filmler", "Diziler", "Favoriler"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Xtream Player")),
      body: Center(
        child: Text(
          "${pages[_currentIndex]} sayfası",
          style: TextStyle(fontSize: 24),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.grey,
        onTap: (i) => setState(() => _currentIndex = i),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.live_tv), label: "TV"),
          BottomNavigationBarItem(icon: Icon(Icons.movie), label: "Film"),
          BottomNavigationBarItem(icon: Icon(Icons.video_library), label: "Dizi"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Favori"),
        ],
      ),
    );
  }
}
EOF

# Build işlemi
echo ">>> [2/4] Flutter bağımlılıkları yükleniyor..."
flutter pub get > /dev/null

echo ">>> [3/4] APK derleniyor..."
flutter build apk --release > /dev/null

echo ">>> [4/4] Build tamamlandı. APK => build/app/outputs/flutter-apk/app-release.apk"
EOF

---

## ⚙️ `.github/workflows/build.yml`

```yaml
name: Xtream Player Build
on:
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Check out code
        uses: actions/checkout@v3

      - name: Setup Flutter
        uses: subosito/flutter-action@v2

      - name: Run Build Script
        run: bash build.sh
