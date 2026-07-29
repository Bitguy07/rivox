import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:rivox/app/theme/app_colors.dart';
import 'package:rivox/core/providers/providers.dart';

class Map3DScreen extends ConsumerWidget {
  const Map3DScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMapLoaded = ref.watch(isMapLoadedProvider);
    final mapPackage = ref.watch(loadedMapProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('3D Map', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: !isMapLoaded
          ? _buildNoMapState(context)
          : Stack(
              children: [
                ModelViewer(
                  backgroundColor: AppColors.background,
                  src: 'file://${mapPackage?.glbFilePath ?? ''}',
                  alt: 'A 3D model of the campus',
                  ar: false,
                  autoRotate: false,
                  cameraControls: true,
                ),
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _buildFloorSelector(ref),
                  ),
                ),
              ],
            ),
      floatingActionButton: isMapLoaded
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/localize'),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.my_location),
              label: const Text('Localize'),
            )
          : null,
    );
  }

  Widget _buildNoMapState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map_outlined, size: 80, color: Colors.white54),
          const SizedBox(height: 16),
          const Text(
            'No Map Loaded',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please import a map package to view the 3D map.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/settings/map-manager'),
            icon: const Icon(Icons.download),
            label: const Text('Go to Map Manager'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloorSelector(WidgetRef ref) {
    final mapPackage = ref.watch(loadedMapProvider);
    final floors = mapPackage?.navGraph.floors ?? [0];
    final selectedFloor = ref.watch(selectedFloorProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.glassBackground,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: floors.map((floor) {
          final isSelected = selectedFloor == floor;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text('Floor $floor'),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  ref.read(selectedFloorProvider.notifier).state = floor;
                }
              },
              selectedColor: AppColors.primary,
              backgroundColor: Colors.transparent,
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70),
            ),
          );
        }).toList(),
      ),
    );
  }
}
