import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stedii/screens/timer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> _tasks = []; // Only declare once
  final TextEditingController _taskController = TextEditingController();

  final List<String> _quotes = [
    "Success is not final, failure is not fatal: it is the courage to continue that counts.",
    "Believe in yourself and all that you are. Know that there is something inside you greater than any obstacle.",
    "The only way to achieve the impossible is to believe it is possible.",
    "Stay consistent and disciplined, and success will follow.",
    "Don’t watch the clock; do what it does. Keep going!"
  ];

  String get _randomQuote => _quotes[Random().nextInt(_quotes.length)];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _tasks = prefs.getStringList('tasks') ?? [];
    });
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('tasks', _tasks);
  }

  void _addTask() {
    if (_taskController.text.isNotEmpty) {
      setState(() {
        _tasks.add(_taskController.text);
        _taskController.clear();
      });
      _saveTasks();
      Navigator.pop(context);
    }
  }

  void _removeTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
    _saveTasks();
  }

  void _navigateToTimer(String task) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => TimerScreen(tasks: _tasks, selectedTask: task)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: Color(0xFFA31D1D),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  bottom: -30,
                  right: 10,
                  child: Opacity(
                    opacity: 0.2,
                    child: Icon(
                      Icons.format_quote,
                      size: 120,
                      color: Colors.white,
                    ),
                  ),
                ),
                Positioned(
                  top: -10,
                  left: 10,
                  child: Opacity(
                    opacity: 0.2,
                    child: Transform.rotate(
                      angle: pi,
                      child: Icon(
                        Icons.format_quote,
                        size: 120,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 40),
                    Text(
                      'Quote of the Day',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    Center(
                      child: Text(
                        _randomQuote,
                        style: TextStyle(
                          fontSize: 22,
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tasks',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6D2323),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                return Dismissible(
                  key: Key(_tasks[index]),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    color: Colors.red,
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    _removeTask(index);
                  },
                  child: GestureDetector(
                    onTap: () {
                      _navigateToTimer(_tasks[index]);
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFFE5D0AC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.access_time, color: Color(0xFFA31D1D)),
                              SizedBox(width: 10),
                              Text(
                                _tasks[index],
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFFA31D1D),
                                ),
                              ),
                            ],
                          ),
                          Icon(Icons.play_arrow, color: Color(0xFFA31D1D)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFFA31D1D),
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              title:
                  Text('Add Task', style: TextStyle(color: Color(0xFFA31D1D))),
              content: TextField(
                controller: _taskController,
                decoration: InputDecoration(hintText: 'Enter a task'),
              ),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFA31D1D)),
                  onPressed: _addTask,
                  child: Text('Add', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
