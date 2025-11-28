import 'package:flutter/material.dart';
import '../screens/map_screen.dart';
import '../screens/mypage_screen.dart';
import '../screens/login.dart';
import 'package:provider/provider.dart';
import '../utils/authProvider.dart';
//import '../screens/feedback_screen.dart';
import '../screens/reservation_screen.dart';

class AppRouterDelegate extends RouterDelegate<RouteInformation>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<RouteInformation> {
  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  late AuthProvider _authProvider;
  String _currentRoute = '/';

  // MapScreen의 GlobalKey 추가
  final GlobalKey<MapScreenState> _mapScreenKey = GlobalKey<MapScreenState>();

  AppRouterDelegate(AuthProvider authProvider) {
    _authProvider = authProvider;
    _authProvider.addListener(_handleAuthStateChange);
  }

  void _handleAuthStateChange() {
    notifyListeners();
  }

  int getIndexForRoute(String route) {
    switch (route) {
      case '/mypage':
        return 1;
      case '/feedback':
        return 999; //deprecated
      case '/reservation':
        return 2;
      default:
        return 0; // 지도
    }
  }



  String getRouteForIndex(int index) {
    switch (index) {
      case 1:
        return '/mypage';
      case 999: //deprecated
        return '/feedback';
      case 2:
        return '/reservation';
      default:
        return '/'; // 지도
    }
  }



  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: [
        MaterialPage(
          child: Scaffold(
            body: IndexedStack(
              index: getIndexForRoute(_currentRoute),
              children: [
                MapScreen(key: _mapScreenKey),     // index 0: 지도 (GlobalKey 전달, const 제거)
                _authProvider.isLoggedIn ? MyPage() : LoginPage(), // index 1: 내정보
                //const FeedbackScreen(),           // index 2: 의견 -> deprecated
                const ReservationScreen(),        // index 3: 예약 -> 2로 수정 
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
                // BottomNavigationBarItem(
                //   icon: Icon(Icons.mail),
                //   label: '의견',
                // ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_month),
                  label: '예약',
                ),
              ],

              currentIndex: getIndexForRoute(_currentRoute),
              selectedItemColor: Colors.brown,
              unselectedItemColor: Colors.grey,

              onTap: (index) {
                // MapScreen에서 다른 탭으로 이동할 때 Bottom Sheet 닫기
                if (_currentRoute == '/' && index != 0) {
                  _mapScreenKey.currentState?.closeBottomSheetIfOpen();
                }

                _currentRoute = getRouteForIndex(index);
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

        if (_currentRoute == '/mypage' || _currentRoute == '/feedback') {
          _currentRoute = '/';
        }

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



class AppRouteInformationParser
    extends RouteInformationParser<RouteInformation> {
  @override
  Future<RouteInformation> parseRouteInformation(
      RouteInformation routeInformation) async {
    return routeInformation;
  }

  @override
  RouteInformation? restoreRouteInformation(RouteInformation configuration) {
    return configuration;
  }
}
