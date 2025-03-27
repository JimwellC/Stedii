import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  ChallengesScreenState createState() => ChallengesScreenState();
}

class ChallengesScreenState extends State<ChallengesScreen> {
  int _completedTasks = 0;
  final List<Map<String, dynamic>> _challenges = [
    {
      "title": "Triple Focus",
      "description": "Complete 3 study sessions today",
      "completed": false
    },
    {
      "title": "Steady Streak",
      "description": "Study for 5 days in a row",
      "completed": false
    },
    {
      "title": "No Procrastination",
      "description": "Start your study session within 5 minutes of planning",
      "completed": false
    },
    {
      "title": "Pomodoro Pro",
      "description": "Complete 4 Pomodoro cycles",
      "completed": false
    },
    {
      "title": "Mind & Body Sync",
      "description": "Do 3 study sessions and 3 relaxation exercises",
      "completed": false
    },
    {
      "title": "Complete 1 Pomodoro Cycle",
      "description": "Finish a single Pomodoro cycle",
      "completed": false
    },
    {
      "title": "Complete 2 Pomodoro Cycle",
      "description": "Finish 2 Pomodoro cycles",
      "completed": false
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadCompletedCycles();
    _loadCompletedChallenges();
  }

  void _loadCompletedCycles() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getInt('completed_tasks') ?? 0;
    setState(() {
      _completedTasks = completed;
    });
    _updateChallenges(completed);
  }

  void _loadCompletedChallenges() async {
    final prefs = await SharedPreferences.getInstance();
    final completedList = prefs.getStringList('completed_challenge_titles') ?? [];

    setState(() {
      for (var challenge in _challenges) {
        if (completedList.contains(challenge['title'])) {
          challenge['completed'] = true;
        }
      }
    });
  }

  void _updateChallenges(int completedTasks) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> completedTitles = [];

    setState(() {
      for (var challenge in _challenges) {
        switch (challenge['title']) {
          case "Complete 1 Pomodoro Cycle":
            challenge['completed'] = completedTasks >= 1;
            break;
          case "Complete 2 Pomodoro Cycle":
            challenge['completed'] = completedTasks >= 2;
            break;
          case "Pomodoro Pro":
            challenge['completed'] = completedTasks >= 4;
            break;
          case "Triple Focus":
            challenge['completed'] = completedTasks >= 3;
            break;
          case "Steady Streak":
            challenge['completed'] = completedTasks >= 5;
            break;
          default:
            break;
        }

        if (challenge['completed'] == true) {
          completedTitles.add(challenge['title']);
        }
      }
    });

    prefs.setStringList('completed_challenge_titles', completedTitles);
  }

  double get _progress {
    final completedCount =
        _challenges.where((challenge) => challenge['completed']).length;
    return completedCount / _challenges.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 225,
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
                SizedBox(height: 75),
                Text(
                  "Today's Challenges",
                  style: TextStyle(
                    fontSize: 30,
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
                SizedBox(height: 10),
              ],
            ),
          ),
          SizedBox(height: 30),
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
                      Flexible(
                        child: Column(
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