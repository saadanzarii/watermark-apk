import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class HistoryItem {
  final String path;
  final DateTime date;

  HistoryItem({required this.path, required this.date});

  Map<String, dynamic> toJson() => {
        'path': path,
        'date': date.toIso8601String(),
      };

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      path: json['path'],
      date: DateTime.parse(json['date']),
    );
  }
}

class HistoryService {
  static const String _fileName = 'watermark_history.json';
  
  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  Future<List<HistoryItem>> loadHistory() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(contents);
        return jsonList.map((e) => HistoryItem.fromJson(e)).toList()
          ..sort((a, b) => b.date.compareTo(a.date)); // Newest first
      }
    } catch (e) {
      debugPrint("Error loading history: $e");
    }
    return [];
  }

  Future<void> saveToHistory(String imagePath) async {
    try {
      final history = await loadHistory();
      // Add the new item
      history.insert(0, HistoryItem(path: imagePath, date: DateTime.now()));
      
      final file = await _localFile;
      final jsonList = history.map((e) => e.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      debugPrint("Error saving to history: $e");
    }
  }

  Future<String> saveImageToLocalDirectory(Uint8List imageBytes, String originalName) async {
    final directory = await getApplicationDocumentsDirectory();
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String newPath = '${directory.path}/watermark_$timestamp.png';
    final file = File(newPath);
    await file.writeAsBytes(imageBytes);
    await saveToHistory(newPath);
    return newPath;
  }
}
