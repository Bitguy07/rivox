import 'dart:math';

import 'package:vector_math/vector_math_64.dart';

/// Represents a 3D position with optional floor information.
class Position3D {
  final double x;
  final double y;
  final double z;
  final int floor;

  const Position3D({
    required this.x,
    required this.y,
    required this.z,
    this.floor = 0,
  });

  Position3D copyWith({double? x, double? y, double? z, int? floor}) {
    return Position3D(
      x: x ?? this.x,
      y: y ?? this.y,
      z: z ?? this.z,
      floor: floor ?? this.floor,
    );
  }

  /// Euclidean distance to another position (3D).
  double distanceTo(Position3D other) {
    final dx = x - other.x;
    final dy = y - other.y;
    final dz = z - other.z;
    return sqrt(dx * dx + dy * dy + dz * dz);
  }

  /// 2D distance (ignoring Z/height).
  double distanceTo2D(Position3D other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return sqrt(dx * dx + dy * dy);
  }

  Vector3 toVector3() => Vector3(x, y, z);

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'z': z,
    'floor': floor,
  };

  factory Position3D.fromJson(Map<String, dynamic> json) => Position3D(
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    z: (json['z'] as num).toDouble(),
    floor: (json['floor'] as num?)?.toInt() ?? 0,
  );

  factory Position3D.zero() => const Position3D(x: 0, y: 0, z: 0);

  @override
  String toString() => 'Position3D($x, $y, $z, floor=$floor)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position3D &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          z == other.z &&
          floor == other.floor;

  @override
  int get hashCode => Object.hash(x, y, z, floor);
}

/// Represents a full 6-DOF pose (position + orientation) as a 4x4
/// camera-to-world (C2W) transformation matrix.
class Pose3D {
  /// The 4x4 camera-to-world transformation matrix.
  /// Column-major order (as used by vector_math).
  final Matrix4 matrix;

  Pose3D(this.matrix);

  /// Create an identity pose (origin, no rotation).
  factory Pose3D.identity() => Pose3D(Matrix4.identity());

  /// Create from position and forward direction.
  factory Pose3D.fromPositionAndForward(Vector3 position, Vector3 forward) {
    final up = Vector3(0, 1, 0);
    final right = forward.cross(up)..normalize();
    final correctedUp = right.cross(forward)..normalize();

    final mat = Matrix4.identity();
    mat.setColumn(0, Vector4(right.x, right.y, right.z, 0));
    mat.setColumn(1, Vector4(correctedUp.x, correctedUp.y, correctedUp.z, 0));
    mat.setColumn(2, Vector4(-forward.x, -forward.y, -forward.z, 0));
    mat.setColumn(3, Vector4(position.x, position.y, position.z, 1));
    return Pose3D(mat);
  }

  /// Create from 16 doubles (row-major order, as stored in traj.txt).
  factory Pose3D.fromRowMajorList(List<double> values) {
    assert(values.length == 16, 'Expected 16 values for 4x4 matrix');
    final mat = Matrix4.fromList(values);
    mat.transpose(); // Convert row-major to column-major
    return Pose3D(mat);
  }

  /// Extract position (translation) from the matrix.
  Position3D get position => Position3D(
    x: matrix.entry(0, 3),
    y: matrix.entry(1, 3),
    z: matrix.entry(2, 3),
  );

  /// Extract position as Vector3.
  Vector3 get positionVector => Vector3(
    matrix.entry(0, 3),
    matrix.entry(1, 3),
    matrix.entry(2, 3),
  );

  /// Extract forward direction (negative Z axis in camera convention).
  Vector3 get forward => Vector3(
    -matrix.entry(0, 2),
    -matrix.entry(1, 2),
    -matrix.entry(2, 2),
  );

  /// Extract right direction (X axis).
  Vector3 get right => Vector3(
    matrix.entry(0, 0),
    matrix.entry(1, 0),
    matrix.entry(2, 0),
  );

  /// Extract up direction (Y axis).
  Vector3 get up => Vector3(
    matrix.entry(0, 1),
    matrix.entry(1, 1),
    matrix.entry(2, 1),
  );

  /// Extract the 3x3 rotation matrix.
  Matrix3 get rotation => matrix.getRotation();

  /// Get the heading angle (yaw) in radians, measured from positive X axis.
  double get heading {
    final fwd = forward;
    return atan2(fwd.y, fwd.x);
  }

  /// Apply a transformation to this pose.
  Pose3D transform(Matrix4 t) => Pose3D(t * matrix);

  /// Inverse of this pose (world-to-camera).
  Pose3D get inverse => Pose3D(Matrix4.copy(matrix)..invert());

  /// Serialize to row-major list of 16 doubles.
  List<double> toRowMajorList() {
    final transposed = Matrix4.copy(matrix)..transpose();
    return List<double>.generate(16, (i) => transposed.storage[i]);
  }

  Map<String, dynamic> toJson() => {
    'matrix': toRowMajorList(),
  };

  factory Pose3D.fromJson(Map<String, dynamic> json) {
    final values = (json['matrix'] as List).cast<num>().map((e) => e.toDouble()).toList();
    return Pose3D.fromRowMajorList(values);
  }

  @override
  String toString() => 'Pose3D(pos=$position, heading=${(heading * 180 / pi).toStringAsFixed(1)}°)';
}
