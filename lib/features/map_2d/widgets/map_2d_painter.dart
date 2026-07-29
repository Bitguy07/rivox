import 'package:flutter/material.dart';
import 'package:rivox/app/theme/app_colors.dart';
import 'package:rivox/core/models/pose.dart';
import 'package:rivox/core/models/nav_graph.dart';
import 'package:rivox/core/models/map_package.dart';

/// Custom painter for the 2D top-down map view.
///
/// Draws floor plan walls, rooms, navigation nodes, user avatar,
/// and the active navigation route on a Canvas.
class Map2DPainter extends CustomPainter {
  final FloorPlanLayer? floorLayer;
  final List<NavNode>? nodesOnFloor;
  final Position3D? userPosition;
  final NavRoute? activeRoute;
  final double scale;
  final Offset offset;

  Map2DPainter({
    this.floorLayer,
    this.nodesOnFloor,
    this.userPosition,
    this.activeRoute,
    this.scale = 3.0,
    this.offset = Offset.zero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background grid
    _drawGrid(canvas, size);

    // Draw walls
    if (floorLayer != null) {
      _drawWalls(canvas, floorLayer!);
      _drawRooms(canvas, floorLayer!);
    }

    // Draw navigation nodes
    if (nodesOnFloor != null) {
      _drawNodes(canvas);
    }

    // Draw route
    if (activeRoute != null && activeRoute!.nodes.length >= 2) {
      _drawRoute(canvas);
    }

    // Draw user avatar
    if (userPosition != null) {
      _drawAvatar(canvas);
    }
  }

  Offset _worldToCanvas(double x, double y) {
    return Offset(
      (x + offset.dx) * scale,
      (y + offset.dy) * scale,
    );
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.mapGrid
      ..strokeWidth = 0.5;

    const gridSpacing = 30.0;
    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawWalls(Canvas canvas, FloorPlanLayer layer) {
    final wallPaint = Paint()
      ..color = AppColors.mapWall
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final wall in layer.walls) {
      final start = _worldToCanvas(wall.x1, wall.y1);
      final end = _worldToCanvas(wall.x2, wall.y2);
      canvas.drawLine(start, end, wallPaint);
    }
  }

  void _drawRooms(Canvas canvas, FloorPlanLayer layer) {
    final roomFillPaint = Paint()
      ..color = AppColors.mapRoom
      ..style = PaintingStyle.fill;

    final roomStrokePaint = Paint()
      ..color = AppColors.mapWall.withValues(alpha: 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (final room in layer.rooms) {
      if (room.points.length < 3) continue;

      final path = Path();
      final first = _worldToCanvas(room.points[0][0], room.points[0][1]);
      path.moveTo(first.dx, first.dy);

      for (int i = 1; i < room.points.length; i++) {
        final pt = _worldToCanvas(room.points[i][0], room.points[i][1]);
        path.lineTo(pt.dx, pt.dy);
      }
      path.close();

      canvas.drawPath(path, roomFillPaint);
      canvas.drawPath(path, roomStrokePaint);

      // Draw room label
      if (room.label.isNotEmpty) {
        final center = _worldToCanvas(
          room.points.map((p) => p[0]).reduce((a, b) => a + b) / room.points.length,
          room.points.map((p) => p[1]).reduce((a, b) => a + b) / room.points.length,
        );
        final textPainter = TextPainter(
          text: TextSpan(
            text: room.label,
            style: const TextStyle(color: AppColors.mapRoomLabel, fontSize: 10),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, center - Offset(textPainter.width / 2, textPainter.height / 2));
      }
    }
  }

  void _drawNodes(Canvas canvas) {
    for (final node in nodesOnFloor!) {
      final pos = _worldToCanvas(node.position.x, node.position.y);
      final color = _nodeColor(node.type);

      canvas.drawCircle(pos, 5, Paint()..color = color);

      // Draw label for important nodes
      if (node.type != NavNodeType.waypoint && node.type != NavNodeType.corridor) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: node.label,
            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w500),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, pos + const Offset(8, -6));
      }
    }
  }

  Color _nodeColor(NavNodeType type) {
    switch (type) {
      case NavNodeType.room:
        return AppColors.nodeRoom;
      case NavNodeType.stairs:
        return AppColors.nodeStairs;
      case NavNodeType.elevator:
        return AppColors.nodeElevator;
      case NavNodeType.entrance:
      case NavNodeType.exit:
        return AppColors.nodeEntrance;
      case NavNodeType.restroom:
        return AppColors.nodeRestroom;
      case NavNodeType.cafeteria:
        return AppColors.nodeCafeteria;
      default:
        return AppColors.nodeCorridor;
    }
  }

  void _drawRoute(Canvas canvas) {
    final routePaint = Paint()
      ..color = AppColors.routePath
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final glowPaint = Paint()
      ..color = AppColors.routePathGlow
      ..strokeWidth = 12.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final path = Path();
    final nodes = activeRoute!.nodes;
    final first = _worldToCanvas(nodes[0].position.x, nodes[0].position.y);
    path.moveTo(first.dx, first.dy);

    for (int i = 1; i < nodes.length; i++) {
      final pt = _worldToCanvas(nodes[i].position.x, nodes[i].position.y);
      path.lineTo(pt.dx, pt.dy);
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, routePaint);

    // Destination marker
    final dest = _worldToCanvas(nodes.last.position.x, nodes.last.position.y);
    canvas.drawCircle(dest, 8, Paint()..color = AppColors.destinationMarker);
    canvas.drawCircle(dest, 12, Paint()
      ..color = AppColors.destinationMarker.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
  }

  void _drawAvatar(Canvas canvas) {
    final pos = _worldToCanvas(userPosition!.x, userPosition!.y);

    // Glow ring
    canvas.drawCircle(pos, 18, Paint()
      ..color = AppColors.avatarGlow
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    // Outer ring
    canvas.drawCircle(pos, 12, Paint()
      ..color = AppColors.avatarColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);

    // Inner dot
    canvas.drawCircle(pos, 8, Paint()..color = AppColors.avatarColor);

    // Center dot
    canvas.drawCircle(pos, 3, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant Map2DPainter oldDelegate) {
    return oldDelegate.userPosition != userPosition ||
        oldDelegate.activeRoute != activeRoute ||
        oldDelegate.floorLayer != floorLayer ||
        oldDelegate.scale != scale;
  }
}
