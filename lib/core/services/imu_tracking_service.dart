import 'dart:async';
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';
import '../utils/step_detector.dart';
import '../utils/math_filters.dart';
import '../models/pose.dart';

class ImuTrackingService {
  StreamSubscription? _accelSub;
  StreamSubscription? _gyroSub;
  StreamSubscription? _magSub;
  
  final StepDetector _stepDetector = StepDetector();
  final ComplementaryFilter _headingFilter = ComplementaryFilter(0.98);
  final LowPassFilter _xFilter = LowPassFilter(0.2);
  final LowPassFilter _yFilter = LowPassFilter(0.2);
  
  double _currentHeading = 0.0;
  Position3D _currentPosition = Position3D(x: 0, y: 0, z: 0);
  
  double strideLength = 0.7; // ~0.7m default
  DateTime? _lastUpdate;
  
  Function(Position3D, double)? onPositionUpdated;

  void startTracking(Position3D initialPosition, double initialHeading) {
    _currentPosition = initialPosition;
    _currentHeading = initialHeading;
    _lastUpdate = DateTime.now();
    
    _accelSub = accelerometerEventStream().listen((event) {
      final magnitude = math.sqrt(event.x*event.x + event.y*event.y + event.z*event.z);
      if (_stepDetector.processMagnitude(magnitude)) {
        _handleStep();
      }
    });
    
    _gyroSub = gyroscopeEventStream().listen((event) {
      final now = DateTime.now();
      if (_lastUpdate != null) {
        final dt = now.difference(_lastUpdate!).inMilliseconds / 1000.0;
        // Simplified heading update (z-axis rotation)
        _currentHeading += event.z * dt;
      }
      _lastUpdate = now;
    });
    
    _magSub = magnetometerEventStream().listen((event) {
      // Basic magnetometer heading
      final magHeading = math.atan2(event.y, event.x);
      
      // Fuse with complementary filter
      _currentHeading = _headingFilter.filter(0.0, magHeading, 0.1); 
    });
  }

  void _handleStep() {
    final dx = strideLength * math.cos(_currentHeading);
    final dy = strideLength * math.sin(_currentHeading);
    
    final smoothedX = _xFilter.filter(_currentPosition.x + dx);
    final smoothedY = _yFilter.filter(_currentPosition.y + dy);
    
    _currentPosition = Position3D(x: smoothedX, y: smoothedY, z: _currentPosition.z);
    
    if (onPositionUpdated != null) {
      onPositionUpdated!(_currentPosition, _currentHeading);
    }
  }

  void stopTracking() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _magSub?.cancel();
  }
}
