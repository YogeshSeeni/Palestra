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
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Center(
                child: Text(
                  "Exercises",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: StreamBuilder<List<DocumentSnapshot>>(
                  stream: exerciseFirestore.getExercisesStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      List<DocumentSnapshot> exerciseList = snapshot.data!;
        
                      if (exerciseList.isEmpty) {
                        return const Center(child: Text("No Exercises"));
                      }
        
                      return ListView.builder(
                        itemCount: exerciseList.length,
                        itemBuilder: (context, index) {
                          DocumentSnapshot document = exerciseList[index];
                          ExerciseInfo exerciseInfo = ExerciseInfo.fromJson(
                              document.data() as Map<String, dynamic>);
                      
                          return ListTile(
                            title: Text(exerciseInfo.title),
                            subtitle: Text(exerciseInfo.primaryMuscles.isNotEmpty ? exerciseInfo.primaryMuscles[0] : 'No primary muscle'),
                            onTap: () {
                              onExerciseAdded(exerciseInfo.title);
                              Navigator.of(context).pop();
                            },
                            trailing: const Icon(Icons.add),
                          );
                        },
                      );
                    } else if (snapshot.hasError) {
                      return const Center(child: Text("Error loading exercises"));
                    } else {
                      return const Center(child: CircularProgressIndicator());
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
