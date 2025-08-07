import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'utils/authProvider.dart' as loginProvider;
import 'utils/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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
