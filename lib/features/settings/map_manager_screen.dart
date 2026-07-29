import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rivox/app/theme/app_colors.dart';

class MapManagerScreen extends ConsumerWidget {
  const MapManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Map Manager', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.download), onPressed: () {})
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: AppColors.surface,
            child: ListTile(
              title: const Text('Campus Main Map', style: TextStyle(color: Colors.white)),
              subtitle: const Text('v1.0.2', style: TextStyle(color: Colors.white54)),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () {},
              ),
            ),
          )
        ],
      ),
    );
  }
}
