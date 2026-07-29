import '../models/nav_graph.dart';
import '../models/pose.dart';

/// Navigation service that wraps the NavGraph pathfinding algorithms.
///
/// Provides route computation, nearest node lookup, and active route
/// management for the navigation feature.
class NavigationService {
  NavGraph? _activeGraph;

  /// Set the active navigation graph (from the loaded map package).
  void setActiveGraph(NavGraph graph) {
    _activeGraph = graph;
  }

  /// Get the currently active graph.
  NavGraph? get activeGraph => _activeGraph;

  /// Compute the shortest route between two nodes using A*.
  ///
  /// Returns null if no path exists or graph is not loaded.
  NavRoute? computeRoute(String fromId, String toId) {
    if (_activeGraph == null) return null;
    return _activeGraph!.findShortestPathAStar(fromId, toId);
  }

  /// Compute route using Dijkstra (alternative to A*).
  NavRoute? computeRouteDijkstra(String fromId, String toId) {
    if (_activeGraph == null) return null;
    return _activeGraph!.findShortestPath(fromId, toId);
  }

  /// Find the nearest navigation node to a world position.
  NavNode? findNearestNodeToPosition(Position3D position, {int? floor}) {
    if (_activeGraph == null) return null;
    return _activeGraph!.findNearestNode(position, floor: floor);
  }

  /// Search nodes by label text.
  List<NavNode> searchNodes(String query) {
    if (_activeGraph == null) return [];
    return _activeGraph!.searchNodes(query);
  }

  /// Get all available floors in the current map.
  List<int> get availableFloors {
    if (_activeGraph == null) return [];
    return _activeGraph!.floors;
  }

  /// Get all nodes on a specific floor.
  List<NavNode> getNodesOnFloor(int floor) {
    if (_activeGraph == null) return [];
    return _activeGraph!.getNodesOnFloor(floor);
  }
}
