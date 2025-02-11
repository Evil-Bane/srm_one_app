import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:srm_hope/Utilities/data_saver.dart'; // Your custom session/data saver
import 'package:srm_hope/Utilities/credentials.dart'; // Adjust path as necessary

// -----------------------
// AttendancePage Widget
// -----------------------
class AttendancePage extends StatefulWidget {
  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  late Future<Map<String, dynamic>> attendanceData;
  bool hasOdMl = false;

  @override
  void initState() {
    super.initState();
    attendanceData = fetchAttendanceData();
  }

  Future<Map<String, dynamic>> fetchAttendanceData() async {
    try {
      final sid = await UserSession.getSession();
      if (sid == null) throw Exception('No SID found. Please log in again.');

      // Fetch cumulative data first
      final cumulativeResponse = await http.post(
        Uri.parse('https://api-srm-one.vercel.app/user'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'method': 'getCummulativeAttendance', 'sid': sid},
      );

      if (cumulativeResponse.statusCode != 200) {
        throw Exception('Failed to fetch cumulative data');
      }

      final dynamic cumulativeRaw = json.decode(cumulativeResponse.body);
      List<Map<String, dynamic>> transformedCumulativeData = [];
      bool odMlDetected = false;

      if (cumulativeRaw is List) {
        transformedCumulativeData = cumulativeRaw.map<Map<String, dynamic>>((item) {
          final ml = int.tryParse(item['medical']?.toString() ?? "0") ?? 0;
          final oda = int.tryParse(item['odabsent']?.toString() ?? "0") ?? 0;
          final odp = int.tryParse(item['odpresent']?.toString() ?? "0") ?? 0;
          if (ml > 0 || oda > 0 || odp > 0) odMlDetected = true;

          return {
            'month_year': item['attendancemonthyear'],
            'present': item['present'],
            'absent': item['absent'],
            'ml': ml.toString(),
            'oda': oda.toString(),
            'odp': odp.toString(),
          };
        }).toList();
      }

      hasOdMl = odMlDetected;

      // Fetch subject-wise data
      dynamic subjectwiseResponse;
      if (hasOdMl) {
        int retryCount = 0;
        http.Response response;

        do {
          final credentials = await UserCredentials.getCredentials();
          if (credentials == null) throw Exception('No credentials found');

          response = await http.post(
            Uri.parse('https://srm-api-t1zh.onrender.com/attendanceDetailsPro'),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {
              'user': credentials['email']!,
              'password': credentials['password']!,
            },
          );

          if (response.body.contains('Retry....Captcha Error') && retryCount < 10) {
            await Future.delayed(Duration(milliseconds: 200));
            retryCount++;
          } else {
            break;
          }
        } while (retryCount < 10);

        if (response.body.contains('Login Failed')) {
          throw 'Password Changed, Login app again';
        }
        subjectwiseResponse = json.decode(response.body);
      } else {
        final res = await http.post(
          Uri.parse('https://api-srm-one.vercel.app/user'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {'method': 'getSubjectwiseAttendance', 'sid': sid},
        );
        subjectwiseResponse = json.decode(res.body);
      }

      // Transform subject data
      List<Map<String, dynamic>> transformedSubjectwiseData = [];
      if (hasOdMl && subjectwiseResponse is Map && subjectwiseResponse.containsKey('course_wise_attendance')) {
        transformedSubjectwiseData = (subjectwiseResponse['course_wise_attendance'] as List).map((item) {
          return {
            'code': item['code'],
            'description': item['description'],
            'max_hours': item['max_hours'],
            'att_hours': item['att_hours'],
            'total_percentage': item['total_percentage'],
            'od_ml_percentage': item['od_ml_percentage'],
          };
        }).toList();
      } else if (subjectwiseResponse is List) {
        transformedSubjectwiseData = subjectwiseResponse.map<Map<String, dynamic>>((item) {
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
    } catch (e) {
      if (e.toString().contains('Password Changed')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Password Changed, Login app again")),
          );
        });
      }
      throw Exception('Error: ${e.toString()}');
    }
  }


  Future<List<Map<String, dynamic>>> fetchHourwiseAttendance(String monthYear) async {
    try {
      final sid = await UserSession.getSession();
      if (sid == null) {
        throw Exception('No SID found. Please log in again.');
      }
      final response = await http.post(
        Uri.parse('https://api-srm-one.vercel.app/user'),
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
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => setState(() => attendanceData = fetchAttendanceData()),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: attendanceData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            if (snapshot.error.toString().contains('Password Changed')) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Password Changed, Login app again")),
                );
              });
            }
            return Center(child: Text("Error: ${snapshot.error}", style: TextStyle(color: Colors.red)));
          }
          if (!snapshot.hasData) return Center(child: Text("No data available"));

          final data = snapshot.data!;
          return AttendanceView(
            attendanceData: data,
            hasOdMl: hasOdMl,
            fetchHourwiseAttendance: fetchHourwiseAttendance,
          );
        },
      ),
    );
  }
}

// -----------------------
// Revised AttendanceView Widget
// -----------------------
class AttendanceView extends StatelessWidget {
  final Map<String, dynamic> attendanceData;
  final bool hasOdMl;
  final Future<List<Map<String, dynamic>>> Function(String) fetchHourwiseAttendance;

  const AttendanceView({
    required this.attendanceData,
    required this.hasOdMl,
    required this.fetchHourwiseAttendance,
  });

  @override
  Widget build(BuildContext context) {
    final cumulativeAttendance = List<Map<String, dynamic>>.from(
        attendanceData['cumulative_attendance'] ?? []
    );
    final courseWiseAttendance = List<Map<String, dynamic>>.from(
        attendanceData['course_wise_attendance'] ?? []
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OverallStatisticsCard(courseWiseAttendance: courseWiseAttendance, hasOdMl: hasOdMl),
          SizedBox(height: 20),
          Text('Monthly Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
          SizedBox(height: 12),
          SizedBox(
            height: 170,
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
          Text('Subject-wise Attendance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
          SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: courseWiseAttendance.length,
            itemBuilder: (context, index) => SubjectCard(
              subject: courseWiseAttendance[index],
              showOdMl: hasOdMl,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------
// OverallStatisticsCard Widget (Revised)
// -----------------------
class OverallStatisticsCard extends StatelessWidget {
  final List<Map<String, dynamic>> courseWiseAttendance;
  final bool hasOdMl;

  const OverallStatisticsCard({
    required this.courseWiseAttendance,
    required this.hasOdMl,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate base statistics
    final int totalMax = courseWiseAttendance.fold(0,
            (sum, item) => sum + (int.tryParse(item['max_hours']?.toString() ?? "0") ?? 0));

    final int totalAtt = courseWiseAttendance.fold(0,
            (sum, item) => sum + (int.tryParse(item['att_hours']?.toString() ?? "0") ?? 0));

    // Calculate OD/ML adjusted statistics
    final double totalOdMlHours = courseWiseAttendance.fold(0.0,
            (sum, item) => sum + ((double.tryParse(item['od_ml_percentage']?.toString() ?? "0") ?? 0) / 100) *
            (int.tryParse(item['max_hours']?.toString() ?? "0") ?? 0));

    // Calculate percentages
    final double basePercentage = totalMax > 0 ? (totalAtt / totalMax * 100) : 0;
    final double adjustedPercentage = totalMax > 0 ?
    ((totalAtt + totalOdMlHours) / totalMax * 100) : 0;

    return Card(
      color: Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Progress Indicator Container
                Container(
                  width: 60,
                  height: 60,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: adjustedPercentage / 100,
                        strokeWidth: 6,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          adjustedPercentage >= 75 ? Colors.green : Colors.red,
                        ),
                      ),
                      Text(
                        '${adjustedPercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 12
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Overall Attendance",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue
                          )),
                      SizedBox(height: 4),
                      Text("Attended: $totalAtt / $totalMax hours",
                          style: TextStyle(color: Colors.white, fontSize: 14)),
                      if (hasOdMl)
                        Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text("+ ${totalOdMlHours.toStringAsFixed(1)} OD/ML hours",
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 12,
                              )),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (hasOdMl)
              Padding(
                padding: EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: basePercentage / 100,
                        backgroundColor: Colors.grey.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        minHeight: 8,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Base ${basePercentage.toStringAsFixed(1)}%',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// -----------------------
// Revised MonthCard Widget
// -----------------------
class MonthCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Future<List<Map<String, dynamic>>> Function(String) fetchHourwiseAttendance;

  const MonthCard({required this.data, required this.fetchHourwiseAttendance});

  @override
  Widget build(BuildContext context) {
    final present = int.tryParse(data['present']?.toString() ?? "0") ?? 0;
    final absent = int.tryParse(data['absent']?.toString() ?? "0") ?? 0;
    final ratio = (present + absent) > 0 ? present / (present + absent) : 0.0;

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Color(0xFF1A1A2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: HourlyAttendanceView(
            monthYear: data['month_year'],
            fetchHourwiseAttendance: fetchHourwiseAttendance,
          ),
        ),
      ),
      child: Card(
        color: Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 200,
          padding: EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(data['month_year'],
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              LinearProgressIndicator(
                value: ratio,
                backgroundColor: Colors.grey,
                valueColor: AlwaysStoppedAnimation<Color>(ratio >= 0.75 ? Colors.green : Colors.red),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 100),
                child: SingleChildScrollView(
                  child: Text(
                    "Present: $present          Absent: $absent\nOD(A): ${data['oda']}                OD(P): ${data['odp']}\n\nMedical Leaves: ${data['ml']}",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
              Text("Click Here", style: TextStyle(color: Colors.blue, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------
// Revised SubjectCard Widget
// -----------------------
class SubjectCard extends StatefulWidget {
  final Map<String, dynamic> subject;
  final bool showOdMl;

  const SubjectCard({required this.subject, required this.showOdMl});

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
    final present = int.tryParse(widget.subject['att_hours']?.toString() ?? "0") ?? 0;
    final total = int.tryParse(widget.subject['max_hours']?.toString() ?? "0") ?? 0;
    if (total == 0) {
      resultText = "No data available";
      return;
    }
    double currentPercentage = (present / total) * 100;
    if (currentPercentage >= selectedPercentage) {
      final daysToBunk = ((100 * present - selectedPercentage * total) / selectedPercentage).floor();
      resultText = "Leave => $daysToBunk Classes";
    } else {
      final needed = ((selectedPercentage * total - 100 * present) / (100 - selectedPercentage)).ceil();
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
            Text("Code: ${widget.subject['code']}", style: TextStyle(color: Colors.white70)),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Total: ${widget.subject['max_hours']}", style: TextStyle(color: Colors.white)),
                    Text("Attended: ${widget.subject['att_hours']}", style: TextStyle(color: Colors.white)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("${widget.subject['total_percentage']}%",
                        style: TextStyle(
                          color: (double.tryParse(widget.subject['total_percentage'].toString()) ?? 0) >= 75
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        )),
                    if (widget.showOdMl && widget.subject.containsKey('od_ml_percentage'))
                      Text("OD/ML: ${widget.subject['od_ml_percentage']}%",
                          style: TextStyle(color: Colors.amber, fontSize: 12)),
                  ],
                ),
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
                  items: [65, 75].map((val) => DropdownMenuItem<int>(
                    value: val,
                    child: Text("$val%"),
                  )).toList(),
                  onChanged: (value) => setState(() {
                    selectedPercentage = value!;
                    _calculate();
                  }),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(resultText,
                      style: TextStyle(
                          color: resultText.contains("Attend") ? Colors.orange : Colors.blue,
                          fontWeight: FontWeight.bold)),
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
