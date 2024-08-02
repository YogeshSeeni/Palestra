import 'package:flutter/material.dart';
import '../models/exercise.dart';

class AddExerciseDialog extends StatelessWidget {
  final Function(ExerciseInfo) onAdd;

  const AddExerciseDialog({required this.onAdd, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController primaryMusclesController = TextEditingController();
    final TextEditingController secondaryMusclesController = TextEditingController();
    final TextEditingController techniqueController = TextEditingController();

    return AlertDialog(
      title: const Text('Add Exercise'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Exercise Title', hintText: 'Bench Press'),
            ),
            TextField(
              controller: primaryMusclesController,
              decoration: const InputDecoration(labelText: 'Primary Muscles', hintText: 'Pectoralis Major, Triceps Brachii'),
            ),
            TextField(
              controller: secondaryMusclesController,
              decoration: const InputDecoration(labelText: 'Secondary Muscles', hintText: 'Biceps Brachii, Latissimus Dorsi'),
            ),
            TextField(
              controller: techniqueController,
              decoration: const InputDecoration(labelText: 'Technique', hintText: 'Lie flat on a bench...'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final newExercise = ExerciseInfo(
              title: titleController.text,
              primaryMuscles: primaryMusclesController.text.split(',').map((s) => s.trim()).toList(),
              secondaryMuscles: secondaryMusclesController.text.split(',').map((s) => s.trim()).toList(),
              technique: techniqueController.text,
            );
            onAdd(newExercise);
            Navigator.of(context).pop();
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
