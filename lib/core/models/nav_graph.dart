import 'dart:collection';
import 'dart:math';

import 'pose.dart';

/// A node in the navigation graph representing a point of interest
/// or a navigable waypoint in the campus map.
class NavNode {
  final String id;
  final String label;
  final Position3D position;
  final NavNodeType type;
  final Map<String, dynamic> metadata;

  const NavNode({
    required this.id,
    required this.label,
    required this.position,
    this.type = NavNodeType.waypoint,
    this.metadata = const {},
  });

  factory NavNode.fromJson(Map<String, dynamic> json) => NavNode(
    id: json['id'] as String,
    label: json['label'] as String,
    position: Position3D.fromJson(json['position'] as Map<String, dynamic>),
    type: NavNodeType.fromString(json['type'] as String? ?? 'waypoint'),
    metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'position': position.toJson(),
    'type': type.name,
    'metadata': metadata,
  };

  @override
  String toString() => 'NavNode($id, "$label", ${type.name})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavNode && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Types of navigation nodes.
enum NavNodeType {
  room,
  corridor,
  intersection,
  stairs,
  elevator,
  entrance,
  exit,
  waypoint,
  restroom,
  cafeteria,
  lab,
  office,
  library;

  static NavNodeType fromString(String value) {
    return NavNodeType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NavNodeType.waypoint,
    );
  }
}

/// An edge in the navigation graph connecting two nodes.
class NavEdge {
  final String fromId;
  final String toId;
  final double distance;
  final NavEdgeType type;

  const NavEdge({
    required this.fromId,
    required this.toId,
    required this.distance,
    this.type = NavEdgeType.walk,
  });

  factory NavEdge.fromJson(Map<String, dynamic> json) => NavEdge(
    fromId: json['from'] as String,
    toId: json['to'] as String,
    distance: (json['distance'] as num).toDouble(),
    type: NavEdgeType.fromString(json['type'] as String? ?? 'walk'),
  );

  Map<String, dynamic> toJson() => {
    'from': fromId,
    'to': toId,
    'distance': distance,
    'type': type.name,
  };

  @override
  String toString() => 'NavEdge($fromId → $toId, ${distance.toStringAsFixed(1)}m, ${type.name})';
}

/// Types of navigation edges.
enum NavEdgeType {
  walk,
  stairs,
  elevator,
  ramp;

  static NavEdgeType fromString(String value) {
    return NavEdgeType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NavEdgeType.walk,
    );
  }

  /// Penalty multiplier for pathfinding. Stairs and elevators are
  /// penalized to prefer walking paths when possible.
  double get penalty {
    switch (this) {
      case NavEdgeType.walk:
        return 1.0;
      case NavEdgeType.stairs:
        return 1.5;
      case NavEdgeType.elevator:
        return 2.0; // Waiting time
      case NavEdgeType.ramp:
        return 1.2;
    }
  }
}

/// The complete navigation graph for a campus map.
///
/// Supports Dijkstra and A* pathfinding algorithms.
class NavGraph {
  final Map<String, NavNode> _nodes;
  final List<NavEdge> _edges;

  /// Adjacency list: nodeId → list of (neighborId, edge).
  final Map<String, List<AdjEntry>> _adjacency;

  NavGraph._({
    required Map<String, NavNode> nodes,
    required List<NavEdge> edges,
    required Map<String, List<AdjEntry>> adjacency,
  })  : _nodes = nodes,
        _edges = edges,
        _adjacency = adjacency;

  factory NavGraph.fromNodesAndEdges(List<NavNode> nodes, List<NavEdge> edges) {
    final nodeMap = {for (final n in nodes) n.id: n};
    final adjacency = <String, List<AdjEntry>>{};

    for (final node in nodes) {
      adjacency[node.id] = [];
    }

    for (final edge in edges) {
      // Bidirectional edges
      adjacency[edge.fromId]?.add(AdjEntry(edge.toId, edge));
      adjacency[edge.toId]?.add(AdjEntry(edge.fromId, NavEdge(
        fromId: edge.toId,
        toId: edge.fromId,
        distance: edge.distance,
        type: edge.type,
      )));
    }

    return NavGraph._(nodes: nodeMap, edges: edges, adjacency: adjacency);
  }

  factory NavGraph.fromJson(Map<String, dynamic> json) {
    final nodes = (json['nodes'] as List)
        .map((e) => NavNode.fromJson(e as Map<String, dynamic>))
        .toList();
    final edges = (json['edges'] as List)
        .map((e) => NavEdge.fromJson(e as Map<String, dynamic>))
        .toList();
    return NavGraph.fromNodesAndEdges(nodes, edges);
  }

  Map<String, dynamic> toJson() => {
    'nodes': _nodes.values.map((n) => n.toJson()).toList(),
    'edges': _edges.map((e) => e.toJson()).toList(),
  };

  /// Get all nodes.
  Iterable<NavNode> get nodes => _nodes.values;

  /// Get all edges.
  List<NavEdge> get edges => _edges;

  /// Get a node by ID.
  NavNode? getNode(String id) => _nodes[id];

  /// Get the number of nodes.
  int get nodeCount => _nodes.length;

  /// Get neighbors of a node.
  List<AdjEntry> getNeighbors(String nodeId) =>
      _adjacency[nodeId] ?? const [];

  /// Get all nodes on a specific floor.
  List<NavNode> getNodesOnFloor(int floor) =>
      _nodes.values.where((n) => n.position.floor == floor).toList();

  /// Get all distinct floor numbers.
  List<int> get floors {
    final floorSet = _nodes.values.map((n) => n.position.floor).toSet();
    return floorSet.toList()..sort();
  }

  /// Find the nearest node to a given position.
  NavNode? findNearestNode(Position3D position, {int? floor}) {
    NavNode? nearest;
    double minDist = double.infinity;

    for (final node in _nodes.values) {
      if (floor != null && node.position.floor != floor) continue;
      final dist = position.distanceTo(node.position);
      if (dist < minDist) {
        minDist = dist;
        nearest = node;
      }
    }

    return nearest;
  }

  /// Search nodes by label (fuzzy matching).
  List<NavNode> searchNodes(String query) {
    if (query.isEmpty) return [];
    final lowerQuery = query.toLowerCase();
    return _nodes.values
        .where((n) => n.label.toLowerCase().contains(lowerQuery))
        .toList()
      ..sort((a, b) {
        // Prefer exact prefix matches
        final aStarts = a.label.toLowerCase().startsWith(lowerQuery) ? 0 : 1;
        final bStarts = b.label.toLowerCase().startsWith(lowerQuery) ? 0 : 1;
        if (aStarts != bStarts) return aStarts.compareTo(bStarts);
        return a.label.compareTo(b.label);
      });
  }

  /// Dijkstra's shortest path algorithm.
  ///
  /// Returns a [NavRoute] containing the ordered list of nodes and
  /// total distance, or null if no path exists.
  NavRoute? findShortestPath(String fromId, String toId) {
    if (!_nodes.containsKey(fromId) || !_nodes.containsKey(toId)) {
      return null;
    }
    if (fromId == toId) {
      return NavRoute(
        nodes: [_nodes[fromId]!],
        edges: [],
        totalDistance: 0,
      );
    }

    final dist = <String, double>{};
    final prev = <String, String>{};
    final prevEdge = <String, NavEdge>{};
    final visited = <String>{};

    // Priority queue: (distance, nodeId)
    final pq = SplayTreeSet<_PQEntry>((a, b) {
      final cmp = a.distance.compareTo(b.distance);
      if (cmp != 0) return cmp;
      return a.nodeId.compareTo(b.nodeId);
    });

    dist[fromId] = 0;
    pq.add(_PQEntry(0, fromId));

    while (pq.isNotEmpty) {
      final current = pq.first;
      pq.remove(current);

      if (visited.contains(current.nodeId)) continue;
      visited.add(current.nodeId);

      if (current.nodeId == toId) break;

      for (final adj in getNeighbors(current.nodeId)) {
        if (visited.contains(adj.neighborId)) continue;

        final edgeWeight = adj.edge.distance * adj.edge.type.penalty;
        final newDist = (dist[current.nodeId] ?? double.infinity) + edgeWeight;

        if (newDist < (dist[adj.neighborId] ?? double.infinity)) {
          dist[adj.neighborId] = newDist;
          prev[adj.neighborId] = current.nodeId;
          prevEdge[adj.neighborId] = adj.edge;
          pq.add(_PQEntry(newDist, adj.neighborId));
        }
      }
    }

    // Reconstruct path
    if (!prev.containsKey(toId) && fromId != toId) return null;

    final pathNodes = <NavNode>[];
    final pathEdges = <NavEdge>[];
    String? current = toId;

    while (current != null) {
      pathNodes.add(_nodes[current]!);
      if (prevEdge.containsKey(current)) {
        pathEdges.add(prevEdge[current]!);
      }
      current = prev[current];
    }

    pathNodes.reversed;
    pathEdges.reversed;

    return NavRoute(
      nodes: pathNodes.reversed.toList(),
      edges: pathEdges.reversed.toList(),
      totalDistance: dist[toId] ?? 0,
    );
  }

  /// A* shortest path algorithm with Euclidean heuristic.
  ///
  /// Generally faster than Dijkstra for spatial graphs.
  NavRoute? findShortestPathAStar(String fromId, String toId) {
    if (!_nodes.containsKey(fromId) || !_nodes.containsKey(toId)) {
      return null;
    }
    if (fromId == toId) {
      return NavRoute(
        nodes: [_nodes[fromId]!],
        edges: [],
        totalDistance: 0,
      );
    }

    final targetPos = _nodes[toId]!.position;

    final gScore = <String, double>{};
    final fScore = <String, double>{};
    final prev = <String, String>{};
    final prevEdge = <String, NavEdge>{};
    final visited = <String>{};

    final pq = SplayTreeSet<_PQEntry>((a, b) {
      final cmp = a.distance.compareTo(b.distance);
      if (cmp != 0) return cmp;
      return a.nodeId.compareTo(b.nodeId);
    });

    gScore[fromId] = 0;
    fScore[fromId] = _nodes[fromId]!.position.distanceTo(targetPos);
    pq.add(_PQEntry(fScore[fromId]!, fromId));

    while (pq.isNotEmpty) {
      final current = pq.first;
      pq.remove(current);

      if (current.nodeId == toId) break;
      if (visited.contains(current.nodeId)) continue;
      visited.add(current.nodeId);

      for (final adj in getNeighbors(current.nodeId)) {
        if (visited.contains(adj.neighborId)) continue;

        final edgeWeight = adj.edge.distance * adj.edge.type.penalty;
        final tentativeG = (gScore[current.nodeId] ?? double.infinity) + edgeWeight;

        if (tentativeG < (gScore[adj.neighborId] ?? double.infinity)) {
          prev[adj.neighborId] = current.nodeId;
          prevEdge[adj.neighborId] = adj.edge;
          gScore[adj.neighborId] = tentativeG;

          final h = _nodes[adj.neighborId]!.position.distanceTo(targetPos);
          fScore[adj.neighborId] = tentativeG + h;
          pq.add(_PQEntry(fScore[adj.neighborId]!, adj.neighborId));
        }
      }
    }

    // Reconstruct path
    if (!prev.containsKey(toId)) return null;

    final pathNodes = <NavNode>[];
    final pathEdges = <NavEdge>[];
    String? current = toId;

    while (current != null) {
      pathNodes.add(_nodes[current]!);
      if (prevEdge.containsKey(current)) {
        pathEdges.add(prevEdge[current]!);
      }
      current = prev[current];
    }

    return NavRoute(
      nodes: pathNodes.reversed.toList(),
      edges: pathEdges.reversed.toList(),
      totalDistance: gScore[toId] ?? 0,
    );
  }
}

/// Internal adjacency entry.
class AdjEntry {
  final String neighborId;
  final NavEdge edge;

  const AdjEntry(this.neighborId, this.edge);
}

/// Internal priority queue entry.
class _PQEntry {
  final double distance;
  final String nodeId;

  const _PQEntry(this.distance, this.nodeId);
}

/// A computed navigation route.
class NavRoute {
  final List<NavNode> nodes;
  final List<NavEdge> edges;
  final double totalDistance;

  const NavRoute({
    required this.nodes,
    required this.edges,
    required this.totalDistance,
  });

  /// Estimated walking time in seconds (assuming 1.2 m/s average walking speed).
  double get estimatedTimeSeconds => totalDistance / 1.2;

  /// Estimated walking time formatted as "X min Y sec".
  String get estimatedTimeFormatted {
    final seconds = estimatedTimeSeconds.round();
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (remainingSeconds == 0) return '$minutes min';
    return '$minutes min ${remainingSeconds}s';
  }

  /// Get waypoints as a list of Position3D for rendering.
  List<Position3D> get waypoints => nodes.map((n) => n.position).toList();

  /// Check if route involves floor changes.
  bool get hasFloorChanges {
    if (nodes.length < 2) return false;
    final firstFloor = nodes.first.position.floor;
    return nodes.any((n) => n.position.floor != firstFloor);
  }

  /// Get turn-by-turn directions.
  List<NavInstruction> getInstructions() {
    if (nodes.length < 2) return [];

    final instructions = <NavInstruction>[];
    instructions.add(NavInstruction(
      text: 'Start at ${nodes.first.label}',
      type: NavInstructionType.start,
      position: nodes.first.position,
    ));

    for (int i = 0; i < edges.length; i++) {
      final edge = edges[i];
      final toNode = nodes[i + 1];

      if (edge.type == NavEdgeType.stairs) {
        final goingUp = toNode.position.floor > nodes[i].position.floor;
        instructions.add(NavInstruction(
          text: 'Take stairs ${goingUp ? "up" : "down"} to floor ${toNode.position.floor}',
          type: NavInstructionType.stairs,
          position: toNode.position,
          distance: edge.distance,
        ));
      } else if (edge.type == NavEdgeType.elevator) {
        instructions.add(NavInstruction(
          text: 'Take elevator to floor ${toNode.position.floor}',
          type: NavInstructionType.elevator,
          position: toNode.position,
          distance: edge.distance,
        ));
      } else {
        // Compute turn direction if we have a previous segment
        String direction = 'Continue';
        if (i > 0) {
          final prevPos = nodes[i - 1].position;
          final currPos = nodes[i].position;
          final nextPos = toNode.position;
          direction = _computeTurnDirection(prevPos, currPos, nextPos);
        }

        if (toNode.type == NavNodeType.room ||
            toNode.type == NavNodeType.lab ||
            toNode.type == NavNodeType.office ||
            toNode.type == NavNodeType.library ||
            toNode.type == NavNodeType.cafeteria ||
            toNode.type == NavNodeType.restroom) {
          instructions.add(NavInstruction(
            text: '$direction to ${toNode.label}',
            type: NavInstructionType.arrive,
            position: toNode.position,
            distance: edge.distance,
          ));
        } else {
          instructions.add(NavInstruction(
            text: '$direction for ${edge.distance.toStringAsFixed(0)}m',
            type: NavInstructionType.walk,
            position: toNode.position,
            distance: edge.distance,
          ));
        }
      }
    }

    instructions.add(NavInstruction(
      text: 'Arrived at ${nodes.last.label}',
      type: NavInstructionType.destination,
      position: nodes.last.position,
    ));

    return instructions;
  }

  String _computeTurnDirection(Position3D prev, Position3D curr, Position3D next) {
    final dx1 = curr.x - prev.x;
    final dy1 = curr.y - prev.y;
    final dx2 = next.x - curr.x;
    final dy2 = next.y - curr.y;

    // Cross product to determine turn direction
    final cross = dx1 * dy2 - dy1 * dx2;
    // Dot product to check if roughly straight
    final dot = dx1 * dx2 + dy1 * dy2;
    final mag1 = sqrt(dx1 * dx1 + dy1 * dy1);
    final mag2 = sqrt(dx2 * dx2 + dy2 * dy2);

    if (mag1 < 0.001 || mag2 < 0.001) return 'Continue';

    final cosAngle = dot / (mag1 * mag2);
    if (cosAngle > 0.9) return 'Continue straight';
    if (cross > 0) return 'Turn left';
    if (cross < 0) return 'Turn right';
    return 'Continue';
  }
}

/// A single navigation instruction for turn-by-turn directions.
class NavInstruction {
  final String text;
  final NavInstructionType type;
  final Position3D position;
  final double? distance;

  const NavInstruction({
    required this.text,
    required this.type,
    required this.position,
    this.distance,
  });
}

/// Types of navigation instructions.
enum NavInstructionType {
  start,
  walk,
  turnLeft,
  turnRight,
  stairs,
  elevator,
  arrive,
  destination,
}
