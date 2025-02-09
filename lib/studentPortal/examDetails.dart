import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:srm_hope/Utilities/data_saver.dart';

class ExamDetailsPage extends StatefulWidget {
  @override
  _ExamDetailsPageState createState() => _ExamDetailsPageState();
}

class _ExamDetailsPageState extends State<ExamDetailsPage> {
  late Future<List<dynamic>> examDetailsFuture;
  String? selectedSemester;

  @override
  void initState() {
    super.initState();
    examDetailsFuture = fetchExamDetails();
  }

  Future<List<dynamic>> fetchExamDetails() async {
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
          'method': 'getExamDetails',
          'sid': sid,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // If the response is a List, we assume success.
        if (data is List) {
          return data;
        } else {
          throw Exception("Data unavailable or invalid response.");
        }
      } else {
        throw Exception("Failed to retrieve exam details.");
      }
    } catch (error) {
      throw Exception("Error fetching exam details: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Exam Results"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                examDetailsFuture = fetchExamDetails();
              });
            },
          )
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: examDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (snapshot.hasData) {
            final examDetails = snapshot.data!;
            if (examDetails.isEmpty) {
              return Center(child: Text("No exam data available"));
            }

            // Get distinct semesters from the API response.
            final semesters = examDetails
                .map<String>((exam) => exam['semester'].toString().trim())
                .toSet()
                .toList();
            // Optionally, sort the semesters numerically.
            semesters.sort((a, b) => int.parse(a).compareTo(int.parse(b)));

            // If no semester has been selected yet, default to the first.
            selectedSemester ??= semesters.first;

            // Filter the exam details by the selected semester.
            final filteredExamDetails = examDetails.where((exam) {
              return exam['semester'].toString().trim() == selectedSemester;
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Semester filter buttons
                Container(
                  height: 60,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: semesters.length,
                    itemBuilder: (context, index) {
                      final semester = semesters[index];
                      final isSelected = semester == selectedSemester;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                             backgroundColor: isSelected ? Colors.blue : Colors.grey[800],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              selectedSemester = semester;
                            });
                          },
                          child: Text(
                            "Semester $semester",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // List of exam detail cards filtered by semester
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(16.0),
                    itemCount: filteredExamDetails.length,
                    itemBuilder: (context, index) {
                      final exam = filteredExamDetails[index] as Map<String, dynamic>;
                      return ExamDetailCard(exam: exam);
                    },
                  ),
                ),
              ],
            );
          } else {
            return Center(child: Text("No data available"));
          }
        },
      ),
    );
  }
}

class ExamDetailCard extends StatelessWidget {
  final Map<String, dynamic> exam;
  const ExamDetailCard({Key? key, required this.exam}) : super(key: key);

  /// Returns a color based on the result status.
  Color getResultColor(String result) {
    if (result.toLowerCase() == 'pass') {
      return Colors.green;
    } else if (result.toLowerCase() == 'fail') {
      return Colors.red;
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    // Extract values from the exam object.
    final result = exam['result']?.toString().trim() ?? '';
    final grade = exam['grade']?.toString().trim() ?? '';
    final credit = exam['credit']?.toString().trim() ?? '';
    final marksObtained = exam['marksobtained']?.toString().trim() ?? '';
    final semester = exam['semester']?.toString().trim() ?? '';
    final subjectCode = exam['subjectcode']?.toString().trim() ?? '';
    final subjectDesc = exam['subjectdesc']?.toString().trim() ?? '';
    final monthYear = exam['monthyear']?.toString().trim() ?? '';

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
            // Header: Subject Code and Result badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  subjectCode,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: getResultColor(result),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    result,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            // Subject description
            Text(
              subjectDesc,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 8),
            // Semester and Month/Year
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Semester: $semester",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  monthYear,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
            Divider(color: Colors.white38, thickness: 1, height: 20),
            // Exam details: Grade, Credit, Marks Obtained
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoColumn("Grade", grade),
                _buildInfoColumn("Credit", credit),
                _buildInfoColumn("Marks", marksObtained),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Helper method to build a column for each exam detail.
  Widget _buildInfoColumn(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
