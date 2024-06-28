import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercise.dart';
import 'package:Palestra/services/exercise_firestore.dart';

class ExerciseInfoDialog extends StatelessWidget {
  final ExerciseInfo exercise;
  ExerciseInfoDialog({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Text(
                    exercise.title,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              Text('Description: ${exercise.description}'),
              const SizedBox(height: 10),
              Text('Primary Muscles: ${exercise.primaryMuscles.join(', ')}'),
              const SizedBox(height: 10),
              Text('Secondary Muscles: ${exercise.secondaryMuscles.join(', ')}'),
              const SizedBox(height: 10),
              Text('Technique: ${exercise.technique}'),
            ],
          ),
        ),
      ),
    );
  }
}
