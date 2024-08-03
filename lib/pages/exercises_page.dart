import 'package:Palestra/services/exercise_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:Palestra/components/exercise_info_dialog.dart';
import 'package:Palestra/components/add_exercise_dialog.dart';
import '../models/exercise.dart';

class ExercisesPage extends StatefulWidget {
  const ExercisesPage({super.key});

  @override
  _ExercisesPageState createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage> {
  final ExerciseFirestore exerciseFirestore = ExerciseFirestore();

  void _showExerciseInfo(BuildContext context, ExerciseInfo exercise) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ExerciseInfoDialog(exercise: exercise);
      },
    );
  }

  void _showAddExerciseDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddExerciseDialog(
          onAdd: (ExerciseInfo newExercise) {
            exerciseFirestore.addExercise(newExercise);
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Exercise"),
          content: Text("Are you sure you want to delete this exercise?"),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text("Delete"),
              onPressed: () {
                exerciseFirestore.deleteExercise(docId);
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: exerciseFirestore.getExercisesStream(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<DocumentSnapshot> exerciseList = snapshot.data!;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "Library",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text(
                          'Exercise',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black),
                        onPressed: _showAddExerciseDialog,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: exerciseList.length,
                    itemBuilder: (context, index) {
                      // Get each individual exercise doc
                      DocumentSnapshot document = exerciseList[index];

                      // Get exercise from doc
                      ExerciseInfo exercise = ExerciseInfo.fromJson(
                          document.data() as Map<String, dynamic>);

                      return ListTile(
                        title: Text(
                          exercise.title,
                          style: const TextStyle(fontSize: 18),
                        ),
                        subtitle: Text(
                          exercise.primaryMuscles.isNotEmpty ? exercise.primaryMuscles[0] : '',
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.grey[800]),
                          onPressed: () => _confirmDelete(context, document.id),
                        ),
                        tileColor: Colors.grey[200],
                        onTap: () {
                          _showExerciseInfo(context, exercise);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error loading exercises"));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
