import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioDownloadService {
  Future<String> getAudioPath(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$fileName';
  }

  Future<void> downloadAudio(String url, String fileName) async {
    final ReceivePort receivePort = ReceivePort();
    await Isolate.spawn(_downloadIsolate, [url, fileName, receivePort.sendPort]);

    final response = await receivePort.first;
    if (response != 'done') throw Exception('Erro ao baixar áudio');
  }

  static Future<void> _downloadIsolate(List<dynamic> args) async {
    final url = args[0];
    final fileName = args[1];
    final SendPort sendPort = args[2];

    try {
      final response = await http.get(Uri.parse(url));
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('downloaded_$fileName', true);

      sendPort.send('done');
    } catch (e) {
      sendPort.send(e.toString());
    }
  }

  Future<bool> isDownloaded(String fileName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('downloaded_$fileName') ?? false;
  }

  Future<void> clearDownloads() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = dir.listSync();
    for (var file in files) {
      if (file is File && file.path.endsWith('.mp3')) {
        await file.delete();
      }
    }
    final prefs = await SharedPreferences.getInstance();
    prefs.clear(); // Opcional: apaga flags de downloads
  }
}
