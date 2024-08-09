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

      // Fetch unique exercises
      setState(() {
        uniqueExercisesFuture = sessionFirestore!.fetchUniqueExercises();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Analyze",
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
          ),
          WorkoutsPerWeekCard(),
          Expanded(
            child: FutureBuilder<List<String>>(
              future: uniqueExercisesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No exercises found'));
                } else {
                  List<String> uniqueExercises = snapshot.data!;
                  return ListView.builder(
                    itemCount: uniqueExercises.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(uniqueExercises[index]),
                        trailing: IconButton(
                          icon: Icon(Icons.arrow_forward),
                          onPressed: () {
                            // Navigate to the ExerciseDetailPage with the exercise name
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AnalyzeExercisePage(
                                  exerciseName: uniqueExercises[index],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
