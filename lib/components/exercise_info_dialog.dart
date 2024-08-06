import 'package:flutter/material.dart';
import '../models/exercise.dart';

class ExerciseInfoDialog extends StatelessWidget {
  final ExerciseInfo exercise;
  final bool isCustom;
  final Function()? onDelete;

  const ExerciseInfoDialog({
    super.key,
    required this.exercise,
    required this.isCustom,
    this.onDelete,
  });

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
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
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