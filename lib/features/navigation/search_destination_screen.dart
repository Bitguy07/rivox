import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rivox/app/theme/app_colors.dart';
import 'package:rivox/core/providers/providers.dart';

class SearchDestinationScreen extends ConsumerWidget {
  const SearchDestinationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: TextField(
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search destinations...',
            hintStyle: TextStyle(color: Colors.white54),
            border: InputBorder.none,
          ),
          onChanged: (val) {
            ref.read(destinationSearchQueryProvider.notifier).state = val;
          },
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.meeting_room, color: AppColors.accent),
            title: const Text('Room 101', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Floor 1', style: TextStyle(color: Colors.white54)),
            onTap: () {
              context.push('/active-navigation');
            },
          )
        ],
      ),
    );
  }
}
