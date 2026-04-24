// lib/storage/file_manager.dart
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
    return null;
  }

  // --- UPDATED SAVE METHOD (Physical Folder Routing) ---
  static Future<void> saveMatchFile(String sportFolder, Map<String, dynamic> data) async {
    try {
      final basePath = await _getPublicDownloadPath();
      if (basePath == null) return;

      // 1. Determine which sub-folder this belongs in
      bool isComplete = data['isComplete'] == true;
      String subFolder = isComplete ? 'Completed' : 'Paused';
      final String targetFolderPath = '$basePath/$sportFolder/$subFolder';

      final targetDir = Directory(targetFolderPath);
      if (!await targetDir.exists()) await targetDir.create(recursive: true);

      File? oldFile;
      if (data.containsKey('file_path') && data['file_path'] != null) {
        oldFile = File(data['file_path']);
      }

      File newFile;

      // 2. If a file exists AND it's already in the correct folder, just overwrite it
      if (oldFile != null && oldFile.path.contains(subFolder)) {
        newFile = oldFile;
      }
      else {
        // 3. Otherwise, it's either brand new, OR it is moving from Paused to Completed
        int matchCount = 0;
        List<FileSystemEntity> files = targetDir.listSync();
        for (var f in files) {
          if (f is File && f.path.endsWith('.json')) matchCount++;
        }

        // If it already had a name, keep it. If not, generate a new serial number.
        String fileName = data['match_name'] ?? "Match ${matchCount + 1}";
        if (!data.containsKey('match_name')) {
          data['match_name'] = fileName;
        }

        newFile = File('$targetFolderPath/$fileName.json');
        data['file_path'] = newFile.path;

        // 4. If we moved the file to a new folder, delete the old Paused copy!
        if (oldFile != null && await oldFile.exists()) {
          await oldFile.delete();
        }
      }

      // Save the file
      await newFile.writeAsString(jsonEncode(data));
      print('Saved successfully to: ${newFile.path}');
    } catch (e) {
      print('Error saving file: $e');
    }
  }

  // --- GET ALL SAVED MATCHES ---
  static Future<List<Map<String, dynamic>>> getSavedMatches(String sportFolder) async {
    try {
      final basePath = await _getPublicDownloadPath();
      if (basePath == null) return [];

      List<Map<String, dynamic>> savedMatches = [];

      // Helper function to read from a specific physical subfolder
      Future<void> readFromFolder(String subFolder) async {
        final dir = Directory('$basePath/$sportFolder/$subFolder');
        if (await dir.exists()) {
          List<FileSystemEntity> files = dir.listSync();
          for (var file in files) {
            if (file is File && file.path.endsWith('.json')) {
              String content = await file.readAsString();
              Map<String, dynamic> data = jsonDecode(content);
              data['file_path'] = file.path;
              savedMatches.add(data);
            }
          }
        }
      }

      // Read from both the physical 'Completed' and 'Paused' folders
      await readFromFolder('Completed');
      await readFromFolder('Paused');

      // Sort matches by File Last Modified Date (newest at the top)
      savedMatches.sort((a, b) => File(b['file_path']).lastModifiedSync().compareTo(File(a['file_path']).lastModifiedSync()));

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