import 'package:flutter/material.dart';

class HabitTrackerCard extends StatefulWidget {
  final HabitType initialHabitType;
  final bool initialReminderEnabled;
  final Function(bool)? onToggleReminder;
  final Function()? onIncrementHabit;

  const HabitTrackerCard({
    super.key,
    this.initialHabitType = HabitType.water,
    this.initialReminderEnabled = true,
    this.onToggleReminder,
    this.onIncrementHabit,
  });

  @override
  State<HabitTrackerCard> createState() => _HabitTrackerCardState();
}

class _HabitTrackerCardState extends State<HabitTrackerCard> {
  late HabitType _habitType;
  late bool _habitReminderEnabled;
  bool _habitDone = false;
  bool _celebrate = false;
  int _habitCount = 3;
  int _habitGoal = 8;
  String _habitTitle = "Drink water";
  double _habitProgress = 0.375; // 3/8
  double _sleepHours = 7.5;
  int _sleepDaysStreak = 5;

  @override
  void initState() {
    super.initState();
    _habitType = widget.initialHabitType;
    _habitReminderEnabled = widget.initialReminderEnabled;
    _updateHabitValues();
  }

  void _updateHabitValues() {
    switch (_habitType) {
      case HabitType.water:
        _habitCount = 3;
        _habitGoal = 8;
        _habitTitle = "Drink water";
        break;
      case HabitType.sleep:
        _habitCount = _sleepDaysStreak;
        _habitGoal = 7;
        _habitTitle = "Sleep well";
        break;
      case HabitType.exercise:
        _habitCount = 2;
        _habitGoal = 5;
        _habitTitle = "Workout";
        break;
      case HabitType.meditation:
        _habitCount = 4;
        _habitGoal = 7;
        _habitTitle = "Meditate";
        break;
      case HabitType.reading:
        _habitCount = 50;
        _habitGoal = 100;
        _habitTitle = "Read pages";
        break;
    }
    _habitProgress = _habitCount / _habitGoal;
  }

  void _toggleHabit(bool value) {
    setState(() {
      _habitReminderEnabled = value;
      if (!value) _habitDone = false;
    });
    widget.onToggleReminder?.call(value);
  }

  void _incrementHabit() {
    setState(() {
      if (_habitCount < _habitGoal) {
        _habitCount++;
        _habitProgress = _habitCount / _habitGoal;
        if (_habitCount == _habitGoal) {
          _habitDone = true;
          _celebrate = true;
          Future.delayed(const Duration(seconds: 2), () {
            setState(() => _celebrate = false);
          });
        }
      }
    });
    widget.onIncrementHabit?.call();
  }

  void _changeHabitType(HabitType type) {
    setState(() {
      _habitType = type;
      _habitDone = false;
      _celebrate = false;
      _updateHabitValues();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _habitReminderEnabled && !_habitDone;
    final isCompleted = _habitReminderEnabled && _habitDone;
    final habitData = _getHabitData(_habitType);
    final glowColor = _habitDone
        ? habitData.completedColor
        : habitData.activeColor;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (_celebrate)
            BoxShadow(
              color: glowColor.withOpacity(0.35),
              blurRadius: 24,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isCompleted
                ? habitData.completedColor.withOpacity(0.6)
                : isActive
                ? habitData.activeColor.withOpacity(0.4)
                : Colors.grey.withOpacity(0.3),
            width: (isActive || isCompleted) ? 1.5 : 1,
          ),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: isCompleted
                  ? [
                      habitData.completedColor.withOpacity(0.15),
                      habitData.secondaryColor.withOpacity(0.12),
                    ]
                  : [
                      habitData.primaryColor.withOpacity(
                        isActive ? 0.12 : 0.08,
                      ),
                      habitData.secondaryColor.withOpacity(
                        isActive ? 0.15 : 0.10,
                      ),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with habit type selector
              Row(
                children: [
                  // Habit icon with type dropdown
                  PopupMenuButton<HabitType>(
                    itemBuilder: (context) => HabitType.values.map((type) {
                      final data = _getHabitData(type);
                      return PopupMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            Icon(data.icon, color: data.activeColor),
                            const SizedBox(width: 10),
                            Text(data.title),
                          ],
                        ),
                      );
                    }).toList(),
                    onSelected: _changeHabitType,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(isActive ? 0.9 : 0.7),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        habitData.icon,
                        color: isCompleted
                            ? habitData.completedColor
                            : isActive
                            ? habitData.activeColor
                            : Colors.grey,
                        size: 24,
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      habitData.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: isCompleted
                            ? habitData.completedColor
                            : isActive
                            ? Colors.blueGrey[900]
                            : Colors.grey[700],
                      ),
                    ),
                  ),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch.adaptive(
                      value: _habitReminderEnabled,
                      activeColor: habitData.activeColor,
                      onChanged: _toggleHabit,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Habit-specific content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Custom content based on habit type
                  _buildHabitContent(habitData),

                  const SizedBox(height: 14),

                  // Action button
                  SizedBox(
                    width: double.infinity,
                    child: AnimatedScale(
                      scale: isActive ? 1.0 : 0.95,
                      duration: const Duration(milliseconds: 200),
                      child: AnimatedOpacity(
                        opacity: isActive ? 1.0 : 0.6,
                        duration: const Duration(milliseconds: 200),
                        child: ElevatedButton.icon(
                          icon: Icon(habitData.actionIcon, size: 20),
                          label: Text(
                            _habitDone ? "Completed!" : habitData.actionText,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _habitDone
                                ? habitData.completedColor
                                : habitData.activeColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 2,
                            shadowColor: glowColor.withOpacity(0.5),
                          ),
                          onPressed: isActive ? _incrementHabit : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHabitContent(HabitData habitData) {
    final isActive = _habitReminderEnabled && !_habitDone;

    switch (_habitType) {
      case HabitType.water:
      case HabitType.exercise:
      case HabitType.meditation:
      case HabitType.reading:
        return Column(
          children: [
            Row(
              children: [
                Text(
                  _habitTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.blueGrey[800] : Colors.grey[600],
                  ),
                ),
                const Spacer(),
                if (_habitReminderEnabled)
                  GestureDetector(
                    onTap: () => _showHabitGoalPicker(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: habitData.activeColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        "$_habitCount/$_habitGoal",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: habitData.activeColor,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildProgressBar(habitData),
          ],
        );
      case HabitType.sleep:
        return Column(
          children: [
            Row(
              children: [
                Text(
                  "Last night: ${_sleepHours.toStringAsFixed(1)} hours",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.blueGrey[800] : Colors.grey[600],
                  ),
                ),
                const Spacer(),
                if (_habitReminderEnabled)
                  GestureDetector(
                    onTap: () => _showHabitGoalPicker(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: habitData.activeColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        "$_sleepDaysStreak day streak",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: habitData.activeColor,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildProgressBar(habitData),
          ],
        );
    }
  }

  Widget _buildProgressBar(HabitData habitData) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        height: 12,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutQuint,
                  width: constraints.maxWidth * _habitProgress,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _habitReminderEnabled && _habitDone
                          ? [habitData.completedColor, habitData.secondaryColor]
                          : !_habitReminderEnabled
                          ? [Colors.grey.shade400, Colors.grey.shade600]
                          : [habitData.activeColor, habitData.primaryColor],
                    ),
                  ),
                );
              },
            ),
            if (_habitProgress > 0.3)
              Positioned.fill(
                child: Center(
                  child: Text(
                    "${(_habitProgress * 100).round()}%",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showHabitGoalPicker(BuildContext context) async {
    final newGoal = await showDialog<int>(
      context: context,
      builder: (context) {
        int tempGoal = _habitGoal;
        return AlertDialog(
          title: Text("Set ${_getHabitData(_habitType).title} Goal"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "New goal",
                  suffixText: _habitType == HabitType.water
                      ? "glasses"
                      : _habitType == HabitType.reading
                      ? "pages"
                      : "times",
                ),
                onChanged: (value) =>
                    tempGoal = int.tryParse(value) ?? tempGoal,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, tempGoal),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );

    if (newGoal != null && newGoal > 0) {
      setState(() {
        _habitGoal = newGoal;
        _habitProgress = _habitCount / _habitGoal;
        if (_habitCount >= _habitGoal) {
          _habitDone = true;
        } else {
          _habitDone = false;
        }
      });
    }
  }

  HabitData _getHabitData(HabitType type) {
    switch (type) {
      case HabitType.water:
        return HabitData(
          title: "Hydration",
          icon: Icons.water_drop_rounded,
          actionIcon: Icons.add_rounded,
          actionText: "Add Glass",
          activeColor: Colors.blueAccent,
          completedColor: Colors.greenAccent,
          primaryColor: Colors.blue,
          secondaryColor: Colors.purple,
        );
      case HabitType.sleep:
        return HabitData(
          title: "Sleep",
          icon: Icons.bedtime_rounded,
          actionIcon: Icons.nightlight_round,
          actionText: "Log Sleep",
          activeColor: Colors.indigoAccent,
          completedColor: Colors.tealAccent,
          primaryColor: Colors.indigo,
          secondaryColor: Colors.deepPurple,
        );
      case HabitType.exercise:
        return HabitData(
          title: "Exercise",
          icon: Icons.directions_run_rounded,
          actionIcon: Icons.fitness_center_rounded,
          actionText: "Log Workout",
          activeColor: Colors.orangeAccent,
          completedColor: Colors.redAccent,
          primaryColor: Colors.orange,
          secondaryColor: Colors.red,
        );
      case HabitType.meditation:
        return HabitData(
          title: "Meditation",
          icon: Icons.self_improvement_rounded,
          actionIcon: Icons.timer_rounded,
          actionText: "Start Session",
          activeColor: Colors.purpleAccent,
          completedColor: Colors.deepPurpleAccent,
          primaryColor: Colors.purple,
          secondaryColor: Colors.deepPurple,
        );
      case HabitType.reading:
        return HabitData(
          title: "Reading",
          icon: Icons.menu_book_rounded,
          actionIcon: Icons.bookmark_add_rounded,
          actionText: "Add Pages",
          activeColor: Colors.brown,
          completedColor: Colors.amber,
          primaryColor: Colors.brown,
          secondaryColor: Colors.amber,
        );
    }
  }
}

enum HabitType { water, sleep, exercise, meditation, reading }

class HabitData {
  final String title;
  final IconData icon;
  final IconData actionIcon;
  final String actionText;
  final Color activeColor;
  final Color completedColor;
  final Color primaryColor;
  final Color secondaryColor;

  const HabitData({
    required this.title,
    required this.icon,
    required this.actionIcon,
    required this.actionText,
    required this.activeColor,
    required this.completedColor,
    required this.primaryColor,
    required this.secondaryColor,
  });
}
