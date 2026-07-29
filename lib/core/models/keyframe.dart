import 'dart:typed_data';

import 'pose.dart';

/// Camera intrinsic parameters.
class CameraIntrinsics {
  /// Focal length in pixels (x-axis).
  final double fx;

  /// Focal length in pixels (y-axis).
  final double fy;

  /// Principal point x-coordinate in pixels.
  final double cx;

  /// Principal point y-coordinate in pixels.
  final double cy;

  /// Image width in pixels.
  final int width;

  /// Image height in pixels.
  final int height;

  const CameraIntrinsics({
    required this.fx,
    required this.fy,
    required this.cx,
    required this.cy,
    required this.width,
    required this.height,
  });

  factory CameraIntrinsics.fromJson(Map<String, dynamic> json) =>
      CameraIntrinsics(
        fx: (json['fx'] as num).toDouble(),
        fy: (json['fy'] as num).toDouble(),
        cx: (json['cx'] as num).toDouble(),
        cy: (json['cy'] as num).toDouble(),
        width: (json['width'] as num).toInt(),
        height: (json['height'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {
    'fx': fx,
    'fy': fy,
    'cx': cx,
    'cy': cy,
    'width': width,
    'height': height,
  };

  @override
  String toString() =>
      'CameraIntrinsics(fx=$fx, fy=$fy, cx=$cx, cy=$cy, ${width}x$height)';
}

/// A single 2D keypoint detected in an image.
class Keypoint2D {
  final double x;
  final double y;

  const Keypoint2D(this.x, this.y);

  factory Keypoint2D.fromJson(Map<String, dynamic> json) => Keypoint2D(
    (json['x'] as num).toDouble(),
    (json['y'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {'x': x, 'y': y};
}

/// A keyframe from the 3D reconstruction with associated
/// descriptors and 2D↔3D correspondences for visual localization.
class KeyframeEntry {
  /// Unique identifier for this keyframe.
  final String id;

  /// The camera pose when this keyframe was captured (C2W).
  final Pose3D pose;

  /// Camera intrinsics used to capture this keyframe.
  final CameraIntrinsics intrinsics;

  /// Global image descriptor (e.g., color histogram or neural embedding).
  /// Used for fast retrieval (kNN search).
  final Float32List globalDescriptor;

  /// 2D keypoint locations in this keyframe image.
  final List<Keypoint2D> keypoints;

  /// 3D world positions corresponding to each keypoint (same order).
  /// These are from the LingBot-Map depth prediction projected to world coords.
  final List<Position3D> points3D;

  /// Relative path to the keyframe image file within the map package.
  final String imagePath;

  const KeyframeEntry({
    required this.id,
    required this.pose,
    required this.intrinsics,
    required this.globalDescriptor,
    required this.keypoints,
    required this.points3D,
    required this.imagePath,
  });

  /// Number of 2D↔3D correspondences available.
  int get correspondenceCount => keypoints.length;

  factory KeyframeEntry.fromJson(Map<String, dynamic> json) {
    final descriptorList = (json['global_descriptor'] as List)
        .cast<num>()
        .map((e) => e.toDouble())
        .toList();

    return KeyframeEntry(
      id: json['id'] as String,
      pose: Pose3D.fromJson(json['pose'] as Map<String, dynamic>),
      intrinsics: CameraIntrinsics.fromJson(
          json['intrinsics'] as Map<String, dynamic>),
      globalDescriptor: Float32List.fromList(
          descriptorList.map((e) => e).toList()),
      keypoints: (json['keypoints'] as List)
          .map((e) => Keypoint2D.fromJson(e as Map<String, dynamic>))
          .toList(),
      points3D: (json['points_3d'] as List)
          .map((e) => Position3D.fromJson(e as Map<String, dynamic>))
          .toList(),
      imagePath: json['image_path'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'pose': pose.toJson(),
    'intrinsics': intrinsics.toJson(),
    'global_descriptor': globalDescriptor.toList(),
    'keypoints': keypoints.map((k) => k.toJson()).toList(),
    'points_3d': points3D.map((p) => p.toJson()).toList(),
    'image_path': imagePath,
  };
}

/// A database of keyframes for visual localization.
///
/// Supports brute-force kNN search on global descriptors
/// to find candidate keyframes for PnP pose estimation.
class KeyframeDatabase {
  final List<KeyframeEntry> keyframes;

  KeyframeDatabase(this.keyframes);

  factory KeyframeDatabase.fromJson(Map<String, dynamic> json) {
    final entries = (json['keyframes'] as List)
        .map((e) => KeyframeEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    return KeyframeDatabase(entries);
  }

  Map<String, dynamic> toJson() => {
    'keyframes': keyframes.map((k) => k.toJson()).toList(),
  };

  int get count => keyframes.length;

  bool get isEmpty => keyframes.isEmpty;

  /// Find the top-K nearest keyframes by L2 distance on global descriptors.
  ///
  /// This is a brute-force search suitable for small databases (<10k keyframes).
  /// For larger databases, replace with Faiss or an approximate NN index.
  List<KeyframeMatch> findTopK(Float32List queryDescriptor, int k) {
    if (keyframes.isEmpty) return [];

    final matches = <KeyframeMatch>[];

    for (final kf in keyframes) {
      final dist = _l2Distance(queryDescriptor, kf.globalDescriptor);
      matches.add(KeyframeMatch(keyframe: kf, distance: dist));
    }

    matches.sort((a, b) => a.distance.compareTo(b.distance));
    return matches.take(k).toList();
  }

  /// Compute L2 (Euclidean) distance between two descriptor vectors.
  double _l2Distance(Float32List a, Float32List b) {
    assert(a.length == b.length,
        'Descriptor length mismatch: ${a.length} vs ${b.length}');

    double sum = 0;
    for (int i = 0; i < a.length; i++) {
      final diff = a[i] - b[i];
      sum += diff * diff;
    }
    return sum; // Squared L2 is sufficient for ranking
  }
}

/// Result of a keyframe matching query.
class KeyframeMatch {
  final KeyframeEntry keyframe;
  final double distance;

  const KeyframeMatch({required this.keyframe, required this.distance});
}
