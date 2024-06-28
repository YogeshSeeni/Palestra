import 'package:Palestra/services/exercise_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:Palestra/components/exercise_info_dialog.dart';
import '../models/exercise.dart';

class ExercisesPage extends StatelessWidget {
  // Exercise Firestore reference
  final ExerciseFirestore exerciseFirestore = ExerciseFirestore();

  ExercisesPage({super.key});

  void _showExerciseInfo(BuildContext context, ExerciseInfo exercise) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ExerciseInfoDialog(exercise: exercise);
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
                  child: Container(
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      "Exercise Library",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: exerciseList.length,
                    itemBuilder: (context, index) {
                      // Get each individual exercise doc
                      DocumentSnapshot document = exerciseList[index];
                      String docID = document.id;

                      // Get exercise from doc
                      ExerciseInfo exercise = ExerciseInfo.fromJson(document.data() as Map<String, dynamic>);

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
