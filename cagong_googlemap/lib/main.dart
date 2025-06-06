import 'package:flutter/material.dart';
import 'utils/app_router.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:provider/provider.dart';
import 'utils/authProvider.dart' as loginProvider;



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Firebase Auth 명시적 초기화
    await FirebaseAuth.instance.authStateChanges().first;
  } catch (e) {
    print('Firebase 초기화 오류: $e');
    // 여기에 오류 처리 로직을 추가할 수 있습니다.
  }

  if (kIsWeb) {
    // import 'package:google_maps_flutter_web/google_maps_flutter_web.dart' as web;
    // GoogleMapsFlutterPlatform.instance = web.GoogleMapsPlugin();
    print('웹 플랫폼 감지');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => loginProvider.AuthProvider(),
      child: Builder(
        builder: (context) {
          final authProvider = Provider.of<loginProvider.AuthProvider>(context);
          return MaterialApp.router(
            title: 'My Map App',
            theme: ThemeData(
              fontFamily: 'Noto_Sans_KR',
              scaffoldBackgroundColor: Colors.white,
              primarySwatch: Colors.brown,
            ),
            routerDelegate: AppRouterDelegate(authProvider),
            routeInformationParser: AppRouteInformationParser(),
          );
        },
      ),
    );
  }
}