import 'dart:io';
import 'package:path_provider/path_provider.dart';

class UserSession {
  static Future<String> _getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/user_session.txt';
  }

  static Future<void> saveSession(String sid) async {
    final path = await _getFilePath();
    final file = File(path);
    await file.writeAsString(sid);
  }

  static Future<String?> getSession() async {
    try {
      final path = await _getFilePath();
      final file = File(path);
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      throw ('Error reading session: $e');
    }
    return null;
  }

  static Future<void> clearSession() async {
    final path = await _getFilePath();
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
