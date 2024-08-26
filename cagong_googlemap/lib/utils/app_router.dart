import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '../screens/map_screen.dart';
import '../screens/mypage_screen.dart';
import '../screens/payments_screen.dart';

class AppRouterDelegate extends RouterDelegate<RouteInformation>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<RouteInformation> {
  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  int _selectedIndex = 0;

  List<Widget> get _screens => [
        const MapScreen(),
        const PaymentScreen(),
        // const MypageScreen(),
      ];

  void _onItemTapped(int index) {
    _selectedIndex = index;
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
              index: _selectedIndex,
              children: _screens,
            ),
            bottomNavigationBar: BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.map),
                  label: '지도',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.payment),
                  label: '결제',
                ),
                // BottomNavigationBarItem(
                //   icon: Icon(Icons.person),
                //   label: '마이페이지',
                // ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.blue,
              unselectedItemColor: Colors.grey,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
            ),
          ),
        ),
      ],
      onPopPage: (route, result) => route.didPop(result),
    );
  }

  @override
  Future<void> setNewRoutePath(RouteInformation configuration) async {
    // 딥 링크나 웹 URL 처리를 위한 로직을 여기에 구현할 수 있습니다.
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
