import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
// ignore: depend_on_referenced_packages
import 'package:table_calendar/table_calendar.dart';

class HistoryProgressScreen extends StatefulWidget {
  const HistoryProgressScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HistoryProgressScreenState createState() => _HistoryProgressScreenState();
}

class _HistoryProgressScreenState extends State<HistoryProgressScreen> {
  List<Map<String, dynamic>> completedTasks = [];
  int _totalElapsedTime = 0;

  Map<DateTime, int> trackedHours = {};
  late SharedPreferences prefs;
  List<Map<String, dynamic>> _history = []; // Add this to store history

  @override
  void initState() {
    super.initState();
    _loadElapsedTime();
    _loadHistory();
    _loadTrackedData();
  }

  // Function to format recorded time
  String formatRecordedTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    return "$hours h $minutes min";
  }

  Future<void> _loadTrackedData() async {
    prefs = await SharedPreferences.getInstance();
    String? savedData = prefs.getString('trackedHours');
    if (savedData != null) {
      setState(() {
        trackedHours = (json.decode(savedData) as Map<String, dynamic>).map(
          (key, value) => MapEntry(DateTime.parse(key), value as int),
        );
      });
    } else {
      trackedHours = {}; // Ensure it’s not null
    }
  }

//Kate
  bool _isTrackedDay(DateTime day) {
    return trackedHours.keys
        .any((trackedDay) => _normalizeDate(trackedDay) == _normalizeDate(day));
  }

  String _normalizeDate(DateTime date) {
    return date.toUtc().toIso8601String().split('T')[0]; // Keep only date part
  }

  Widget _buildCalendar() {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();

        List<String> recordedDays =
            snapshot.data!.getStringList('recorded_days') ?? [];
        DateTime now = DateTime.now();
        String today = "${now.year}-${now.month}-${now.day}";

        return TableCalendar(
          focusedDay: DateTime.now(),
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          calendarFormat: CalendarFormat.month,
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6D2323),
            ),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(color: Color(0xFF6D2323)),
            weekendStyle: TextStyle(color: Color(0xFF6D2323)),
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: recordedDays.contains(today)
                  ? Color(0xFFA31D1D)
                  : Colors.transparent,
            ),
            defaultTextStyle: TextStyle(color: Color(0xFF6D2323)),
            weekendTextStyle: TextStyle(color: Color(0xFF6D2323)),
            markerDecoration: BoxDecoration(
              color: Color(0xFFA31D1D),
              shape: BoxShape.rectangle,
            ),
          ),
          selectedDayPredicate: _isTrackedDay, // Improved selection logic
          eventLoader: (day) {
            return trackedHours.containsKey(_normalizeDate(day))
                ? [trackedHours[day] ?? 0]
                : [];
          },
        );
      },
    );
  }

  Widget _buildRecordedStats() {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();

        List<String>? storedTasks = snapshot.data!.getStringList('completedTasks');
        int totalSeconds = 0;

        if (storedTasks != null) {
          for (var task in storedTasks) {
            try {
              final parsed = json.decode(task);
              totalSeconds += (parsed['timeSpent'] as num?)?.toInt() ?? 0;
            } catch (e) {
              print("Error decoding task in stats: $e");
            }
          }
        }

        List<String> recordedDays =
            snapshot.data!.getStringList('recorded_days') ?? [];

        return Column(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Align items to the left
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 18, color: Color(0xFF6D2323)),
                children: [
                  TextSpan(
                      text: "Recorded Days: ",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(
                      text: "${recordedDays.length}"), // Number remains normal
                ],
              ),
            ),
            SizedBox(height: 5), // Small space between the two texts
            RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 18, color: Color(0xFF6D2323)),
                children: [
                  TextSpan(
                      text: "Recorded Hours: ",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: formatRecordedTime(totalSeconds)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
  // end kate

// kumi
  void _loadElapsedTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int savedTime = prefs.getInt('totalElapsedTime') ?? 0;

    print("Loaded elapsed time in HistoryProgressScreen: $savedTime");

    setState(() {
      _totalElapsedTime = savedTime;
    });
  }

  Future<void> _loadHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? storedTasks = prefs.getStringList('completedTasks');

    if (storedTasks != null) {
      setState(() {
        completedTasks = storedTasks.map((task) {
          try {
            return json.decode(task, reviver: (key, value) {
              if (key == 'date' && value is String) {
                return DateTime.tryParse(value);
              }
              return value;
            }) as Map<String, dynamic>;
          } catch (e) {
            print("Error decoding task: $e");
            return {'name': 'Unknown Task', 'timeSpent': 0}; // Fallback
          }
        }).toList();
      });
    }
  }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;

    if (minutes > 0) {
      return remainingSeconds > 0
          ? "$minutes min $remainingSeconds sec"
          : "$minutes min";
    }
    return "$remainingSeconds sec";
  }

  void _startNewTask(String taskName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // ✅ Reset elapsed time for the new task
    setState(() {
      _totalElapsedTime = 0;
    });

    // ✅ Store the reset value in SharedPreferences
    await prefs.setInt('totalElapsedTime', 0);
    print("New task '$taskName' started, resetting elapsed time to 0");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFEF9E1),
      appBar: AppBar(
        title: Text(
          "History & Progress",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFFA31D1D),
        iconTheme: IconThemeData(color: Color(0xFF6D2323)),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: true, // Ensures the back button is shown
        leading: Builder(
          builder: (context) {
            return ModalRoute.of(context)?.canPop == true
                ? IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                : Container();
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(height: 30),
              Center(
                child: Text(
                  "Progress",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6D2323),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color(0xFFE5D0AC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _buildCalendar(),
              ),
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.all(10),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Color(0xFFE5D0AC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _buildRecordedStats(),
              ),
              SizedBox(height: 16),
              Text(
                "History",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6D2323),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              completedTasks.isEmpty
                  ? Center(
                      child: Text(
                        "No completed tasks yet",
                        style:
                            TextStyle(fontSize: 18, color: Color(0xFF6D2323)),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: completedTasks.length,
                      itemBuilder: (context, index) {
                        String taskName = completedTasks[index]['name'];
                        int timeSpent = completedTasks[index]['timeSpent'];

                        return Container(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color(0xFFE5D0AC),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                taskName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6D2323),
                                ),
                              ),
                              SizedBox(height: 8),
                              Stack(
                                children: [
                                  Container(
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      double progressWidth =
                                          (timeSpent / 8100) *
                                              constraints.maxWidth;
                                      return AnimatedContainer(
                                        duration: Duration(milliseconds: 500),
                                        width: progressWidth.clamp(
                                            0, constraints.maxWidth),
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: Color(0xFFA31D1D),
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Time Spent: ${formatTime(timeSpent)}",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF6D2323),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
