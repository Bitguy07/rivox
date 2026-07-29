import '../models/pose.dart';
import '../models/keyframe.dart';
import '../utils/descriptor_extractor.dart';
import '../utils/pnp_solver.dart';

/// Visual localization service that matches a camera photo against the
/// keyframe database to estimate the user's position on the map.
///
/// Pipeline:
/// 1. Extract a global descriptor from the query image.
/// 2. Search the keyframe database for the top-K nearest matches.
/// 3. For the best match, use its 2D-3D correspondences with PnP
///    to estimate the camera pose (= user position).
class LocalizationService {
  /// Localize the user from a camera photo.
  ///
  /// [imageBytes] — Raw JPEG/PNG bytes from the camera.
  /// [database] — The keyframe database from the loaded map package.
  ///
  /// Returns a [Pose3D] if localization succeeds, null otherwise.
  Pose3D? localize(List<int> imageBytes, KeyframeDatabase database) {
    if (database.isEmpty) return null;

    // 1. Extract global descriptor from the query image
    final descriptor = DescriptorExtractor.extractGlobalDescriptor(imageBytes);
    if (descriptor.isEmpty) return null;

    // 2. Find top-K nearest keyframes by descriptor distance
    final matches = database.findTopK(descriptor, 3);
    if (matches.isEmpty) return null;

    // 3. For each match, try to solve PnP using the keyframe's
    //    2D-3D correspondences
    for (final match in matches) {
      final kf = match.keyframe;

      // Check that this keyframe has enough correspondences
      if (kf.correspondenceCount < 6) continue;

      final pose = PnPSolver.solvePnP(
        kf.keypoints,
        kf.points3D,
        kf.intrinsics,
      );

      if (pose != null) return pose;
    }

    // If PnP failed for all matches, fall back to the best match's
    // keyframe pose as an approximate localization.
    final bestMatch = matches.first;
    if (bestMatch.distance < 0.5) {
      // Only if the match is reasonably close
      return bestMatch.keyframe.pose;
    }

    return null;
  }
}
