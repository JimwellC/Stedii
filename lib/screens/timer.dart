import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:stedii/screens/progress-history.dart';
import 'dart:convert';

class TimerScreen extends StatefulWidget {
  final List<String> tasks;
  final String? selectedTask;
  final Function(bool)? onTimerRunningChanged;
  const TimerScreen(
      {Key? key,
      required this.tasks,
      this.selectedTask,
      this.onTimerRunningChanged})
      : super(key: key);

  @override
  TimerScreenState createState() => TimerScreenState();
}

class TimerScreenState extends State<TimerScreen> with WidgetsBindingObserver {
  int _seconds = 5;
  final int _breakDuration = 5;
  bool _isRunning = false;
  bool _isBreak = false;
  Timer? _timer;
  String? _selectedTask;
  int _pomodoroCount = 0;
  int _completedCycles = 0;
  final int _maxPomodoros = 4;
  final AudioPlayer _lofiPlayer = AudioPlayer();
  final AudioPlayer _alarmPlayer = AudioPlayer();
  bool _isMuted = false;
  final List<String> _breakChallenges = [
    "💪 Do 10 jumping jacks!",
    "🧘 Take 5 deep breaths.",
    "💧 Drink a glass of water.",
    "📴 Look away from the screen for 1 min.",
    "🧍‍♂️ Stretch your arms and legs.",
    "✍️ Write down one thing you learned.",
  ];
  String? _currentChallenge;
  BuildContext? _challengeDialogContext;
  bool _wasPausedDuringBreak = false; // Added field

// FOR HISTORY - KUMI
  List<String> _tasks = [];
  int _totalElapsedTime = 0;

  @override
  void initState() {
    super.initState();
    _loadElapsedTime();
    SharedPreferences.getInstance().then((prefs) {
      final isBreak = prefs.getBool('resume_isBreak') ?? false;
      final endTimeStr = prefs.getString('resume_endTime');
      if (isBreak && endTimeStr != null) {
        final endTime = DateTime.tryParse(endTimeStr);
        if (endTime != null) {
          final remaining = endTime.difference(DateTime.now()).inSeconds;
          if (remaining > 0) {
            setState(() {
              _isBreak = true;
              _seconds = remaining;
              _isRunning = true;
            });
            _startTimer();
          } else {
            prefs.remove('resume_isBreak');
            prefs.remove('resume_endTime');
          }
        }
      }
    });
    WidgetsBinding.instance.addObserver(this);
    _loadTasks();
    if (_wasPausedDuringBreak) {
      setState(() {
        _isBreak = true;
        _seconds = _breakDuration;
        _isRunning = false;
        _wasPausedDuringBreak = false;
      });
    }
    _loadPomodoroCount(); // Load the saved pomodoro count
    _lofiPlayer.setReleaseMode(ReleaseMode.loop);
    _lofiPlayer.setSource(AssetSource('sounds/lofi.mp3')); // preload lofi audio
    _lofiPlayer.setVolume(_isMuted ? 0.0 : 1.0);
    _alarmPlayer.setVolume(_isMuted ? 0.0 : 1.0);
  }

//  added by Kumi start
  void _loadElapsedTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int savedTime = prefs.getInt('totalElapsedTime') ?? 0;

    // ✅ Prevent loading incorrect old time
    if (savedTime < 0) {
      savedTime = 0;
      await prefs.setInt('totalElapsedTime', 0);
    }

    print("Loaded elapsed time in HistoryProgressScreen: $savedTime");

    setState(() {
      _totalElapsedTime = savedTime;
    });
  }
//  added by Kumi end

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    // _lofiPlayer.dispose();
    // _alarmPlayer.dispose();

    if (_isRunning && !_isBreak) {
      _timer?.cancel();
      _isRunning = false;
    }

    super.dispose();
  }

  //  added by Katerisse; start
  Future<void> _saveSessionHistory(int duration) async {
    final prefs = await SharedPreferences.getInstance();
    final String today = DateTime.now().toIso8601String().split("T")[0];

    // Get existing records
    List<String> history = prefs.getStringList('study_sessions') ?? [];

    // Add new record
    history.add(jsonEncode({'date': today, 'timeSpent': duration}));

    await prefs.setStringList('study_sessions', history);
  }
//  added by Katerisse; end

//  updated by Kumi start
  Future<void> _loadTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _tasks = prefs.getStringList('tasks') ?? []; // Load all tasks

      // If _selectedTask is not in the new list, reset it to null
      if (_selectedTask != null && !_tasks.contains(_selectedTask)) {
        _selectedTask = null;
      }
    });
  }
  //  updated by Kumi end

  Future<void> _loadPomodoroCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pomodoro_count', 0); // Reset count every launch
    setState(() {
      _pomodoroCount = 0;
    });
  }

  Future<void> _saveSelectedTask(String task) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('last_selected_task', task);
  }

//  updated by Kumi start
  void _startTimer() {
    if (_selectedTask == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please select a task before starting the timer."),
          backgroundColor: Color(0xFFA31D1D),
        ),
      );
      return;
    }

    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('resume_isBreak', _isBreak);
      if (_isBreak) {
        final endTime = DateTime.now().add(Duration(seconds: _seconds));
        prefs.setString('resume_endTime', endTime.toIso8601String());
      }
    });

    if (!_isBreak) {
      // ✅ Play Lofi Music during work time
      _lofiPlayer.play(AssetSource('sounds/lofi.mp3'));
    }

    if (_timer != null) {
      _timer!.cancel();
    }

    _isRunning = true;
    widget.onTimerRunningChanged?.call(true);

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      final remaining = _seconds - 1;

      if (remaining > 0) {
        setState(() {
          _seconds = remaining;
          _totalElapsedTime++;
          print("Elapsed Time: $_totalElapsedTime seconds");
        });
      } else {
        _timer!.cancel();
        _isRunning = false;
        widget.onTimerRunningChanged?.call(false);

        SharedPreferences.getInstance().then((prefs) {
          prefs.remove('resume_isBreak');
          prefs.remove('resume_endTime');
          prefs.setInt('totalElapsedTime', _totalElapsedTime);
          print("Saved Elapsed Time: $_totalElapsedTime seconds");
        });

        if (_isBreak) {
          _alarmPlayer.stop();
          _lofiPlayer.play(AssetSource('sounds/lofi.mp3'));
          _toggleBreak();
          _startTimer();
        } else {
          _pomodoroCount++;
          _savePomodoroCount();

          if (_pomodoroCount >= _maxPomodoros) {
            _completedCycles++;
            _showLongBreakDialog();
            return;
          }

          _toggleBreak();
          _startTimer();
        }
      }
    });
  }
//  updated by Kumi end

  void _resetTimer() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('resume_isBreak');
      prefs.remove('resume_endTime');
    });
    _lofiPlayer.stop();
    _alarmPlayer.stop();
    setState(() {
      _seconds = 0;
      _isRunning = false;
      widget.onTimerRunningChanged?.call(false);
      if (_timer != null) {
        _timer!.cancel();
      }
    });
  }

//  updated by Kumi start
  void _toggleBreak() {
    setState(() {
      _isBreak = !_isBreak;
      _seconds = _isBreak ? _breakDuration : 5;

      if (_isBreak) {
        // Pick a random challenge for break time
        final random = (_breakChallenges.toList()..shuffle());
        _currentChallenge = random.firstWhere(
          (challenge) => challenge != _currentChallenge,
          orElse: () => random.first,
        );

        // Show break challenge dialog
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showGeneralDialog(
            context: context,
            barrierDismissible: true,
            barrierLabel:
                MaterialLocalizations.of(context).modalBarrierDismissLabel,
            barrierColor: Colors.black45,
            transitionDuration: Duration(milliseconds: 500),
            pageBuilder: (BuildContext dialogContext,
                Animation<double> animation,
                Animation<double> secondaryAnimation) {
              _challengeDialogContext = dialogContext;
              return Center(
                child: AlertDialog(
                  backgroundColor: Color(0xFF712B2B),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  content: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      _currentChallenge!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
            transitionBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(0, -1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                )),
                child: child,
              );
            },
          );
        });

        // ✅ Stop lofi and play break alarm
        _lofiPlayer.pause();
        _alarmPlayer
            .stop(); // Ensure previous alarm stops before playing a new one
        _alarmPlayer.play(AssetSource('sounds/alarm.mp3'));
      } else {
        _currentChallenge = null;

        // ✅ Stop alarm and resume lofi music
        _alarmPlayer.stop();
        _lofiPlayer.play(
            AssetSource('sounds/lofi.mp3')); // Use play() instead of resume()

        // Close challenge dialog if open
        if (_challengeDialogContext != null && mounted) {
          try {
            Navigator.of(_challengeDialogContext!).pop();
          } catch (_) {}
          _challengeDialogContext = null;
        }
      }
    });
  }

//  updated by Kumi end

//  updated/added by Kumi start
  void _onTaskComplete(String taskName, int completedCycles) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // ✅ Save the elapsed time
    await prefs.setInt('totalElapsedTime', _totalElapsedTime);

    List<String> completedTasks = prefs.getStringList('completedTasks') ?? [];
    Map<String, dynamic> taskData = {
      'name': taskName,
      'timeSpent': _totalElapsedTime + 2,
      'cyclesCompleted': completedCycles
    };

    completedTasks.add(json.encode(taskData));
    await prefs.setStringList('completedTasks', completedTasks);

    // ✅ Reset the elapsed time
    setState(() {
      _totalElapsedTime = 0;
    });
    await prefs.setInt('totalElapsedTime', 0);

    // ✅ Remove the completed task from home
    _removeTaskFromList(taskName);

    print("Task '$taskName' completed and removed.");

    // ✅ Navigate to History screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HistoryProgressScreen()),
    );
  }

  void _showLongBreakDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Pomodoro Complete!'),
        content: Text(
            'Take a 20-minute break?\nDo you want to start another cycle?'),
        actions: [
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              prefs.setInt('pomodoro_count', _pomodoroCount);
              Navigator.of(context).pop();

              setState(() {
                _pomodoroCount = 0;
                _isBreak = true;
                _seconds = 20;
              });

              if (_pomodoroCount >= _maxPomodoros) {
                _completedCycles++;
                _showCompletionDialog(); // ✅ Show completion dialog next
                return;
              }

              _startTimer();
            },
            child: Text('Yes'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              _lofiPlayer.stop();
              _alarmPlayer.stop();

              final prefs = await SharedPreferences.getInstance();
              await prefs.setInt('pomodoro_count', 0);
              await prefs.setInt('completed_tasks', _completedCycles);

              if (_pomodoroCount == 1) {
                await prefs.setInt('completed_tasks', 1);
              }

              setState(() {
                _pomodoroCount = 0;
                _isRunning = false;
                _isBreak = false;
                _seconds = 5;
                _currentChallenge = null;

                if (_challengeDialogContext != null && mounted) {
                  try {
                    Navigator.of(_challengeDialogContext!).pop();
                  } catch (_) {}
                  _challengeDialogContext = null;
                }
              });

              widget.onTimerRunningChanged?.call(false);

              _showCompletionDialog(); // ✅ Show completion dialog next
            },
            child: Text('No'),
          ),
        ],
      ),
    );
  }

// ✅ New function to handle the final completion dialog
  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Session Complete!'),
        content: Text(
            'You’ve completed $_completedCycles Pomodoro Cycles. Great job!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // ✅ Close dialog first

              if (_selectedTask != null) {
                _onTaskComplete(_selectedTask!, _completedCycles);
                _removeTaskFromList(_selectedTask!);
              }
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

// ✅ Function to remove task from the list
  void _removeTaskFromList(String taskName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> tasks = prefs.getStringList('tasks') ?? [];

    // ✅ Remove the task
    tasks.removeWhere((task) => task == taskName);
    await prefs.setStringList('tasks', tasks);

    // ✅ Update the UI immediately
    setState(() {});

    print("Task '$taskName' removed and UI updated.");
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
//  updated/added by Kumi end

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _lofiPlayer.setVolume(_isMuted ? 0.0 : 1.0);
    _alarmPlayer.setVolume(_isMuted ? 0.0 : 1.0);
  }

  // added by Katerisse pt. 4; start

  void _updateUI() {
    setState(() {}); // Triggers a UI update
  }
// added by Katerisse pt. 4; end

// added by Katerisse pt. 5; start
  void _saveTrackedTime(int newSeconds) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int currentTotal = prefs.getInt('total_seconds') ?? 0;
    prefs.setInt('total_seconds', currentTotal + newSeconds);
  }

// added by Katerisse pt. 5; end

  void _savePomodoroCount() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('pomodoro_count', _pomodoroCount);
    prefs.setInt('completed_tasks', _completedCycles);
    // added by Katerisse pt. 3; start
    DateTime now = DateTime.now();
    String today = "${now.year}-${now.month}-${now.day}";

    List<String> recordedDays = prefs.getStringList('recorded_days') ?? [];

    // Add today if not already recorded
    if (!recordedDays.contains(today)) {
      recordedDays.add(today);
    }
    prefs.setStringList('recorded_days', recordedDays);

    // Save total recorded hours
    int totalSeconds = prefs.getInt('total_seconds') ?? 0;
    totalSeconds += (25 * 60); // Assuming 25-minute Pomodoro
    prefs.setInt('total_seconds', totalSeconds);

    _updateUI(); // Call function to update the calendar display
  }
// added by Katerisse pt. 3; end

// added by Katerisse pt. 6; start
  String getFormattedTime(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
// added by Katerisse pt. 6; end

// added by Katerisse pt. 6; start

  String formatRecordedTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}";
  }
// added by Katerisse pt. 6; end

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return "$minutes:${remainingSeconds.toString().padLeft(2, '0')}";
  }

  @override
  Future<bool> didPopRoute() async {
    if (_isRunning) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("You can't leave while the timer is running."),
          backgroundColor: Color(0xFFA31D1D),
        ),
      );
      return true; // Prevent back navigation
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isRunning) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("You can't leave while the timer is running."),
              backgroundColor: Color(0xFFA31D1D),
            ),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Color(0xFFFEF9E1),
        appBar: AppBar(
          title: Text(
            'Timer',
            style: TextStyle(fontSize: 24),
          ),
          titleTextStyle: TextStyle(color: Colors.white),
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
                    items: widget.tasks
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child:
                            Text(value, style: TextStyle(color: Colors.black)),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            SizedBox(height: 30),
            Text(
              'Stay Stedii & Let’s Study!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF712B2B),
              ),
            ),
            SizedBox(height: 20),
            Container(
              width: 376,
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 50),
              decoration: BoxDecoration(
                color: Color(0xFFEADDC1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  _formatTime(_seconds),
                  style: TextStyle(
                    fontFamily: 'Digital',
                    fontSize: 150,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF712B2B),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
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
                      color: index < _pomodoroCount
                          ? Color(0xFFA31D1D)
                          : Colors.black26,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              width: 230,
              decoration: BoxDecoration(
                color: Color(0xFFF6EBD8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: !_isBreak ? Color(0xFF712B2B) : Colors.transparent,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      'Study Time',
                      style: TextStyle(
                        color: !_isBreak ? Colors.white : Color(0xFF712B2B),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isBreak ? Color(0xFF712B2B) : Colors.transparent,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      'Short Break',
                      style: TextStyle(
                        color: _isBreak ? Colors.white : Color(0xFF712B2B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 40),
                  child: Tooltip(
                    message: "Stay focused – no shortcuts!",
                    child: Icon(Icons.lock, color: Color(0xFFA31D1D)),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFEADDC1),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.play_arrow,
                      color: Color(0xFFA31D1D),
                      size: 60,
                    ),
                    onPressed: _isRunning ? null : _startTimer,
                  ),
                ),
                SizedBox(width: 40),
                IconButton(
                  icon: Icon(
                    _isMuted ? Icons.volume_off : Icons.volume_up,
                    color: Color(0xFFA31D1D),
                  ),
                  onPressed: _toggleMute,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
