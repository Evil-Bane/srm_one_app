import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:srm_hope/Utilities/data_saver.dart';

class TimetablePage extends StatefulWidget {
  @override
  _TimetablePageState createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  Map<String, List<String>> timetable = {};
  bool _isLoading = true;

  // Define the order of days for tabs.
  final List<String> dayOrder = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
  int defaultTabIndex = 0;

  // Fixed period timings for 7 periods.
  final List<TimeOfDay> periodTimes = [
    TimeOfDay(hour: 9, minute: 20),  // Period 1
    TimeOfDay(hour: 10, minute: 10), // Period 2
    TimeOfDay(hour: 11, minute: 10), // Period 3
    TimeOfDay(hour: 12, minute: 0),  // Period 4 (ends at 12:50)
    TimeOfDay(hour: 14, minute: 0),  // Period 5 (post-lunch)
    TimeOfDay(hour: 14, minute: 50), // Period 6
    TimeOfDay(hour: 15, minute: 40), // Period 7
  ];

  // End time for the last period (4:30 PM)
  final TimeOfDay lastPeriodEnd = TimeOfDay(hour: 16, minute: 30);

  @override
  void initState() {
    super.initState();
    // Set default tab based on current weekday (Monday=1, ..., Sunday=7)
    final todayWeekday = DateTime.now().weekday;
    if (todayWeekday >= 1 && todayWeekday <= 5) {
      defaultTabIndex = todayWeekday - 1;
    } else {
      defaultTabIndex = 0;
    }
    _fetchTimetable();
  }

  Future<void> _fetchTimetable() async {
    try {
      final sid = await UserSession.getSession();
      if (sid != null) {
        final response = await http.post(
          Uri.parse('https://api-srm-one.vercel.app/timetable'),
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {
            'sid': sid,
          },
        );

        if (response.statusCode == 200) {
          final responseBody = jsonDecode(response.body);
          setState(() {
            timetable = {};
            // For each day in the defined order, retrieve up to 7 periods.
            for (var day in dayOrder) {
              timetable[day] = List<String>.from(
                responseBody.containsKey(day) ? responseBody[day] : [],
              ).where((subject) => subject != null).take(7).toList();
            }
            _isLoading = false;
          });
        } else {
          _handleError();
        }
      } else {
        _handleError();
      }
    } catch (e) {
      _handleError();
    }
  }

  void _handleError() {
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to load timetable. Please try again later.')),
    );
  }

  /// Converts a TimeOfDay to total minutes.
  int _timeOfDayToMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  /// Returns the index of the period to highlight (if any) based on current time.
  /// Accounts for lunch break between 12:50 PM and 2:00 PM.
  int? _getCurrentPeriodIndex() {
    final now = TimeOfDay.now();
    final nowMin = _timeOfDayToMinutes(now);

    // Define period durations (in minutes)
    const regularPeriodDuration = 50;
    const lunchBreakStart = TimeOfDay(hour: 12, minute: 50);
    const lunchBreakEnd = TimeOfDay(hour: 14, minute: 0); // 2:00 PM

    // Convert special times to minutes
    final lunchStartMin = _timeOfDayToMinutes(lunchBreakStart);
    final lunchEndMin = _timeOfDayToMinutes(lunchBreakEnd);
    final lastPeriodEndMin = _timeOfDayToMinutes(lastPeriodEnd);

    // Check if we're in lunch break first
    if (nowMin >= lunchStartMin && nowMin < lunchEndMin) {
      return null;
    }

    // Check regular periods
    for (int i = 0; i < periodTimes.length; i++) {
      final periodStart = _timeOfDayToMinutes(periodTimes[i]);
      int periodEnd;

      if (i < periodTimes.length - 1) {
        // For periods before lunch break (period 4 ends at 12:50)
        if (i == 3) { // 4th period (index 3)
          periodEnd = _timeOfDayToMinutes(lunchBreakStart);
        } else {
          periodEnd = periodStart + regularPeriodDuration;
        }
      } else {
        periodEnd = lastPeriodEndMin;
      }

      // Check if current time falls within this period
      if (nowMin >= periodStart && nowMin < periodEnd) {
        // Check if we're in the "preview" window for next period
        if (i < periodTimes.length - 1) {
          final nextPeriodStart = (i == 3) // After lunch break
              ? _timeOfDayToMinutes(lunchBreakEnd)
              : periodStart + regularPeriodDuration;

          if (nowMin >= periodEnd - 5) { // 5 minute preview
            return i + 1;
          }
        }
        return i;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // When loading, show a scaffold with the refresh button and a CircularProgressIndicator.
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Timetable"),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  _isLoading = true;
                });
                _fetchTimetable();
              },
            ),
          ],
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // When data is loaded, show the timetable in a tab view.
    return DefaultTabController(
      initialIndex: defaultTabIndex,
      length: dayOrder.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Timetable"),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  _isLoading = true;
                });
                _fetchTimetable();
              },
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.blueAccent,
            indicatorWeight: 3.0,
            tabs: dayOrder.map((day) => Tab(text: day)).toList(),
          ),
        ),
        body: TabBarView(
          children: dayOrder.map((day) {
            final periods = timetable[day] ?? [];
            // If this tab corresponds to the current day, compute the highlight index.
            final todayWeekday = DateTime.now().weekday;
            final todayName = _weekdayToName(todayWeekday);
            final int? highlightIndex = (day == todayName) ? _getCurrentPeriodIndex() : null;

            return Padding(
              padding: const EdgeInsets.all(12.0),
              child: periods.isEmpty
                  ? Center(
                child: Text(
                  "No periods scheduled for $day.",
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
              )
                  : ListView.builder(
                itemCount: periods.length,
                itemBuilder: (context, index) {
                  final subject = periods[index];
                  final bool isCurrent = (highlightIndex != null && index == highlightIndex);
                  return Card(
                    color: isCurrent ? Colors.black : Color(0xFF1A1A2E),
                    elevation: isCurrent ? 6 : 3,
                    margin: EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isCurrent ? Colors.green : Colors.blueAccent,
                        width: isCurrent ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: isCurrent ? Colors.green : Colors.blueAccent,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                      title: Text(
                        subject,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: isCurrent
                          ? Text(
                        "Period ${index + 1} Ongoing",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      )
                          : Text(
                        "Period ${index + 1}",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  );
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Helper method to convert weekday integer (1=Monday,...,7=Sunday) to day name.
  String _weekdayToName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }
}