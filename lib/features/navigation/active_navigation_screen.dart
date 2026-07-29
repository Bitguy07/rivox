import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rivox/app/theme/app_colors.dart';
import 'package:rivox/core/models/nav_graph.dart';
import 'package:rivox/core/providers/providers.dart';

class ActiveNavigationScreen extends ConsumerWidget {
  final String fromNodeId;
  final String toNodeId;

  const ActiveNavigationScreen({
    super.key,
    required this.fromNodeId,
    required this.toNodeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeRoute = ref.watch(activeRouteProvider);
    final instructions = activeRoute?.getInstructions() ?? [];
    final currentIndex = ref.watch(currentInstructionIndexProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            ref.read(activeRouteProvider.notifier).state = null;
            ref.read(currentInstructionIndexProvider.notifier).state = 0;
            context.pop();
          },
        ),
        title: const Text('Navigating', style: TextStyle(color: Colors.white)),
      ),
      body: Stack(
        children: [
          // Map area placeholder — in production this would be the 2D map
          const Center(
            child: Text(
              'Navigation Map View',
              style: TextStyle(color: Colors.white38, fontSize: 18),
            ),
          ),

          // Route info panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Route summary
                  if (activeRoute != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Distance: ${activeRoute.totalDistance.toStringAsFixed(0)}m',
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        Text(
                          'ETA: ${activeRoute.estimatedTimeFormatted}',
                          style: const TextStyle(color: AppColors.accent, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Current instruction
                  if (instructions.isNotEmpty && currentIndex < instructions.length)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _instructionIcon(instructions[currentIndex].type),
                            color: AppColors.routePath,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              instructions[currentIndex].text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // End navigation button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        ref.read(activeRouteProvider.notifier).state = null;
                        ref.read(currentInstructionIndexProvider.notifier).state = 0;
                        context.pop();
                      },
                      child: const Text(
                        'End Navigation',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _instructionIcon(NavInstructionType type) {
    return switch (type) {
      NavInstructionType.start => Icons.play_circle,
      NavInstructionType.walk => Icons.straight,
      NavInstructionType.turnLeft => Icons.turn_left,
      NavInstructionType.turnRight => Icons.turn_right,
      NavInstructionType.stairs => Icons.stairs,
      NavInstructionType.elevator => Icons.elevator,
      NavInstructionType.arrive => Icons.place,
      NavInstructionType.destination => Icons.flag,
    };
  }
}
