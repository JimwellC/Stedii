import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HistoryProgressScreen extends StatefulWidget {
  @override
  _HistoryProgressScreenState createState() => _HistoryProgressScreenState();
}

class _HistoryProgressScreenState extends State<HistoryProgressScreen> {
  List<Map<String, dynamic>> completedTasks = [];
  int _totalElapsedTime = 0;

  @override
  void initState() {
    super.initState();
    _loadElapsedTime();
    _loadHistory(); // ✅ Load completed tasks
  }

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
            return json.decode(task) as Map<String, dynamic>;
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
    return "$remainingSeconds sec"; // Show seconds if <1 min
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
        centerTitle: true, // This centers the title in the AppBar
      ),
      body: completedTasks.isEmpty
          ? Center(
              child: Text("No completed tasks yet",
                  style: TextStyle(fontSize: 18, color: Color(0xFF6D2323))))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
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
                  Expanded(
                    child: ListView.builder(
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
                  ),
                ],
              ),
            ),
    );
  }
}
