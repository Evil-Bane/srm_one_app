import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:srm_hope/Utilities/data_saver.dart'; // Your custom session/data saver


// -----------------------
// AttendancePage Widget
// -----------------------
class AttendancePage extends StatefulWidget {
  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  late Future<Map<String, dynamic>> attendanceData;

  @override
  void initState() {
    super.initState();
    attendanceData = fetchAttendanceData();
  }

  Future<Map<String, dynamic>> fetchAttendanceData() async {
    try {
      final sid = await UserSession.getSession();
      if (sid == null) {
        throw Exception('No SID found. Please log in again.');
      }

      // Fetch subject-wise attendance
      final subjectwiseResponse = await http.post(
        Uri.parse('https://api-srm-one.onrender.com/user'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'method': 'getSubjectwiseAttendance',
          'sid': sid,
        },
      );

      // Fetch cumulative (monthly) attendance data
      final cumulativeResponse = await http.post(
        Uri.parse('https://api-srm-one.onrender.com/user'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'method': 'getCummulativeAttendance',
          'sid': sid,
        },
      );

      if (subjectwiseResponse.statusCode == 200 &&
          cumulativeResponse.statusCode == 200) {
        final subjectwiseData = json.decode(subjectwiseResponse.body);
        final cumulativeData = json.decode(cumulativeResponse.body);

        // Transform cumulative attendance data
        List<Map<String, dynamic>> transformedCumulativeData = [];
        if (cumulativeData is List) {
          transformedCumulativeData = cumulativeData.map<Map<String, dynamic>>((item) {
            return {
              'month_year': item['attendancemonthyear'],
              'present': item['present'],
              'absent': item['absent'],
            };
          }).toList();
        }

        // Transform subject-wise attendance data
        List<Map<String, dynamic>> transformedSubjectwiseData = [];
        if (subjectwiseData is List) {
          transformedSubjectwiseData = subjectwiseData.map<Map<String, dynamic>>((item) {
            return {
              'code': item['subjectcode'],
              'description': item['subjectdesc'],
              'max_hours': item['total'],
              'att_hours': item['present'],
              'total_percentage': item['presentpercentage'],
            };
          }).toList();
        }

        return {
          'message': 'Data Retrieved Successfully',
          'cumulative_attendance': transformedCumulativeData,
          'course_wise_attendance': transformedSubjectwiseData,
        };
      } else {
        throw Exception('Failed to retrieve attendance data');
      }
    } catch (error) {
      throw Exception('Error fetching attendance data: $error');
    }
  }

  Future<List<Map<String, dynamic>>> fetchHourwiseAttendance(String monthYear) async {
    try {
      final sid = await UserSession.getSession();
      if (sid == null) {
        throw Exception('No SID found. Please log in again.');
      }
      final response = await http.post(
        Uri.parse('https://api-srm-one.onrender.com/user'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'method': 'getHourwiseAttendance',
          'sid': sid,
        },
      );
      if (response.statusCode == 200) {
        List<dynamic> allData = json.decode(response.body);
        // Filter the data for the selected month (e.g. "Jan-2025")
        final parts = monthYear.split('-');
        final month = parts[0];
        final monthData = allData.where((item) {
          final date = item['attendancedate'] as String;
          return date.contains(month);
        }).toList();
        return List<Map<String, dynamic>>.from(monthData);
      } else {
        throw Exception('Failed to fetch hourwise attendance data');
      }
    } catch (error) {
      throw Exception('Error fetching hourwise attendance data: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Attendance Details"),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: attendanceData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          else if (snapshot.hasError)
            return Center(child: Text("Error: ${snapshot.error}", style: TextStyle(color: Colors.red)));
          else if (snapshot.hasData && snapshot.data != null) {
            final data = snapshot.data!;
            return AttendanceView(
              attendanceData: data,
              fetchHourwiseAttendance: fetchHourwiseAttendance,
            );
          } else {
            return Center(child: Text("No data available"));
          }
        },
      ),
    );
  }
}

// -----------------------
// AttendanceView Widget
// -----------------------
class AttendanceView extends StatelessWidget {
  final Map<String, dynamic> attendanceData;
  final Future<List<Map<String, dynamic>>> Function(String monthYear) fetchHourwiseAttendance;

  AttendanceView({required this.attendanceData, required this.fetchHourwiseAttendance});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> cumulativeAttendance =
    List<Map<String, dynamic>>.from(attendanceData['cumulative_attendance'] ?? []);
    final List<Map<String, dynamic>> courseWiseAttendance =
    List<Map<String, dynamic>>.from(attendanceData['course_wise_attendance'] ?? []);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OverallStatisticsCard(courseWiseAttendance: courseWiseAttendance),
          SizedBox(height: 20),
          Text(
            'Monthly Summary',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: cumulativeAttendance.length,
              separatorBuilder: (_, __) => SizedBox(width: 12),
              itemBuilder: (context, index) => MonthCard(
                data: cumulativeAttendance[index],
                fetchHourwiseAttendance: fetchHourwiseAttendance,
              ),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Subject-wise Attendance',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: courseWiseAttendance.length,
            itemBuilder: (context, index) {
              return SubjectCard(subject: courseWiseAttendance[index]);
            },
          ),
        ],
      ),
    );
  }
}

// -----------------------
// OverallStatisticsCard Widget
// -----------------------
class OverallStatisticsCard extends StatelessWidget {
  final List<Map<String, dynamic>> courseWiseAttendance;

  OverallStatisticsCard({required this.courseWiseAttendance});

  @override
  Widget build(BuildContext context) {
    int totalMax = courseWiseAttendance.fold<int>(
      0,
          (sum, item) => sum + (int.tryParse(item['max_hours']?.toString() ?? "0") ?? 0),
    );
    int totalAtt = courseWiseAttendance.fold<int>(
      0,
          (sum, item) => sum + (int.tryParse(item['att_hours']?.toString() ?? "0") ?? 0),
    );
    double overallPercentage = totalMax > 0 ? (totalAtt / totalMax * 100) : 0;

    return Card(
      color: Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: overallPercentage / 100,
                    strokeWidth: 6,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      overallPercentage >= 75 ? Colors.green : Colors.red,
                    ),
                  ),
                  Text(
                    '${overallPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Overall Attendance",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                SizedBox(height: 4),
                Text("Attended: $totalAtt / $totalMax hours",
                    style: TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------
// MonthCard Widget
// -----------------------
class MonthCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Future<List<Map<String, dynamic>>> Function(String) fetchHourwiseAttendance;

  MonthCard({required this.data, required this.fetchHourwiseAttendance});

  @override
  Widget build(BuildContext context) {
    final int present = int.tryParse(data['present']?.toString() ?? "0") ?? 0;
    final int absent = int.tryParse(data['absent']?.toString() ?? "0") ?? 0;
    final double ratio = (present + absent) > 0 ? present / (present + absent) : 0.0;

    return GestureDetector(
      onTap: () {
        // Open a modal bottom sheet (which comes from below) for hourly attendance.
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) {
            return Container(
              // You can adjust the height as needed.
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: Color(0xFF1A1A2E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: HourlyAttendanceView(
                monthYear: data['month_year'],
                fetchHourwiseAttendance: fetchHourwiseAttendance,
              ),
            );
          },
        );
      },
      child: Card(
        color: Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 150,
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                data['month_year'],
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              LinearProgressIndicator(
                value: ratio,
                backgroundColor: Colors.grey,
                valueColor: AlwaysStoppedAnimation<Color>(ratio >= 0.75 ? Colors.green : Colors.red),
              ),
              SizedBox(height: 8),
              Text(
                "Present: $present \n Absent: $absent",
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              Text("Click Here", style: TextStyle(color: Colors.blue, fontSize: 12),)
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------
// SubjectCard Widget
// -----------------------
class SubjectCard extends StatefulWidget {
  final Map<String, dynamic> subject;
  SubjectCard({required this.subject});

  @override
  _SubjectCardState createState() => _SubjectCardState();
}

class _SubjectCardState extends State<SubjectCard> {
  int selectedPercentage = 75;
  String resultText = "";

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    final int present = int.tryParse(widget.subject['att_hours']?.toString() ?? "0") ?? 0;
    final int total = int.tryParse(widget.subject['max_hours']?.toString() ?? "0") ?? 0;
    if (total == 0) {
      resultText = "No data available";
      return;
    }
    double currentPercentage = (present / total) * 100;
    if (currentPercentage >= selectedPercentage) {
      final int daysToBunk =
      ((100 * present - selectedPercentage * total) / selectedPercentage).floor();
      resultText = "Leave => $daysToBunk Classes";
    } else {
      final int needed =
      ((selectedPercentage * total - 100 * present) / (100 - selectedPercentage)).ceil();
      resultText = "Attend => $needed Classes";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.subject['description'] ?? "",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              "Code: ${widget.subject['code']}",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total: ${widget.subject['max_hours']}",
                    style: TextStyle(color: Colors.white)),
                Text("Attended: ${widget.subject['att_hours']}",
                    style: TextStyle(color: Colors.white)),
                Text("${widget.subject['total_percentage']}%",
                    style: TextStyle(
                        color: (double.tryParse(widget.subject['total_percentage'].toString()) ?? 0) >= 75
                            ? Colors.green
                            : Colors.red)),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Text("Target:", style: TextStyle(color: Colors.white70)),
                SizedBox(width: 8),
                DropdownButton<int>(
                  value: selectedPercentage,
                  dropdownColor: Color(0xFF1A1A2E),
                  style: TextStyle(color: Colors.white),
                  items: [65, 75]
                      .map((val) => DropdownMenuItem<int>(
                    value: val,
                    child: Text("$val%"),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedPercentage = value!;
                      _calculate();
                    });
                  },
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    resultText,
                    style: TextStyle(
                        color: resultText.contains("Attend") ? Colors.orange : Colors.blue,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HourlyAttendanceView extends StatefulWidget {
  final String monthYear;
  final Future<List<Map<String, dynamic>>> Function(String monthYear) fetchHourwiseAttendance;
  HourlyAttendanceView({required this.monthYear, required this.fetchHourwiseAttendance});

  @override
  _HourlyAttendanceViewState createState() => _HourlyAttendanceViewState();
}

class _HourlyAttendanceViewState extends State<HourlyAttendanceView> {
  late Future<List<Map<String, dynamic>>> hourwiseData;

  @override
  void initState() {
    super.initState();
    hourwiseData = widget.fetchHourwiseAttendance(widget.monthYear);
  }

  // Helper: Returns a color based on the status value.
  Color getAttendanceColor(String status) {
    status = status.trim();
    if (status == 'P') return Colors.green;
    if (status == 'A') return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    // We use a SingleChildScrollView for vertical scrolling in case of many rows.
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: hourwiseData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return Center(child: CircularProgressIndicator());
            else if (snapshot.hasError)
              return Center(child: Text("Error: ${snapshot.error}", style: TextStyle(color: Colors.red)));
            else if (!snapshot.hasData || snapshot.data!.isEmpty)
              return Center(child: Text("No attendance data available", style: TextStyle(color: Colors.white)));
            final data = snapshot.data!;
            return Table(
              border: TableBorder.all(color: Colors.white24),
              columnWidths: const <int, TableColumnWidth>{
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
                4: FlexColumnWidth(1),
                5: FlexColumnWidth(1),
                6: FlexColumnWidth(1),
                7: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.white10),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                    ...List.generate(7, (index) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('P${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    )),
                  ],
                ),
                ...data.map((dayData) => TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(dayData['attendancedate'] ?? '', style: TextStyle(fontSize: 14)),
                    ),
                    ...List.generate(7, (index) {
                      final status = dayData['h${index + 1}']?.toString() ?? 'null';
                      return Container(
                        padding: EdgeInsets.all(12),
                        color: getAttendanceColor(status),
                        child: Text(
                          status.trim() == 'null' ? '-' : status.trim(),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      );
                    }),
                  ],
                )).toList(),
              ],
            );
          },
        ),
      ),
    );
  }
}
