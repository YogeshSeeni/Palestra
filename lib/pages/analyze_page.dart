import 'package:Palestra/pages/analyze_exercise_page.dart';
import 'package:Palestra/services/session_firestore.dart';
import 'package:Palestra/util/workouts_per_week.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnalyzePage extends StatefulWidget {
  const AnalyzePage({super.key});

  @override
  State<AnalyzePage> createState() => _AnalyzePageState();
}

class _AnalyzePageState extends State<AnalyzePage> {
  User? currentUser;
  SessionFirestore? sessionFirestore;
  Future<List<String>>? uniqueExercisesFuture;

  @override
  void initState() {
    super.initState();
    refreshUser();
  }

  void refreshUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
      currentUser = FirebaseAuth.instance.currentUser;
      sessionFirestore = SessionFirestore(userID: currentUser!.uid);

      setState(() {
        uniqueExercisesFuture = sessionFirestore?.getNonTemplateSessionStream().first.then((snapshot) {
          Set<String> uniqueExercises = {};
          for (var doc in snapshot.docs) {
            List<dynamic> exercises = doc['exercises'];
            for (var exercise in exercises) {
              uniqueExercises.add(exercise['title']);
            }
          }
          return uniqueExercises.toList();
        });
      });
    }
  }

  void _showExerciseSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select an Exercise'),
          content: SizedBox(
            width: double.maxFinite,
            child: FutureBuilder<List<String>>(
              future: uniqueExercisesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No exercises found'));
                } else {
                  List<String> uniqueExercises = snapshot.data!;
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: uniqueExercises.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(uniqueExercises[index]),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AnalyzeExercisePage(
                                exerciseName: uniqueExercises[index],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Analyze",
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const WorkoutsPerWeekCard(),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _showExerciseSelectionDialog,
              child: const Text(
                'Perform an AI-powered analysis on an exercise',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}