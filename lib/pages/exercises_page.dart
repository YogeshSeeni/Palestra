import 'package:Palestra/services/exercise_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/exercise.dart';

class ExercisesPage extends StatelessWidget {
  //exercise firestore reference
  final ExerciseFirestore exerciseFirestore = ExerciseFirestore();

  ExercisesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: StreamBuilder<QuerySnapshot>(
        stream: exerciseFirestore.getExercisesStream(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List exerciseList = snapshot.data!.docs;

            return ListView.builder(
              itemCount: exerciseList.length,
              itemBuilder: (context, index) {
                //Get Each Individual Exercise Doc
                DocumentSnapshot document = exerciseList[index];
                String docID = document.id;

                // Get Exercise from Doc
                Exercise exercise = Exercise.fromJson(document.data() as Map<String, dynamic>);

                return ListTile(
                  title: Text(exercise.title),
                );
              },
            );
          } else {
            return const Text("No NOtes");
          }
        },
      ),
    );
  }
}