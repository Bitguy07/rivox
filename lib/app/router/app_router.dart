import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/splash_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/map_3d/map_3d_screen.dart';
import '../../features/map_2d/map_2d_screen.dart';
import '../../features/localize/localize_screen.dart';
import '../../features/navigation/search_destination_screen.dart';
import '../../features/navigation/active_navigation_screen.dart';
import '../../features/video_capture/video_capture_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/map_manager_screen.dart';

/// Route path constants.
abstract final class RoutePaths {
  static const splash = '/';
  static const home = '/home';
  static const map3d = '/map-3d';
  static const map2d = '/map-2d';
  static const localize = '/localize';
  static const searchDestination = '/navigate/search';
  static const activeNavigation = '/navigate/active';
  static const videoCapture = '/video-capture';
  static const settings = '/settings';
  static const mapManager = '/settings/map-manager';
}

/// Shell widget with bottom navigation bar for main app sections.
class AppShell extends StatelessWidget {
  final Widget child;
  final GoRouterState state;

  const AppShell({super.key, required this.child, required this.state});

  int _calculateSelectedIndex(String location) {
    if (location.startsWith('/map-3d')) return 1;
    if (location.startsWith('/map-2d')) return 2;
    if (location.startsWith('/navigate')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(
      state.uri.toString(),
    );

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go(RoutePaths.home);
            case 1:
              context.go(RoutePaths.map3d);
            case 2:
              context.go(RoutePaths.map2d);
            case 3:
              context.go(RoutePaths.searchDestination);
            case 4:
              context.go(RoutePaths.settings);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.view_in_ar_outlined),
            selectedIcon: Icon(Icons.view_in_ar),
            label: '3D Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: '2D Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.navigation_outlined),
            selectedIcon: Icon(Icons.navigation),
            label: 'Navigate',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

/// Application router configuration.
GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: RoutePaths.splash,
    routes: [
      // Splash screen (no shell)
      GoRoute(
        path: RoutePaths.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Main app with bottom navigation shell
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(state: state, child: child),
        routes: [
          GoRoute(
            path: RoutePaths.home,
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const HomeScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          GoRoute(
            path: RoutePaths.map3d,
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const Map3DScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          GoRoute(
            path: RoutePaths.map2d,
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const Map2DScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          GoRoute(
            path: RoutePaths.searchDestination,
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const SearchDestinationScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          GoRoute(
            path: RoutePaths.settings,
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const SettingsScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
        ],
      ),

      // Full-screen routes (no bottom nav)
      GoRoute(
        path: RoutePaths.localize,
        builder: (context, state) => const LocalizeScreen(),
      ),
      GoRoute(
        path: RoutePaths.activeNavigation,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ActiveNavigationScreen(
            fromNodeId: extra?['fromNodeId'] as String? ?? '',
            toNodeId: extra?['toNodeId'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: RoutePaths.videoCapture,
        builder: (context, state) => const VideoCaptureScreen(),
      ),
      GoRoute(
        path: RoutePaths.mapManager,
        builder: (context, state) => const MapManagerScreen(),
      ),
    ],
  );
}

Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(opacity: animation, child: child);
}
