import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:srm_hope/Utilities/data_saver.dart';

class InternalMarksPage extends StatefulWidget {
  @override
  _InternalMarksPageState createState() => _InternalMarksPageState();
}

class _InternalMarksPageState extends State<InternalMarksPage> {
  late Future<dynamic> internalMarksFuture;

  @override
  void initState() {
    super.initState();
    internalMarksFuture = fetchInternalMarks();
  }

  Future<dynamic> fetchInternalMarks() async {
    try {
      final sid = await UserSession.getSession();
      if (sid == null) {
        throw Exception('No SID found. Please log in again.');
      }

      final response = await http.post(
        Uri.parse('https://api-srm-one.vercel.app/user'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'method': 'getInternalMarkDetails',
          'sid': sid,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data["Status"] == "Error") {
          return data;
        }
        return data;
      } else {
        throw Exception('Failed to retrieve internal marks details.');
      }
    } catch (error) {
      throw Exception('Error fetching internal marks details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Internal Marks"),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                internalMarksFuture = fetchInternalMarks();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<dynamic>(
        future: internalMarksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (snapshot.hasData) {
            final data = snapshot.data;
            if (data is Map && data["Status"] == "Error") {
              return _buildNoMarksFound();
            }
            if (data is List && data.isNotEmpty) {
              return _buildMarksList(data);
            }
            return _buildNoMarksFound();
          } else {
            return _buildNoMarksFound();
          }
        },
      ),
    );
  }

  Widget _buildMarksList(List<dynamic> marks) {
    return ListView.separated(
      padding: EdgeInsets.all(16),
      itemCount: marks.length,
      separatorBuilder: (context, index) => SizedBox(height: 16),
      itemBuilder: (context, index) {
        final subject = marks[index];
        return _buildSubjectCard(subject);
      },
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> subject) {
    final marks = subject['sumofmarks'].split(' / ');
    final obtained = double.parse(marks[0]);
    final max = double.parse(marks[1]);
    final percentage = (obtained / max) * 100;
    final isPassed = percentage >= 50;

    return Card(
      elevation: 4,
      color: Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            _buildProgressIndicator(percentage, isPassed),
            SizedBox(width: 16), // Reduced spacing
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject['subjectdesc'],
                    style: TextStyle(
                      fontSize: 16, // Reduced font size
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                    maxLines: 2, // Allow text to wrap
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Text(
                    subject['subjectcode'],
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8, // Add spacing between chips
                    runSpacing: 8, // Add spacing between lines
                    children: [
                      _buildMarksChip('Obtained', obtained.toStringAsFixed(2)),
                      _buildMarksChip('Max', max.toStringAsFixed(2)),
                      _buildStatusIndicator(isPassed),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(double percentage, bool isPassed) {
    return SizedBox(
      width: 70, // Reduced size
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: percentage / 100,
            strokeWidth: 3,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              isPassed ? Colors.green : Colors.red,
            ),
          ),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 10, // Reduced font size
              fontWeight: FontWeight.bold,
              color: isPassed ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarksChip(String label, String value) {
    return Chip(
      backgroundColor: Colors.blue.shade50,
      label: Text(
        '$label: $value',
        style: TextStyle(
          color: Colors.blue.shade800,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(bool isPassed) {
    return Chip(
      backgroundColor: isPassed ? Colors.green.shade50 : Colors.orange.shade50,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPassed ? Icons.check_circle : Icons.warning,
            color: isPassed ? Colors.green : Colors.orange,
            size: 16,
          ),
          SizedBox(width: 4),
          Text(
            isPassed ? 'Passing' : 'Failing',
            style: TextStyle(
              color: isPassed ? Colors.green : Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoMarksFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment, size: 60, color: Colors.grey.shade400),
          SizedBox(height: 16),
          Text(
            'No Marks Available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your marks will appear here once they are published',
            style: TextStyle(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}