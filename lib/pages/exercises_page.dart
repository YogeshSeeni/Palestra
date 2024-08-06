import 'package:Palestra/services/exercise_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:Palestra/components/exercise_info_dialog.dart';
import 'package:Palestra/components/add_exercise_dialog.dart';
import '../models/exercise.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExercisesPage extends StatefulWidget {
  const ExercisesPage({super.key});

  @override
  _ExercisesPageState createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage> {
  final ExerciseFirestore exerciseFirestore = ExerciseFirestore();

  @override
  void initState() {
    super.initState();
    _ensureCustomExercisesInitialized();
  }

  Future<void> _ensureCustomExercisesInitialized() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await initializeCustomExercises(user.uid);
    }
  }

  Future<void> initializeCustomExercises(String userId) async {
    final firestore = FirebaseFirestore.instance;
    final userDocRef = firestore.collection('users').doc(userId);
    
    // Check if the customExercises collection already exists
    final customExercisesCollection = await userDocRef.collection('customExercises').get();
    
    if (customExercisesCollection.docs.isEmpty) {
      // If it doesn't exist, create an empty document to initialize the collection
      await userDocRef.collection('customExercises').add({
        'initialized': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  void _showExerciseInfo(
      BuildContext context, ExerciseInfo exercise, bool isCustom) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ExerciseInfoDialog(
          exercise: exercise,
          isCustom: isCustom,
          onDelete:
              isCustom ? () => _confirmDelete(context, exercise.title) : null,
        );
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
          title: const Text("Delete Exercise"),
          content: const Text("Are you sure you want to delete this exercise?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text("Delete"),
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
                      DocumentSnapshot document = exerciseList[index];
                      Map<String, dynamic> data =
                          document.data() as Map<String, dynamic>;
                      ExerciseInfo exercise = ExerciseInfo.fromJson(data);
                      bool isCustom = data['isCustom'] ?? false;

                      return ListTile(
                        title: Text(
                          exercise.title,
                          style: const TextStyle(fontSize: 18),
                        ),
                        subtitle: Text(
                          exercise.primaryMuscles.isNotEmpty
                              ? exercise.primaryMuscles[0]
                              : '',
                        ),
                        trailing: isCustom
                            ? IconButton(
                                icon:
                                    Icon(Icons.delete, color: Colors.grey[800]),
                                onPressed: () =>
                                    _confirmDelete(context, document.id),
                              )
                            : null,
                        tileColor: Colors.grey[200],
                        onTap: () {
                          _showExerciseInfo(context, exercise, isCustom);
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
