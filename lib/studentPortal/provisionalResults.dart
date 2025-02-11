import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:srm_hope/Utilities/credentials.dart';

class ProvisionalResultsPage extends StatefulWidget {
  @override
  _ProvisionalResultsPageState createState() => _ProvisionalResultsPageState();
}

class _ProvisionalResultsPageState extends State<ProvisionalResultsPage> {
  late Future<List<dynamic>> provisionalResultsFuture;

  @override
  void initState() {
    super.initState();
    provisionalResultsFuture = fetchProvisionalResults();
  }

  Future<List<dynamic>> fetchProvisionalResults() async {
    try {
      // Retrieve saved credentials.
      final credentials = await UserCredentials.getCredentials();
      if (credentials == null) {
        throw Exception('No saved credentials found. Please log in again.');
      }
      // Call the API using the saved email and password.
      final response = await http.post(
        Uri.parse('https://srm-api-t1zh.onrender.com/resultsXprovisional'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'user': credentials['email']!,
          'password': credentials['password']!,
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        // Case 2: Captcha error – keep retrying.
        if (decoded is Map &&
            decoded["message"] == "Retry....Captcha Error" &&
            decoded["response"] == 200) {
          // Wait a couple of seconds before retrying.
          await Future.delayed(Duration(seconds: 2));
          return await fetchProvisionalResults();
        }
        // Case 1: Valid response (a List of results)
        else if (decoded is List) {
          return decoded;
        }
        // Case 3: Unrecognized response.
        else {
          throw Exception("No results found.");
        }
      } else {
        throw Exception("Failed to retrieve provisional results.");
      }
    } catch (e) {
      throw Exception("Error fetching provisional results: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Provisional Results"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                provisionalResultsFuture = fetchProvisionalResults();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: provisionalResultsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // While waiting (including while retrying captcha errors), show a loading indicator.
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: TextStyle(color: Colors.white),
              ),
            );
          } else if (snapshot.hasData) {
            final results = snapshot.data!;
            if (results.isEmpty) {
              return Center(
                child: Text(
                  "No results found.",
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }
            return ListView.builder(
              padding: EdgeInsets.all(16.0),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final result = results[index] as Map<String, dynamic>;
                return ProvisionalResultCard(result: result);
              },
            );
          } else {
            return Center(
              child: Text(
                "No data available.",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }
        },
      ),
    );
  }
}

class ProvisionalResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  const ProvisionalResultCard({Key? key, required this.result}) : super(key: key);

  /// Returns a color based on the result value.
  Color getResultColor(String res) {
    if (res.toLowerCase() == 'pass') {
      return Colors.green;
    } else if (res.toLowerCase() == 'fail') {
      return Colors.red;
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    // Extract values from the result object.
    final code = result['code']?.toString().trim() ?? '';
    final course = result['course']?.toString().trim() ?? '';
    final credits = result['credits']?.toString().trim() ?? '';
    final grade = result['grade']?.toString().trim() ?? '';
    final resStr = result['result']?.toString().trim() ?? '';
    final semester = result['semester']?.toString().trim() ?? '';
    final sno = result['sno']?.toString().trim() ?? '';

    return Card(
      color: Color(0xFF1A1A2E),
      margin: EdgeInsets.only(bottom: 16),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Code and result badge.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  code,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: getResultColor(resStr),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    resStr,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            // Course name.
            Text(
              course,
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            SizedBox(height: 8),
            // Row: Credits, Grade, Semester.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Credits: $credits",
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                Text(
                  "Grade: $grade",
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                Text(
                  "Semester: $semester",
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ],
            ),
            SizedBox(height: 8),
            // Serial number aligned right.
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "S.No: $sno",
                style: TextStyle(fontSize: 14, color: Colors.white38),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
