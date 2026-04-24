// lib/storage/file_manager.dart
import 'dart:convert';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class FileManager {

  // --- CORE SYSTEM: GET PUBLIC DOWNLOAD PATH ---
  static Future<String?> _getPublicDownloadPath() async {
    if (Platform.isAndroid) {
      // Request standard storage permissions
      var status = await Permission.storage.status;
      if (!status.isGranted) await Permission.storage.request();

      // Request Android 11+ "All Files Access" (Required for Downloads folder)
      var manageStatus = await Permission.manageExternalStorage.status;
      if (!manageStatus.isGranted) await Permission.manageExternalStorage.request();

      // Standard Android public Download path
      return '/storage/emulated/0/Download/EzzeScoreCard';
    }
    else if (Platform.isIOS) {
      // iOS requires using the Documents folder to be visible in the Files App
      final directory = await getApplicationDocumentsDirectory();
      return '${directory.path}/EzzeScoreCard';
    }
    return null;
  }

  // --- SAVE MATCH (With Serial Naming) ---
  static Future<void> saveMatchFile(String sportFolder, String dummyFileName, Map<String, dynamic> data) async {
    try {
      final basePath = await _getPublicDownloadPath();
      if (basePath == null) return;

      final String folderPath = '$basePath/$sportFolder';
      final sportDir = Directory(folderPath);

      if (!await sportDir.exists()) {
        await sportDir.create(recursive: true);
      }

      // Count existing JSON files to determine the serial number
      int matchCount = 0;
      List<FileSystemEntity> files = sportDir.listSync();
      for (var file in files) {
        if (file is File && file.path.endsWith('.json')) {
          matchCount++;
        }
      }

      // Generate the serial name (e.g., "Match 1", "Match 2")
      String serialName = "Match ${matchCount + 1}";
      final File file = File('$folderPath/$serialName.json');

      // Update the internal JSON data so the History screen shows the correct serial name
      data['match_name'] = serialName;

      String jsonString = jsonEncode(data);
      await file.writeAsString(jsonString);

      print('Saved successfully to Public Downloads: ${file.path}');
    } catch (e) {
      print('Error saving file: $e');
    }
  }

  // --- GET SAVED MATCHES ---
  static Future<List<Map<String, dynamic>>> getSavedMatches(String sportFolder) async {
    try {
      final basePath = await _getPublicDownloadPath();
      if (basePath == null) return [];

      final String folderPath = '$basePath/$sportFolder';
      final sportDir = Directory(folderPath);

      if (!await sportDir.exists()) {
        return [];
      }

      List<FileSystemEntity> files = sportDir.listSync();
      List<Map<String, dynamic>> savedMatches = [];

      for (var file in files) {
        if (file is File && file.path.endsWith('.json')) {
          String content = await file.readAsString();
          Map<String, dynamic> data = jsonDecode(content);

          // Inject file path for the delete function
          data['file_path'] = file.path;

          savedMatches.add(data);
        }
      }

      // Sort matches by File Last Modified Date so the newest matches appear at the top
      savedMatches.sort((a, b) {
        File fileA = File(a['file_path']);
        File fileB = File(b['file_path']);
        return fileB.lastModifiedSync().compareTo(fileA.lastModifiedSync());
      });

      return savedMatches;
    } catch (e) {
      print('Error reading files: $e');
      return [];
    }
  }

  // --- DELETE MATCH ---
  static Future<bool> deleteMatchFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }
}