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
    // Implement the logic to show a dialog for adding an exercise
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddExerciseDialog(
          onAdd: (ExerciseInfo newExercise) {
            setState(() {
              // Add the new exercise to Firestore or the local list
              exerciseFirestore.addExercise(newExercise);
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: StreamBuilder<QuerySnapshot>(
        stream: exerciseFirestore.getExercisesStream(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<DocumentSnapshot> exerciseList = snapshot.data!.docs;

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
                        subtitle: Text(exercise.primaryMuscles[0]),
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
