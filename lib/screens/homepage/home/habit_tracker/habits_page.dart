import 'package:flutter/material.dart';
import 'habit_tracker_card.dart';

class HabitsPage extends StatelessWidget {
  const HabitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const HabitTrackerCard(initialHabitType: HabitType.water),
        const SizedBox(height: 16),
        const HabitTrackerCard(initialHabitType: HabitType.sleep),
        const SizedBox(height: 16),
        const HabitTrackerCard(initialHabitType: HabitType.exercise),
        // Add more habit cards as needed
      ],
    );
  }
}
