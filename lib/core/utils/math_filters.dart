// Signal processing filters for IMU sensor fusion.
//
// Used by the IMU tracking service for heading estimation
// and position smoothing.

/// First-order IIR low-pass filter.
///
/// Smooths noisy sensor readings. Higher alpha = more smoothing.
class LowPassFilter {
  final double alpha;
  double? _lastVal;

  LowPassFilter(this.alpha);

  double filter(double value) {
    if (_lastVal == null) {
      _lastVal = value;
      return value;
    }
    _lastVal = _lastVal! + alpha * (value - _lastVal!);
    return _lastVal!;
  }

  void reset() {
    _lastVal = null;
  }
}

/// Complementary filter for sensor fusion.
///
/// Combines high-frequency gyroscope data with low-frequency
/// accelerometer/magnetometer data to produce a stable angle estimate.
class ComplementaryFilter {
  final double alpha;
  double _angle = 0.0;

  ComplementaryFilter(this.alpha);

  /// Update the filter with new sensor readings.
  ///
  /// [gyroRate] — Angular velocity from gyroscope (rad/s).
  /// [accelAngle] — Absolute angle from accelerometer/magnetometer (rad).
  /// [dt] — Time delta since last update (seconds).
  double filter(double gyroRate, double accelAngle, double dt) {
    _angle = alpha * (_angle + gyroRate * dt) + (1.0 - alpha) * accelAngle;
    return _angle;
  }

  void reset() {
    _angle = 0.0;
  }
}

/// Simple 1D Kalman filter for scalar measurements.
///
/// Provides optimal estimation for noisy scalar signals.
class KalmanFilter {
  /// Process noise covariance.
  double q;

  /// Measurement noise covariance.
  double r;

  /// Current state estimate.
  double x = 0.0;

  /// Estimation error covariance.
  double p = 1.0;

  /// Kalman gain.
  double k = 0.0;

  KalmanFilter({this.q = 0.1, this.r = 0.1});

  /// Update the filter with a new measurement.
  double update(double measurement) {
    // Prediction
    p = p + q;
    // Update
    k = p / (p + r);
    x = x + k * (measurement - x);
    p = (1 - k) * p;
    return x;
  }

  void reset() {
    x = 0.0;
    p = 1.0;
    k = 0.0;
  }
}
