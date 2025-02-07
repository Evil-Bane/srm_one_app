import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class UserDetails {
  static const String _fileName = 'user_details1.json';

  // Get the file path
  static Future<String> _getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_fileName';
  }

  // Save user details to local file
  static Future<void> saveUserDetails(Map<String, dynamic> details) async {
    final path = await _getFilePath();
    final file = File(path);
    final encodedDetails = jsonEncode(details);
    await file.writeAsString(encodedDetails);
  }

  // Read user details from local file
  static Future<Map<String, dynamic>?> getUserDetails() async {
    final path = await _getFilePath();
    final file = File(path);

    if (await file.exists()) {
      final contents = await file.readAsString();
      return jsonDecode(contents) as Map<String, dynamic>;
    }
    return null;
  }

  // Delete user details file
  static Future<void> deleteUserDetails() async {
    final path = await _getFilePath();
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  // Update specific fields in user details
  static Future<void> updateUserDetails(Map<String, dynamic> newDetails) async {
    final existing = await getUserDetails();
    if (existing != null) {
      existing.addAll(newDetails);
      await saveUserDetails(existing);
    } else {
      await saveUserDetails(newDetails);
    }
  }

  // Fetch user details from API and save locally
  static Future<Map<String, dynamic>?> fetchAndSaveUserDetails(String sid) async {
    try {
      final response = await http.post(
        Uri.parse('https://api-srm-one.onrender.com/user'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'sid': sid, 'method': 'getPersonalDetails'},
      );

      if (response.statusCode == 200) {
        final details = jsonDecode(response.body);
        await saveUserDetails(details);
        return details;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
