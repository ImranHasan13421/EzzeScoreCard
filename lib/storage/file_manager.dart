// lib/storage/file_manager.dart
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FileManager {
  // --- SAVE MATCH ---
  static Future<void> saveMatchFile(String sportFolder, String fileName, Map<String, dynamic> data) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final String folderPath = '${directory.path}/EzzeScoreCard/$sportFolder';
      final sportDir = Directory(folderPath);

      if (!await sportDir.exists()) {
        await sportDir.create(recursive: true);
      }

      final File file = File('$folderPath/$fileName.json');
      String jsonString = jsonEncode(data);
      await file.writeAsString(jsonString);

      print('Saved successfully to: ${file.path}');
    } catch (e) {
      print('Error saving file: $e');
    }
  }

  // --- GET SAVED MATCHES ---
  static Future<List<Map<String, dynamic>>> getSavedMatches(String sportFolder) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final String folderPath = '${directory.path}/EzzeScoreCard/$sportFolder';
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

          // NEW: We inject the file's exact location into the data so we can delete it later
          data['file_path'] = file.path;

          savedMatches.add(data);
        }
      }

      return savedMatches.reversed.toList();
    } catch (e) {
      print('Error reading files: $e');
      return [];
    }
  }

  // --- DELETE MATCH (NEW) ---
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