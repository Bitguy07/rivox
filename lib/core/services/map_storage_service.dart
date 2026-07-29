import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import '../models/map_package.dart';
import '../models/nav_graph.dart';
import '../models/keyframe.dart';

/// Service for managing map packages on local device storage.
///
/// Handles importing ZIP map packages, loading/parsing them into
/// the in-memory model, listing available packages, and deletion.
class MapStorageService {
  /// Get the app's documents directory path.
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// Get the maps root directory.
  Future<Directory> get _mapsDir async {
    final path = await _localPath;
    final dir = Directory('$path/maps');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Import a ZIP map package from the given file path.
  ///
  /// Extracts the contents to a subdirectory under the maps folder.
  /// The directory name is derived from the package metadata ID.
  Future<String> importMapPackage(String zipPath) async {
    final bytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final mapsDir = await _mapsDir;

    // Extract to a temporary location first to read metadata
    final tempDir = Directory('${mapsDir.path}/_temp_import');
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
    await tempDir.create(recursive: true);

    for (final file in archive) {
      final filename = file.name;
      if (file.isFile) {
        final data = file.content as List<int>;
        final outFile = File('${tempDir.path}/$filename');
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(data);
      }
    }

    // Read metadata to get the package ID
    final metadataFile = File('${tempDir.path}/metadata.json');
    String packageId = 'unknown_${DateTime.now().millisecondsSinceEpoch}';
    if (await metadataFile.exists()) {
      final content = await metadataFile.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      packageId = json['id'] as String? ?? packageId;
    }

    // Move to final location
    final finalDir = Directory('${mapsDir.path}/$packageId');
    if (await finalDir.exists()) {
      await finalDir.delete(recursive: true);
    }
    await tempDir.rename(finalDir.path);

    return packageId;
  }

  /// List all available map package IDs.
  Future<List<String>> listAvailablePackages() async {
    final mapsDir = await _mapsDir;
    final List<String> packages = [];

    await for (final entity in mapsDir.list(recursive: false)) {
      if (entity is Directory) {
        final name = entity.path.split('/').last;
        if (!name.startsWith('_')) {
          // Skip temp directories
          packages.add(name);
        }
      }
    }
    return packages;
  }

  /// Load a map package by ID into memory.
  ///
  /// Parses metadata.json, nav_graph.json, keyframe_db.json, and floor_plan.json.
  /// Returns null if the package doesn't exist or is corrupt.
  Future<LoadedMapPackage?> loadMapPackage(String id) async {
    final mapsDir = await _mapsDir;
    final dir = Directory('${mapsDir.path}/$id');
    if (!await dir.exists()) return null;

    try {
      // Parse metadata
      final metadataFile = File('${dir.path}/metadata.json');
      if (!await metadataFile.exists()) return null;
      final metadataJson =
          jsonDecode(await metadataFile.readAsString()) as Map<String, dynamic>;
      final metadata = MapPackageMetadata.fromJson(metadataJson);

      // Parse navigation graph
      final navGraphFile = File('${dir.path}/${metadata.navGraphPath}');
      NavGraph navGraph;
      if (await navGraphFile.exists()) {
        final navGraphJson =
            jsonDecode(await navGraphFile.readAsString()) as Map<String, dynamic>;
        navGraph = NavGraph.fromJson(navGraphJson);
      } else {
        navGraph = NavGraph.fromNodesAndEdges([], []);
      }

      // Parse keyframe database
      final keyframeFile = File('${dir.path}/${metadata.keyframeDbPath}');
      KeyframeDatabase keyframeDb;
      if (await keyframeFile.exists()) {
        final kfJson =
            jsonDecode(await keyframeFile.readAsString()) as Map<String, dynamic>;
        keyframeDb = KeyframeDatabase.fromJson(kfJson);
      } else {
        keyframeDb = KeyframeDatabase([]);
      }

      // Parse floor plan
      final floorPlanFile = File('${dir.path}/${metadata.floorPlanPath}');
      FloorPlanData floorPlan;
      if (await floorPlanFile.exists()) {
        final fpJson =
            jsonDecode(await floorPlanFile.readAsString()) as Map<String, dynamic>;
        floorPlan = FloorPlanData.fromJson(fpJson);
      } else {
        floorPlan = FloorPlanData.empty();
      }

      // GLB file path
      final glbFilePath = '${dir.path}/${metadata.glbPath}';

      return LoadedMapPackage(
        metadata: metadata,
        navGraph: navGraph,
        keyframeDb: keyframeDb,
        floorPlan: floorPlan,
        packagePath: dir.path,
        glbFilePath: glbFilePath,
      );
    } catch (e) {
      // Log or handle parse errors
      return null;
    }
  }

  /// Get metadata for a map package without fully loading it.
  Future<MapPackageMetadata?> getPackageMetadata(String id) async {
    final mapsDir = await _mapsDir;
    final metadataFile = File('${mapsDir.path}/$id/metadata.json');
    if (!await metadataFile.exists()) return null;

    try {
      final json =
          jsonDecode(await metadataFile.readAsString()) as Map<String, dynamic>;
      return MapPackageMetadata.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Delete a map package by ID.
  Future<void> deleteMapPackage(String id) async {
    final mapsDir = await _mapsDir;
    final dir = Directory('${mapsDir.path}/$id');
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
