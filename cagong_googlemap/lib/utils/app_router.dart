import 'package:flutter/material.dart';
import '../screens/map_screen.dart';
import '../screens/mypage_screen.dart';
import '../screens/login.dart';
import 'package:provider/provider.dart';
import '../utils/authProvider.dart';

class AppRouterDelegate extends RouterDelegate<RouteInformation>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<RouteInformation> {
  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  late AuthProvider _authProvider;
  String _currentRoute = '/';

  AppRouterDelegate(AuthProvider authProvider) {
    _authProvider = authProvider;
    _authProvider.addListener(_handleAuthStateChange);
  }

  void _handleAuthStateChange() {
    notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: [
        MaterialPage(
          child: Scaffold(
            body: IndexedStack(
              index: _currentRoute == '/mypage' ? 1 : 0,
              children: [
                MapScreen(),
                _authProvider.user != null ? MyPage() : LoginPage(),
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              backgroundColor: Colors.white,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.map),
                  label: '지도',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: '내 정보',
                ),
              ],
              currentIndex: _currentRoute == '/mypage' ? 1 : 0,
              selectedItemColor: Colors.brown,
              unselectedItemColor: Colors.grey,
              onTap: (index) {
                if (index == 1) {
                  _currentRoute = '/mypage';
                } else {
                  _currentRoute = '/';
                }
                notifyListeners();
              },
            ),
          ),
        ),
      ],
      onPopPage: (route, result) {
        if (!route.didPop(result)) {
          return false;
        }
        _currentRoute = '/';
        notifyListeners();
        return true;
      },
    );
  }

  @override
  Future<void> setNewRoutePath(RouteInformation configuration) async {
    if (configuration.location == '/mypage') {
      _currentRoute = '/mypage';
    } else {
      _currentRoute = '/';
    }
    notifyListeners();
  }

  @override
  RouteInformation? get currentConfiguration {
    return RouteInformation(location: _currentRoute);
  }

  @override
  void dispose() {
    _authProvider.removeListener(_handleAuthStateChange);
    super.dispose();
  }
}

class AppRouteInformationParser extends RouteInformationParser<RouteInformation> {
  @override
  Future<RouteInformation> parseRouteInformation(RouteInformation routeInformation) async {
    return routeInformation;
  }

  @override
  RouteInformation? restoreRouteInformation(RouteInformation configuration) {
    return configuration;
  }
}