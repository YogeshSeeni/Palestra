import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercise.dart';
import 'package:Palestra/services/exercise_firestore.dart';

class ExerciseListDialog extends StatelessWidget {
  final ExerciseFirestore exerciseFirestore = ExerciseFirestore();
  final String sessionName;
  final Function(String) onExerciseAdded;

  ExerciseListDialog({super.key, required this.sessionName, required this.onExerciseAdded});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Text(
                "Exercises",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: exerciseFirestore.getExercisesStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    List<DocumentSnapshot> exerciseList = snapshot.data!.docs;

                    if (exerciseList.isEmpty) {
                      return Center(child: Text("No Exercises"));
                    }

                    return ListView.builder(
                      itemCount: exerciseList.length,
                      itemBuilder: (context, index) {
                        DocumentSnapshot document = exerciseList[index];
                        String docID = document.id;

                        ExerciseInfo exerciseInfo = ExerciseInfo.fromJson(
                            document.data() as Map<String, dynamic>);

                        return ListTile(
                          title: Text(exerciseInfo.title),
                          subtitle: Text(exerciseInfo.primaryMuscles[0]),
                          trailing: IconButton(
                            onPressed: () {
                              onExerciseAdded(exerciseInfo.title);
                              Navigator.of(context).pop();
                            },
                            icon: Icon(Icons.add),
                          ),
                        );
                      },
                    );
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Error loading exercises"));
                  } else {
                    return Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
