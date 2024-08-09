import 'package:flutter/material.dart';

class AnalyzeExercisePage extends StatelessWidget {
  final String exerciseName;

  const AnalyzeExercisePage({super.key, required this.exerciseName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(exerciseName),
      ),
      backgroundColor: Colors.grey[200],
      body: Center(
        child: Text(
          exerciseName,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
