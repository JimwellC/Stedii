import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stedii/screens/home.dart';
import 'package:stedii/screens/timer.dart';

void main() {
  runApp(StediiApp());
}

class StediiApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stedii: Study Break Timer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Color(0xFFA31D1D),
        scaffoldBackgroundColor: Color(0xFFFEF9E1),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  List<String> _tasks = [];
  String? _selectedTask;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _screens = [
      HomeScreen(),
      Placeholder(), // Challenges Screen
      Placeholder(), // History Screen
      TimerScreen(tasks: _tasks, selectedTask: null)
    ];
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _tasks = prefs.getStringList('tasks') ?? [];
      _selectedTask = null; // Default to no selection when opening Timer
      _updateTimerScreen();
    });
  }

  void _updateTimerScreen() {
    _screens[3] = TimerScreen(tasks: _tasks, selectedTask: _selectedTask);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 3) {
        _loadTasks(); // Ensure tasks update when navigating to Timer
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Color(0xFFE5D0AC),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 5,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: BottomNavigationBar(
            selectedItemColor: Color(0xFFA31D1D),
            unselectedItemColor: Color(0xFF6D2323),
            backgroundColor: Color(0xFFE5D0AC),
            type: BottomNavigationBarType.fixed,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
              BottomNavigationBarItem(icon: Icon(Icons.flag), label: ''),
              BottomNavigationBarItem(icon: Icon(Icons.history), label: ''),
              BottomNavigationBarItem(icon: Icon(Icons.timer), label: ''),
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
          ),
        ),
      ),
    );
  }
}