import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rivox/app/theme/app_colors.dart';
import 'package:rivox/core/providers/providers.dart';

class LocalizeScreen extends ConsumerStatefulWidget {
  const LocalizeScreen({super.key});

  @override
  ConsumerState<LocalizeScreen> createState() => _LocalizeScreenState();
}

class _LocalizeScreenState extends ConsumerState<LocalizeScreen> {
  CameraController? _controller;
  bool _isProcessing = false;
  int _photoCount = 0;
  String _statusText = 'Point your camera at a distinctive area';

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _controller = CameraController(cameras.first, ResolutionPreset.medium);
        await _controller?.initialize();
        if (mounted) setState(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() => _statusText = 'Camera not available');
      }
    }
  }

  Future<void> _takePhotoAndLocalize() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusText = 'Processing photo...';
    });

    try {
      final photo = await _controller!.takePicture();
      final imageBytes = await photo.readAsBytes();

      setState(() {
        _photoCount++;
        _statusText = 'Matching against keyframe database...';
      });

      // Use the localization service to match the photo
      final localizationService = ref.read(localizationServiceProvider);
      final mapPackage = ref.read(loadedMapProvider);

      if (mapPackage != null) {
        final pose = localizationService.localize(
          imageBytes.toList(),
          mapPackage.keyframeDb,
        );

        if (pose != null && mounted) {
          // Successfully localized — update user position
          ref.read(userPositionProvider.notifier).setPosition(pose.position);
          ref.read(isLocalizedProvider.notifier).state = true;
          ref.read(isTrackingActiveProvider.notifier).state = true;

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Localized! Position: (${pose.position.x.toStringAsFixed(1)}, '
                  '${pose.position.y.toStringAsFixed(1)}, '
                  '${pose.position.z.toStringAsFixed(1)})',
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.pop();
          }
          return;
        }
      }

      // Localization failed
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusText = _photoCount < 2
              ? 'Try again from a different angle'
              : 'Could not localize. Ensure you are in a mapped area.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusText = 'Error: ${e.toString()}';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMapLoaded = ref.watch(isMapLoadedProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          if (_controller?.value.isInitialized ?? false)
            Positioned.fill(child: CameraPreview(_controller!)),

          // Processing overlay
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.accent),
                      SizedBox(height: 16),
                      Text(
                        'Localizing...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      onPressed: () => context.pop(),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.glassBackground,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Photo $_photoCount/2',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status text
                    Text(
                      _statusText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 24),

                    // Take photo button
                    GestureDetector(
                      onTap: isMapLoaded && !_isProcessing
                          ? _takePhotoAndLocalize
                          : null,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          color: _isProcessing
                              ? Colors.grey
                              : AppColors.primary,
                        ),
                        child: const Icon(
                          Icons.camera,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),

                    if (!isMapLoaded) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Load a map first to enable localization',
                        style: TextStyle(color: AppColors.warning, fontSize: 12),
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Privacy notice
                    const Text(
                      'Photos are processed locally and never uploaded',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
