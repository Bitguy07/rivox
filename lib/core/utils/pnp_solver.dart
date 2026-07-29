import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';
import '../models/pose.dart';
import '../models/keyframe.dart';

/// PnP (Perspective-n-Point) solver with RANSAC for outlier rejection.
///
/// Estimates the camera pose from a set of 2D-3D point correspondences
/// using the DLT (Direct Linear Transform) method wrapped in RANSAC.
class PnPSolver {
  /// Solve PnP with RANSAC to find the camera pose.
  ///
  /// [points2D] — 2D keypoint locations in the query image.
  /// [points3D] — Corresponding 3D world positions.
  /// [intrinsics] — Camera intrinsic parameters.
  /// [iterations] — Number of RANSAC iterations (default 200).
  /// [reprojThreshold] — Max reprojection error in pixels for inlier (default 5.0).
  ///
  /// Returns a [Pose3D] (C2W) if enough inliers found, null otherwise.
  static Pose3D? solvePnP(
    List<Keypoint2D> points2D,
    List<Position3D> points3D,
    CameraIntrinsics intrinsics, {
    int iterations = 200,
    double reprojThreshold = 5.0,
    int minInliers = 6,
  }) {
    if (points2D.length != points3D.length || points2D.length < 6) {
      return null;
    }

    int bestInlierCount = 0;
    Matrix4? bestTransform;
    final random = math.Random(42); // Fixed seed for reproducibility
    final n = points2D.length;

    for (int iter = 0; iter < iterations; iter++) {
      // Pick 6 random correspondences for DLT
      final indices = <int>{};
      while (indices.length < 6) {
        indices.add(random.nextInt(n));
      }
      final idxList = indices.toList();

      // Build DLT system: Ax = 0 where x encodes the 3x4 projection matrix
      final samplePts2D =
          idxList.map((i) => points2D[i]).toList();
      final samplePts3D =
          idxList.map((i) => points3D[i]).toList();

      final transform = _solveDLT(samplePts2D, samplePts3D, intrinsics);
      if (transform == null) continue;

      // Count inliers
      int inliers = 0;
      for (int i = 0; i < n; i++) {
        final err =
            _reprojectionError(points2D[i], points3D[i], transform, intrinsics);
        if (err < reprojThreshold) {
          inliers++;
        }
      }

      if (inliers > bestInlierCount) {
        bestInlierCount = inliers;
        bestTransform = transform;
      }
    }

    if (bestTransform != null && bestInlierCount >= minInliers) {
      // Return C2W (invert the W2C transform)
      final c2w = Matrix4.copy(bestTransform)..invert();
      return Pose3D(c2w);
    }

    return null;
  }

  /// Solve the DLT for a small set of 2D-3D correspondences.
  ///
  /// Returns a world-to-camera 4x4 matrix, or null on failure.
  static Matrix4? _solveDLT(List<Keypoint2D> pts2D, List<Position3D> pts3D,
      CameraIntrinsics intrinsics) {
    // Normalize 2D points using intrinsics
    final numPts = pts2D.length;
    if (numPts < 6) return null;

    // Build the 2N x 12 matrix A for DLT
    // Each correspondence gives 2 equations
    final rows = numPts * 2;
    final a = List<List<double>>.generate(rows, (_) => List.filled(12, 0.0));

    for (int i = 0; i < numPts; i++) {
      final u = (pts2D[i].x - intrinsics.cx) / intrinsics.fx;
      final v = (pts2D[i].y - intrinsics.cy) / intrinsics.fy;
      final x = pts3D[i].x;
      final y = pts3D[i].y;
      final z = pts3D[i].z;

      // Row 2i: [X Y Z 1 0 0 0 0 -u*X -u*Y -u*Z -u]
      a[2 * i][0] = x;
      a[2 * i][1] = y;
      a[2 * i][2] = z;
      a[2 * i][3] = 1;
      a[2 * i][8] = -u * x;
      a[2 * i][9] = -u * y;
      a[2 * i][10] = -u * z;
      a[2 * i][11] = -u;

      // Row 2i+1: [0 0 0 0 X Y Z 1 -v*X -v*Y -v*Z -v]
      a[2 * i + 1][4] = x;
      a[2 * i + 1][5] = y;
      a[2 * i + 1][6] = z;
      a[2 * i + 1][7] = 1;
      a[2 * i + 1][8] = -v * x;
      a[2 * i + 1][9] = -v * y;
      a[2 * i + 1][10] = -v * z;
      a[2 * i + 1][11] = -v;
    }

    // Solve via ATA eigenvalue decomposition (simplified: use power iteration
    // on ATA to find the smallest eigenvector)
    final ata = _multiplyATA(a, rows, 12);
    final solution = _smallestEigenvector(ata, 12);
    if (solution == null) return null;

    // Reconstruct 3x4 projection matrix P from solution vector
    // P = [p1 p2 p3 p4; p5 p6 p7 p8; p9 p10 p11 p12]
    final r1 = Vector3(solution[0], solution[1], solution[2]);
    final r2 = Vector3(solution[4], solution[5], solution[6]);
    final r3 = Vector3(solution[8], solution[9], solution[10]);
    final t = Vector3(solution[3], solution[7], solution[11]);

    // Enforce orthogonality via SVD-like correction
    final scale = (r1.length + r2.length + r3.length) / 3.0;
    if (scale < 1e-10) return null;

    r1.normalize();
    r2.normalize();
    // Recompute r3 = r1 x r2 for orthogonality
    final r3c = r1.cross(r2)..normalize();

    final w2c = Matrix4(
      r1.x, r2.x, r3c.x, 0,
      r1.y, r2.y, r3c.y, 0,
      r1.z, r2.z, r3c.z, 0,
      t.x / scale, t.y / scale, t.z / scale, 1,
    );

    return w2c;
  }

  /// Compute reprojection error for a single correspondence.
  static double _reprojectionError(Keypoint2D pt2D, Position3D pt3D,
      Matrix4 w2c, CameraIntrinsics intrinsics) {
    final p = w2c.transform(Vector4(pt3D.x, pt3D.y, pt3D.z, 1.0));
    if (p.z <= 0) return double.infinity;

    final projX = (p.x / p.z) * intrinsics.fx + intrinsics.cx;
    final projY = (p.y / p.z) * intrinsics.fy + intrinsics.cy;

    final dx = projX - pt2D.x;
    final dy = projY - pt2D.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Compute A^T * A for a [rows] x [cols] matrix A stored as nested lists.
  static List<List<double>> _multiplyATA(
      List<List<double>> a, int rows, int cols) {
    final ata =
        List<List<double>>.generate(cols, (_) => List.filled(cols, 0.0));
    for (int i = 0; i < cols; i++) {
      for (int j = i; j < cols; j++) {
        double sum = 0;
        for (int k = 0; k < rows; k++) {
          sum += a[k][i] * a[k][j];
        }
        ata[i][j] = sum;
        ata[j][i] = sum;
      }
    }
    return ata;
  }

  /// Find the eigenvector corresponding to the smallest eigenvalue
  /// using inverse power iteration.
  static List<double>? _smallestEigenvector(
      List<List<double>> matrix, int size) {
    // Add small regularization to avoid singularity
    final mat = List<List<double>>.generate(
        size, (i) => List.generate(size, (j) => matrix[i][j]));
    for (int i = 0; i < size; i++) {
      mat[i][i] += 1e-10;
    }

    // Inverse power iteration
    var x = List<double>.generate(size, (i) => 1.0 / math.sqrt(size.toDouble()));
    const maxIter = 100;

    for (int iter = 0; iter < maxIter; iter++) {
      // Solve mat * y = x using Gaussian elimination
      final y = _solveLinearSystem(mat, x, size);
      if (y == null) return x;

      // Normalize
      double norm = 0;
      for (int i = 0; i < size; i++) {
        norm += y[i] * y[i];
      }
      norm = math.sqrt(norm);
      if (norm < 1e-15) return x;
      for (int i = 0; i < size; i++) {
        y[i] /= norm;
      }
      x = y;
    }

    return x;
  }

  /// Solve a linear system Ax = b using Gaussian elimination with partial pivoting.
  static List<double>? _solveLinearSystem(
      List<List<double>> a, List<double> b, int n) {
    // Augmented matrix
    final aug = List<List<double>>.generate(
        n, (i) => [...a[i], b[i]]);

    for (int col = 0; col < n; col++) {
      // Find pivot
      int maxRow = col;
      for (int row = col + 1; row < n; row++) {
        if (aug[row][col].abs() > aug[maxRow][col].abs()) {
          maxRow = row;
        }
      }
      final temp = aug[col];
      aug[col] = aug[maxRow];
      aug[maxRow] = temp;

      if (aug[col][col].abs() < 1e-12) continue;

      // Eliminate
      for (int row = col + 1; row < n; row++) {
        final factor = aug[row][col] / aug[col][col];
        for (int j = col; j <= n; j++) {
          aug[row][j] -= factor * aug[col][j];
        }
      }
    }

    // Back substitution
    final x = List<double>.filled(n, 0.0);
    for (int i = n - 1; i >= 0; i--) {
      if (aug[i][i].abs() < 1e-12) continue;
      x[i] = aug[i][n];
      for (int j = i + 1; j < n; j++) {
        x[i] -= aug[i][j] * x[j];
      }
      x[i] /= aug[i][i];
    }

    return x;
  }
}
