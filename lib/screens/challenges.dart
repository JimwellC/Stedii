import 'package:flutter/material.dart';

class ChallengesScreen extends StatefulWidget {
  final int completedTasks; // Number of completed tasks (Pomodoro cycles)

  const ChallengesScreen({super.key, required this.completedTasks});

  @override
  ChallengesScreenState createState() => ChallengesScreenState();
}

class ChallengesScreenState extends State<ChallengesScreen> {
  final List<Map<String, dynamic>> _challenges = [
    {
      "title": "Triple Focus",
      "description": "Complete 3 study sessions today",
      "completed": true
    },
    {
      "title": "Steady Streak",
      "description": "Study for 5 days in a row",
      "completed": true
    },
    {
      "title": "No Procrastination",
      "description": "Start your study session within 5 minutes of planning",
      "completed": true
    },
    {
      "title": "Pomodoro Pro",
      "description": "Complete 4 Pomodoro cycles",
      "completed": true
    },
    {
      "title": "Mind & Body Sync",
      "description": "Do 3 study sessions and 3 relaxation exercises",
      "completed": true
    },
    {
      "title": "Complete 1 Pomodoro Cycle",
      "description": "Finish a single Pomodoro cycle",
      "completed": false
    },
    {
      "title": "Complete 3 Pomodoro Cycle",
      "description": "Finish 3 Pomodoro cycles",
      "completed": false
    },
  ];

  @override
  void initState() {
    super.initState();
    _updateChallenges(widget.completedTasks);
  }

  void _updateChallenges(int completedTasks) {
    setState(() {
      final oneCycleIndex = _challenges.indexWhere(
        (challenge) => challenge['title'] == "Complete 1 Pomodoro Cycle",
      );
      if (oneCycleIndex != -1 && completedTasks >= 1) {
        _challenges[oneCycleIndex]['completed'] = true;
      }

      final threeCycleIndex = _challenges.indexWhere(
        (challenge) => challenge['title'] == "Complete 3 Pomodoro Cycle",
      );
      if (threeCycleIndex != -1 && completedTasks >= 3) {
        _challenges[threeCycleIndex]['completed'] = true;
      }
    });
  }

  double get _progress {
    final completedCount =
        _challenges.where((challenge) => challenge['completed']).length;
    return completedCount / _challenges.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFA31D1D),
        title: Text("Challenges"),
      ),
      body: Column(
        children: [
          // Header Container
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFFA31D1D),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Challenges",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Stay on track with your study goals",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          // Progress Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${(_progress * 100).toInt()}% completion progress!",
                  style: TextStyle(
                    color: Color(0xFFA31D1D),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 10),
                SizedBox(
                  height: 20,
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Color(0xFF6D2323),
                    color: Color(0xFFA31D1D),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          // Challenges List
          Expanded(
            child: ListView.builder(
              itemCount: _challenges.length,
              itemBuilder: (context, index) {
                final challenge = _challenges[index];
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: challenge['completed']
                              ? Color(0xFFA31D1D)
                              : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                        child: challenge['completed']
                            ? Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              )
                            : null,
                      ),
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            challenge['title'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFA31D1D),
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            challenge['description'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6D2323),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
