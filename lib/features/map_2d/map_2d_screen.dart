import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rivox/app/theme/app_colors.dart';
import 'package:rivox/core/providers/providers.dart';
import 'widgets/map_2d_painter.dart';

class Map2DScreen extends ConsumerWidget {
  const Map2DScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMapLoaded = ref.watch(isMapLoadedProvider);
    final mapPackage = ref.watch(loadedMapProvider);
    final selectedFloor = ref.watch(selectedFloorProvider);
    final userPosition = ref.watch(userPositionProvider);
    final activeRoute = ref.watch(activeRouteProvider);

    // Get floor-specific data from the loaded map
    final floorLayer = mapPackage?.floorPlan.layers[selectedFloor];
    final nodesOnFloor = mapPackage?.navGraph.getNodesOnFloor(selectedFloor);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('2D Map', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Floor selector dropdown
          if (isMapLoaded)
            PopupMenuButton<int>(
              icon: const Icon(Icons.layers, color: Colors.white),
              onSelected: (floor) {
                ref.read(selectedFloorProvider.notifier).state = floor;
              },
              itemBuilder: (context) {
                final floors = mapPackage?.navGraph.floors ?? [0];
                return floors.map((f) => PopupMenuItem(
                  value: f,
                  child: Text(
                    'Floor $f',
                    style: TextStyle(
                      fontWeight: f == selectedFloor ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                )).toList();
              },
            ),
        ],
      ),
      body: !isMapLoaded
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.map_outlined, size: 80, color: Colors.white54),
                  const SizedBox(height: 16),
                  const Text('No Map Loaded', style: TextStyle(color: Colors.white, fontSize: 20)),
                  const SizedBox(height: 8),
                  const Text('Import a map to see the floor plan', style: TextStyle(color: Colors.white54)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.push('/settings/map-manager'),
                    child: const Text('Import Map'),
                  ),
                ],
              ),
            )
          : InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,
              boundaryMargin: const EdgeInsets.all(200),
              child: SizedBox(
                width: 1000,
                height: 1000,
                child: CustomPaint(
                  painter: Map2DPainter(
                    floorLayer: floorLayer,
                    nodesOnFloor: nodesOnFloor,
                    userPosition: userPosition,
                    activeRoute: activeRoute,
                  ),
                ),
              ),
            ),
      floatingActionButton: isMapLoaded
          ? FloatingActionButton(
              onPressed: () => context.push('/localize'),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.my_location),
            )
          : null,
    );
  }
}
