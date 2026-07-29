import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/map_package.dart';
import '../models/nav_graph.dart';
import '../models/pose.dart';
import '../services/map_storage_service.dart';
import '../services/navigation_service.dart';
import '../services/imu_tracking_service.dart';
import '../services/localization_service.dart';

// ─── Map Storage ───

/// Provides the map storage service singleton.
final mapStorageServiceProvider = Provider<MapStorageService>((ref) {
  return MapStorageService();
});

/// The currently loaded map package (null if none loaded).
final loadedMapProvider = StateProvider<LoadedMapPackage?>((ref) => null);

/// Whether a map is currently loaded and ready.
final isMapLoadedProvider = Provider<bool>((ref) {
  return ref.watch(loadedMapProvider) != null;
});

// ─── Navigation ───

/// Navigation service provider.
final navigationServiceProvider = Provider<NavigationService>((ref) {
  return NavigationService();
});

/// The current navigation graph (from loaded map).
final navGraphProvider = Provider<NavGraph?>((ref) {
  return ref.watch(loadedMapProvider)?.navGraph;
});

/// Current active navigation route.
final activeRouteProvider = StateProvider<NavRoute?>((ref) => null);

/// Navigation instructions for the active route.
final activeInstructionsProvider = Provider<List<NavInstruction>>((ref) {
  final route = ref.watch(activeRouteProvider);
  return route?.getInstructions() ?? [];
});

/// Current instruction index during active navigation.
final currentInstructionIndexProvider = StateProvider<int>((ref) => 0);

// ─── User Position & Tracking ───

/// The user's current position in map coordinates.
final userPositionProvider =
    StateNotifierProvider<UserPositionNotifier, Position3D?>((ref) {
  return UserPositionNotifier();
});

/// The user's current heading in radians (from north/positive-Y).
final userHeadingProvider = StateProvider<double>((ref) => 0.0);

/// Whether IMU tracking is currently active.
final isTrackingActiveProvider = StateProvider<bool>((ref) => false);

/// IMU tracking service.
final imuTrackingServiceProvider = Provider<ImuTrackingService>((ref) {
  return ImuTrackingService();
});

// ─── Localization ───

/// Localization service.
final localizationServiceProvider = Provider<LocalizationService>((ref) {
  return LocalizationService();
});

/// Whether localization has been performed (user is positioned on map).
final isLocalizedProvider = StateProvider<bool>((ref) => false);

// ─── Search / UI State ───

/// Currently selected floor for map views.
final selectedFloorProvider = StateProvider<int>((ref) => 0);

/// Search query for destination search.
final destinationSearchQueryProvider = StateProvider<String>((ref) => '');

/// Filtered search results based on query.
final searchResultsProvider = Provider<List<NavNode>>((ref) {
  final query = ref.watch(destinationSearchQueryProvider);
  final navGraph = ref.watch(navGraphProvider);
  if (navGraph == null || query.isEmpty) return [];
  return navGraph.searchNodes(query);
});

/// Selected destination node for navigation.
final selectedDestinationProvider = StateProvider<NavNode?>((ref) => null);

// ─── Admin State ───

/// Whether admin mode is enabled (shows recording, map management features).
final isAdminModeProvider = StateProvider<bool>((ref) => true);

// ─── Position Notifier ───

/// State notifier for user position with smooth updates.
class UserPositionNotifier extends StateNotifier<Position3D?> {
  UserPositionNotifier() : super(null);

  void setPosition(Position3D position) {
    state = position;
  }

  void updatePosition(double dx, double dy, double dz) {
    if (state == null) return;
    state = Position3D(
      x: state!.x + dx,
      y: state!.y + dy,
      z: state!.z + dz,
      floor: state!.floor,
    );
  }

  void setFloor(int floor) {
    if (state == null) return;
    state = state!.copyWith(floor: floor);
  }

  void clear() {
    state = null;
  }
}
