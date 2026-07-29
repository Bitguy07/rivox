import 'nav_graph.dart';
import 'keyframe.dart';

/// Metadata for a complete map package that is downloaded
/// and stored on the mobile device for offline use.
class MapPackageMetadata {
  /// Unique identifier for this map package.
  final String id;

  /// Human-readable name (e.g., "ABESIT Campus").
  final String name;

  /// Version string for iterative updates.
  final String version;

  /// When this map package was created.
  final DateTime createdAt;

  /// Total number of recordings merged into this map.
  final int recordingCount;

  /// Floor information for multi-floor navigation.
  final List<FloorInfo> floors;

  /// Bounding box of the map in world coordinates.
  final MapBounds bounds;

  /// Path to the GLB model file relative to the map package root.
  final String glbPath;

  /// Path to the navigation graph JSON relative to the map package root.
  final String navGraphPath;

  /// Path to the keyframe database JSON relative to the map package root.
  final String keyframeDbPath;

  /// Path to the floor plan data JSON relative to the map package root.
  final String floorPlanPath;

  const MapPackageMetadata({
    required this.id,
    required this.name,
    required this.version,
    required this.createdAt,
    required this.recordingCount,
    required this.floors,
    required this.bounds,
    required this.glbPath,
    required this.navGraphPath,
    required this.keyframeDbPath,
    required this.floorPlanPath,
  });

  factory MapPackageMetadata.fromJson(Map<String, dynamic> json) =>
      MapPackageMetadata(
        id: json['id'] as String,
        name: json['name'] as String,
        version: json['version'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        recordingCount: (json['recording_count'] as num?)?.toInt() ?? 1,
        floors: (json['floors'] as List?)
                ?.map((e) => FloorInfo.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [FloorInfo.defaultFloor()],
        bounds: json['bounds'] != null
            ? MapBounds.fromJson(json['bounds'] as Map<String, dynamic>)
            : MapBounds.zero(),
        glbPath: json['glb_path'] as String? ?? 'map.glb',
        navGraphPath: json['nav_graph_path'] as String? ?? 'nav_graph.json',
        keyframeDbPath:
            json['keyframe_db_path'] as String? ?? 'keyframe_db.json',
        floorPlanPath:
            json['floor_plan_path'] as String? ?? 'floor_plan.json',
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'version': version,
    'created_at': createdAt.toIso8601String(),
    'recording_count': recordingCount,
    'floors': floors.map((f) => f.toJson()).toList(),
    'bounds': bounds.toJson(),
    'glb_path': glbPath,
    'nav_graph_path': navGraphPath,
    'keyframe_db_path': keyframeDbPath,
    'floor_plan_path': floorPlanPath,
  };
}

/// Information about a single floor in the building.
class FloorInfo {
  /// Floor number (0 = ground floor, negative for basement).
  final int number;

  /// Display label (e.g., "Ground Floor", "1st Floor", "Basement").
  final String label;

  /// Height range in world coordinates (minZ to maxZ).
  final double minHeight;
  final double maxHeight;

  const FloorInfo({
    required this.number,
    required this.label,
    required this.minHeight,
    required this.maxHeight,
  });

  factory FloorInfo.defaultFloor() => const FloorInfo(
    number: 0,
    label: 'Ground Floor',
    minHeight: -1.0,
    maxHeight: 4.0,
  );

  factory FloorInfo.fromJson(Map<String, dynamic> json) => FloorInfo(
    number: (json['number'] as num).toInt(),
    label: json['label'] as String,
    minHeight: (json['min_height'] as num).toDouble(),
    maxHeight: (json['max_height'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'number': number,
    'label': label,
    'min_height': minHeight,
    'max_height': maxHeight,
  };
}

/// Axis-aligned bounding box of the map.
class MapBounds {
  final double minX, minY, minZ;
  final double maxX, maxY, maxZ;

  const MapBounds({
    required this.minX,
    required this.minY,
    required this.minZ,
    required this.maxX,
    required this.maxY,
    required this.maxZ,
  });

  factory MapBounds.zero() => const MapBounds(
    minX: 0, minY: 0, minZ: 0,
    maxX: 0, maxY: 0, maxZ: 0,
  );

  factory MapBounds.fromJson(Map<String, dynamic> json) => MapBounds(
    minX: (json['min_x'] as num).toDouble(),
    minY: (json['min_y'] as num).toDouble(),
    minZ: (json['min_z'] as num).toDouble(),
    maxX: (json['max_x'] as num).toDouble(),
    maxY: (json['max_y'] as num).toDouble(),
    maxZ: (json['max_z'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'min_x': minX, 'min_y': minY, 'min_z': minZ,
    'max_x': maxX, 'max_y': maxY, 'max_z': maxZ,
  };

  double get width => maxX - minX;
  double get depth => maxY - minY;
  double get height => maxZ - minZ;

  double get centerX => (minX + maxX) / 2;
  double get centerY => (minY + maxY) / 2;
  double get centerZ => (minZ + maxZ) / 2;
}

/// 2D floor plan data for rendering the top-down 2D map view.
/// Contains wall outlines, room boundaries, and labels.
class FloorPlanData {
  final Map<int, FloorPlanLayer> layers; // keyed by floor number

  FloorPlanData(this.layers);

  factory FloorPlanData.fromJson(Map<String, dynamic> json) {
    final layers = <int, FloorPlanLayer>{};
    final layersJson = json['layers'] as Map<String, dynamic>? ?? {};
    for (final entry in layersJson.entries) {
      layers[int.parse(entry.key)] =
          FloorPlanLayer.fromJson(entry.value as Map<String, dynamic>);
    }
    return FloorPlanData(layers);
  }

  factory FloorPlanData.empty() => FloorPlanData({});

  Map<String, dynamic> toJson() => {
    'layers': layers.map((k, v) => MapEntry(k.toString(), v.toJson())),
  };
}

/// A single floor's 2D plan data.
class FloorPlanLayer {
  /// Wall segments as pairs of points [(x1,y1,x2,y2), ...].
  final List<WallSegment> walls;

  /// Room outlines as polygons.
  final List<RoomOutline> rooms;

  /// Width and height of this floor plan in world units.
  final double width;
  final double height;

  /// Offset of this floor plan from the world origin.
  final double offsetX;
  final double offsetY;

  const FloorPlanLayer({
    required this.walls,
    required this.rooms,
    required this.width,
    required this.height,
    this.offsetX = 0,
    this.offsetY = 0,
  });

  factory FloorPlanLayer.fromJson(Map<String, dynamic> json) => FloorPlanLayer(
    walls: (json['walls'] as List?)
            ?.map((e) => WallSegment.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    rooms: (json['rooms'] as List?)
            ?.map((e) => RoomOutline.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    width: (json['width'] as num?)?.toDouble() ?? 100,
    height: (json['height'] as num?)?.toDouble() ?? 100,
    offsetX: (json['offset_x'] as num?)?.toDouble() ?? 0,
    offsetY: (json['offset_y'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'walls': walls.map((w) => w.toJson()).toList(),
    'rooms': rooms.map((r) => r.toJson()).toList(),
    'width': width,
    'height': height,
    'offset_x': offsetX,
    'offset_y': offsetY,
  };
}

/// A wall segment defined by two endpoints.
class WallSegment {
  final double x1, y1, x2, y2;

  const WallSegment({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });

  factory WallSegment.fromJson(Map<String, dynamic> json) => WallSegment(
    x1: (json['x1'] as num).toDouble(),
    y1: (json['y1'] as num).toDouble(),
    x2: (json['x2'] as num).toDouble(),
    y2: (json['y2'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() =>
      {'x1': x1, 'y1': y1, 'x2': x2, 'y2': y2};
}

/// A room outline as a polygon with a label.
class RoomOutline {
  final String label;
  final List<List<double>> points; // [[x,y], [x,y], ...]

  const RoomOutline({required this.label, required this.points});

  factory RoomOutline.fromJson(Map<String, dynamic> json) => RoomOutline(
    label: json['label'] as String? ?? '',
    points: (json['points'] as List)
        .map((e) => (e as List).cast<num>().map((n) => n.toDouble()).toList())
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'label': label,
    'points': points,
  };
}

/// The complete loaded state of a map package on the device.
class LoadedMapPackage {
  final MapPackageMetadata metadata;
  final NavGraph navGraph;
  final KeyframeDatabase keyframeDb;
  final FloorPlanData floorPlan;

  /// Absolute path to the extracted map package directory on disk.
  final String packagePath;

  /// Absolute path to the GLB model file.
  final String glbFilePath;

  const LoadedMapPackage({
    required this.metadata,
    required this.navGraph,
    required this.keyframeDb,
    required this.floorPlan,
    required this.packagePath,
    required this.glbFilePath,
  });
}
