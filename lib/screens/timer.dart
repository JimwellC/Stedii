import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

class TimerScreen extends StatefulWidget {
  final List<String> tasks;
  final String? selectedTask;
  const TimerScreen({Key? key, required this.tasks, this.selectedTask}) : super(key: key);

  @override
  TimerScreenState createState() => TimerScreenState();
}

class TimerScreenState extends State<TimerScreen> {
  int _seconds = 3;
  final int _breakDuration = 15;
  bool _isRunning = false;
  bool _isBreak = false;
  Timer? _timer;
  String? _selectedTask;
  int _pomodoroCount = 0;
  final int _maxPomodoros = 4;
  final AudioPlayer _lofiPlayer = AudioPlayer();
  final AudioPlayer _alarmPlayer = AudioPlayer();
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _lofiPlayer.setReleaseMode(ReleaseMode.loop);
    _lofiPlayer.setSource(AssetSource('sounds/lofi.mp3')); // preload lofi audio
    _lofiPlayer.setVolume(_isMuted ? 0.0 : 1.0);
    _alarmPlayer.setVolume(_isMuted ? 0.0 : 1.0);
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedTask = widget.selectedTask ?? prefs.getString('last_selected_task');
    });
  }

  Future<void> _saveSelectedTask(String task) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('last_selected_task', task);
  }

  void _startTimer() {
    if (_timer != null) {
      _timer!.cancel();
    }
    _isRunning = true;

    if (!_isBreak) {
      _lofiPlayer.resume();
    }

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_seconds > 0) {
          _seconds--;
        } else {
          _timer!.cancel();
          _isRunning = false;

          if (!_isBreak) {
            _pomodoroCount++;
          }

          if (_pomodoroCount >= _maxPomodoros && !_isBreak) {
            _showLongBreakDialog();
          } else {
            _toggleBreak();
            _startTimer();
          }
        }
      });
    });
  }

  void _pauseTimer() {
    if (_timer != null) {
      _timer!.cancel();
    }
    _lofiPlayer.stop();
    _alarmPlayer.stop();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _lofiPlayer.stop();
    _alarmPlayer.stop();
    setState(() {
      _seconds = _isBreak ? _breakDuration : 3;
      _isRunning = false;
      if (_timer != null) {
        _timer!.cancel();
      }
    });
  }

  void _toggleBreak() {
    setState(() {
      _isBreak = !_isBreak;
      _seconds = _isBreak ? _breakDuration : 3;

      if (_isBreak) {
        _lofiPlayer.pause();
        _alarmPlayer.play(AssetSource('sounds/alarm.mp3'));
      } else {
        _alarmPlayer.stop();
        _lofiPlayer.resume();
      }
    });
  }

  void _showLongBreakDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Pomodoro Complete!'),
        content: Text('Take a 20-minute break?\nDo you want to start another cycle?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _pomodoroCount = 0; // Reset for new cycle
                _isBreak = true;
                _seconds = 10; // 20 minutes
              });
              _startTimer();
            },
            child: Text('Yes'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _pomodoroCount = 0;
                _isRunning = false;
              });
            },
            child: Text('No'),
          ),
        ],
      ),
    );
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _lofiPlayer.setVolume(_isMuted ? 0.0 : 1.0);
      _alarmPlayer.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return "$minutes:${remainingSeconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFEF9E1),
      appBar: AppBar(
        title: Text('Timer'),
        backgroundColor: Color(0xFFA31D1D),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                color: Color(0xFFE5D0AC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedTask,
                  icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                  isExpanded: true,
                  style: TextStyle(fontSize: 18, color: Colors.white),
                  dropdownColor: Color(0xFFA31D1D),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedTask = newValue;
                      _saveSelectedTask(newValue!);
                    });
                  },
                  items: widget.tasks.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: TextStyle(color: Colors.black)),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Stay Stedii & Let’s Study!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF6D2323)),
          ),
          SizedBox(height: 20),
          Text(
            _formatTime(_seconds),
            style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: Color(0xFFA31D1D)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _maxPomodoros,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Text(
                  '🍅',
                  style: TextStyle(
                    fontSize: 24,
                    color: index < _pomodoroCount ? Color(0xFFA31D1D) : Colors.black26,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.replay, size: 30, color: Color(0xFFA31D1D)),
                onPressed: _resetTimer,
              ),
              SizedBox(width: 40),
              FloatingActionButton(
                backgroundColor: Color(0xFFE5D0AC),
                child: Icon(_isRunning ? Icons.pause : Icons.play_arrow, color: Color(0xFFA31D1D)),
                onPressed: _isRunning ? _pauseTimer : _startTimer,
              ),
              SizedBox(width: 40),
              IconButton(
                icon: Icon(
                  _isMuted ? Icons.volume_off : Icons.volume_up,
                  size: 30,
                  color: Color(0xFFA31D1D),
                ),
                onPressed: _toggleMute,
              ),
            ],
          ),
        ],
      ),
    );
  }
}