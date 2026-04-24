import 'dart:convert';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class FileManager {
  static Future<String?> _getPublicDownloadPath() async {
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (!status.isGranted) await Permission.storage.request();
      var manageStatus = await Permission.manageExternalStorage.status;
      if (!manageStatus.isGranted) await Permission.manageExternalStorage.request();
      return '/storage/emulated/0/Download/EzzeScoreCard';
    }
    return null; // Assuming Android for this public path logic
  }

  // --- UPDATED SAVE METHOD ---
  static Future<void> saveMatchFile(String sportFolder, Map<String, dynamic> data) async {
    try {
      final basePath = await _getPublicDownloadPath();
      if (basePath == null) return;

      final String folderPath = '$basePath/$sportFolder';
      final sportDir = Directory(folderPath);
      if (!await sportDir.exists()) await sportDir.create(recursive: true);

      File file;

      // If this is a paused match, OVERWRITE the exact same file!
      if (data.containsKey('file_path') && data['file_path'] != null) {
        file = File(data['file_path']);
      } else {
        // If it's a new match, create a new serial name
        int matchCount = 0;
        List<FileSystemEntity> files = sportDir.listSync();
        for (var f in files) {
          if (f is File && f.path.endsWith('.json')) matchCount++;
        }
        String serialName = "Match ${matchCount + 1}";
        file = File('$folderPath/$serialName.json');

        data['match_name'] = serialName;
        data['file_path'] = file.path; // Save path internally for future overwrites
      }

      await file.writeAsString(jsonEncode(data));
      print('Saved successfully to: ${file.path}');
    } catch (e) {
      print('Error saving file: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getSavedMatches(String sportFolder) async {
    try {
      final basePath = await _getPublicDownloadPath();
      if (basePath == null) return [];

      final String folderPath = '$basePath/$sportFolder';
      final sportDir = Directory(folderPath);
      if (!await sportDir.exists()) return [];

      List<FileSystemEntity> files = sportDir.listSync();
      List<Map<String, dynamic>> savedMatches = [];

      for (var file in files) {
        if (file is File && file.path.endsWith('.json')) {
          String content = await file.readAsString();
          Map<String, dynamic> data = jsonDecode(content);
          data['file_path'] = file.path;
          savedMatches.add(data);
        }
      }

      savedMatches.sort((a, b) => File(b['file_path']).lastModifiedSync().compareTo(File(a['file_path']).lastModifiedSync()));
      return savedMatches;
    } catch (e) {
      return [];
    }
  }

  static Future<bool> deleteMatchFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}