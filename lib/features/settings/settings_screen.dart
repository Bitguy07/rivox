import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rivox/app/theme/app_colors.dart';
import 'package:rivox/core/providers/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminModeProvider);
    final mapPackage = ref.watch(loadedMapProvider);
    final isMapLoaded = ref.watch(isMapLoadedProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Admin mode toggle
          _buildSection(
            'Mode',
            [
              SwitchListTile(
                title: const Text('Admin Mode', style: TextStyle(color: Colors.white)),
                subtitle: const Text(
                  'Enables recording, map import, and advanced features',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                value: isAdmin,
                onChanged: (val) => ref.read(isAdminModeProvider.notifier).state = val,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                thumbColor: WidgetStateProperty.resolveWith((states) {
                  return states.contains(WidgetState.selected)
                      ? AppColors.primary
                      : Colors.grey;
                }),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Map info section
          _buildSection(
            'Map',
            [
              ListTile(
                leading: Icon(
                  isMapLoaded ? Icons.check_circle : Icons.error_outline,
                  color: isMapLoaded ? AppColors.success : AppColors.error,
                ),
                title: Text(
                  isMapLoaded
                      ? mapPackage!.metadata.name
                      : 'No Map Loaded',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: isMapLoaded
                    ? Text(
                        'v${mapPackage!.metadata.version} • ${mapPackage.metadata.recordingCount} recordings',
                        style: const TextStyle(color: Colors.white54),
                      )
                    : null,
              ),
              ListTile(
                title: const Text('Manage Maps', style: TextStyle(color: Colors.white)),
                leading: const Icon(Icons.folder_open, color: Colors.white54),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                onTap: () => context.push('/settings/map-manager'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Admin actions
          if (isAdmin) ...[
            _buildSection(
              'Admin Actions',
              [
                ListTile(
                  title: const Text('Record Campus Video', style: TextStyle(color: Colors.white)),
                  leading: const Icon(Icons.videocam, color: AppColors.error),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                  onTap: () => context.push('/video-capture'),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Tracking settings
          _buildSection(
            'Navigation',
            [
              ListTile(
                title: const Text('Stride Length', style: TextStyle(color: Colors.white)),
                subtitle: const Text('0.7m (default)', style: TextStyle(color: Colors.white54)),
                leading: const Icon(Icons.straighten, color: Colors.white54),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // About
          _buildSection(
            'About',
            [
              const ListTile(
                title: Text('Rivox', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(
                  'v1.0.0 • Offline Campus Navigation\nBuilt with Flutter & LingBot-Map',
                  style: TextStyle(color: Colors.white54),
                ),
                leading: Icon(Icons.info_outline, color: Colors.white54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}
