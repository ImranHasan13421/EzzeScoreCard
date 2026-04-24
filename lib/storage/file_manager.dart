// lib/storage/file_manager.dart
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FileManager {
  static Future<void> saveMatchFile(String sportFolder, String fileName, Map<String, dynamic> data) async {
    try {
      // Gets the safe 'Documents' directory on Android/iOS
      final directory = await getApplicationDocumentsDirectory();

      // Create the EzzeScoreCard and Sport subdirectories
      final String folderPath = '${directory.path}/EzzeScoreCard/$sportFolder';
      final sportDir = Directory(folderPath);

      if (!await sportDir.exists()) {
        await sportDir.create(recursive: true);
      }

      // Create and write the JSON file
      final File file = File('$folderPath/$fileName.json');
      String jsonString = jsonEncode(data);
      await file.writeAsString(jsonString);

      print('Saved successfully to: ${file.path}');
    } catch (e) {
      print('Error saving file: $e');
    }
  }
}