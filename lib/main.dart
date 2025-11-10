import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:synapse/pages/auth_page.dart'; // ★ (새 프로젝트 이름으로 변경)
import 'package:synapse/pages/home_page.dart'; // ★ (새 프로젝트 이름으로 변경)
import 'package:synapse/pages/incubation_page.dart'; // ★ (새 프로젝트 이름으로 변경)
import 'package:synapse/pages/community_page.dart'; // ★ (새 프로젝트 이름으로 변경)


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ★★★ 여기에 Supabase URL과 Anon Key를 다시 붙여넣으세요 ★★★
  await Supabase.initialize(
    url: 'https://fskcwaxnlnlsooxmdviu.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZza2N3YXhubG5sc29veG1kdml1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI2NDI0ODMsImV4cCI6MjA3ODIxODQ4M30.bfFUMcAb4ctWjJ_DYWOIcKwSv1PKnc-lU31RbZTVCqA',
  );
  
  // (알림 서비스 초기화 코드가 없습니다)
  
  runApp(MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Synapse App',
      theme: ThemeData.dark(), 
      home: AuthHandler(),
    );
  }
}

class AuthHandler extends StatefulWidget {
  @override
  _AuthHandlerState createState() => _AuthHandlerState();
}

class _AuthHandlerState extends State<AuthHandler> {
  User? _user;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(Duration(seconds: 1)); 

    _user = supabase.auth.currentUser;

    supabase.auth.onAuthStateChange.listen((data) {
      if (mounted) { 
        setState(() {
          _user = data.session?.user;
        });
      }
    });

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return AuthPage();
    } else {
      return MainPageContainer();
    }
  }
}

// PageView를 관리하는 메인 컨테이너
class MainPageContainer extends StatefulWidget {
  @override
  _MainPageContainerState createState() => _MainPageContainerState();
}

class _MainPageContainerState extends State<MainPageContainer> {
  final PageController _pageController = PageController(
    initialPage: 1, // 1번 페이지(홈)에서 시작
  );

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        children: [
          IncubationPage(),  // 0번
          HomePage(),        // 1번
          CommunityPage(),   // 2번
        ],
      ),
    );
  }
}