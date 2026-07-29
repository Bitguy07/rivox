import 'package:vector_math/vector_math_64.dart';
import '../models/pose.dart';
import '../models/keyframe.dart';

/// Utility functions for 3D↔2D projection using camera models.
class MatrixUtils {
  /// Project a 3D world point to 2D image coordinates.
  ///
  /// [point3D] is the world position.
  /// [intrinsics] defines the camera's focal length and principal point.
  /// [pose] is the camera-to-world transform (C2W); we invert it to get W2C.
  ///
  /// Returns a [Keypoint2D] with pixel coordinates, or (0,0) if behind camera.
  static Keypoint2D projectPoint3D(
      Position3D point3D, CameraIntrinsics intrinsics, Pose3D pose) {
    // World-to-camera: invert the C2W pose
    final w2c = Matrix4.copy(pose.matrix)..invert();
    final pointHomogeneous = Vector4(point3D.x, point3D.y, point3D.z, 1.0);
    final pointInCamera = w2c.transform(pointHomogeneous);

    final z = pointInCamera.z;
    if (z <= 0) return const Keypoint2D(0, 0);

    final x = (pointInCamera.x / z) * intrinsics.fx + intrinsics.cx;
    final y = (pointInCamera.y / z) * intrinsics.fy + intrinsics.cy;

    return Keypoint2D(x, y);
  }

  /// Unproject a 2D image point with known depth to 3D world coordinates.
  ///
  /// [point2D] is the pixel coordinate.
  /// [depth] is the depth (Z in camera frame).
  /// [intrinsics] defines the camera model.
  /// [pose] is the camera-to-world transform (C2W).
  static Position3D unprojectPoint2D(
      Keypoint2D point2D, double depth, CameraIntrinsics intrinsics, Pose3D pose) {
    // Convert pixel to camera-frame 3D point
    final x = (point2D.x - intrinsics.cx) * depth / intrinsics.fx;
    final y = (point2D.y - intrinsics.cy) * depth / intrinsics.fy;

    final pointInCamera = Vector4(x, y, depth, 1.0);

    // Camera-to-world transform
    final pointInWorld = pose.matrix.transform(pointInCamera);

    return Position3D(
        x: pointInWorld.x, y: pointInWorld.y, z: pointInWorld.z);
  }
}
