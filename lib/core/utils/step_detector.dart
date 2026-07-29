/// Step detection algorithm for Pedestrian Dead Reckoning (PDR).
///
/// Monitors accelerometer magnitude and detects peaks that correspond
/// to footsteps, using a threshold and cooldown period.
class StepDetector {
  /// Magnitude threshold to trigger a step event.
  final double threshold;

  /// Minimum time between consecutive steps.
  final Duration cooldown;

  DateTime? _lastStepTime;

  StepDetector({
    this.threshold = 12.0,
    this.cooldown = const Duration(milliseconds: 300),
  });

  /// Process a new accelerometer magnitude sample.
  ///
  /// Returns true if a step was detected.
  bool processMagnitude(double magnitude) {
    if (magnitude > threshold) {
      final now = DateTime.now();
      if (_lastStepTime == null || now.difference(_lastStepTime!) > cooldown) {
        _lastStepTime = now;
        return true;
      }
    }
    return false;
  }

  /// Reset the detector state.
  void reset() {
    _lastStepTime = null;
  }
}
