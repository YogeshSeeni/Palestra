import 'package:flutter/material.dart';
import 'package:Palestra/util/workouts_per_week.dart';
import 'package:Palestra/util/exercise_analytics.dart';
import 'package:Palestra/components/exercise_list_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Palestra/services/session_firestore.dart';

class AnalyzePage extends StatefulWidget {
  const AnalyzePage({super.key});

  @override
  _AnalyzePageState createState() => _AnalyzePageState();
}

class _AnalyzePageState extends State<AnalyzePage> with AutomaticKeepAliveClientMixin {
  List<Widget> cards = [];

  @override
  bool get wantKeepAlive => true;

  void addWorkoutsPerWeekCard() {
    setState(() {
      cards.add(WorkoutsPerWeekCard(
        key: UniqueKey(),
        onRemove: () => removeCard(WorkoutsPerWeekCard),
      ));
    });
  }

  void addExerciseAnalyticsCard(String exercise, String metric) {
    _fetchExerciseDataCount(exercise).then((count) {
      if (count >= 3) {
        setState(() {
          cards.add(ExerciseAnalyticsCard(
            key: UniqueKey(),
            exercise: exercise,
            metric: metric,
            onRemove: () => removeCard(ExerciseAnalyticsCard),
          ));
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You need at least three sessions with this exercise to view its analytics.')),
        );
      }
    });
  }

  Future<int> _fetchExerciseDataCount(String exercise) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final sessionFirestore = SessionFirestore(userID: user.uid);
      List<Map<String, dynamic>> fetchedData = await sessionFirestore.fetchExerciseData(exercise);
      return fetchedData.length;
    }
    return 0;
  }

  void removeCard(Type cardType) {
    setState(() {
      cards.removeWhere((card) => card.runtimeType == cardType);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Analyze',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Widget',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                  onPressed: _showAddWidgetDialog,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                return cards[index];
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddWidgetDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Add Widget', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(),
                ListTile(
                  title: const Text('Workouts Per Week'),
                  subtitle: const Text('Display workout consistency'),
                  onTap: () {
                    addWorkoutsPerWeekCard();
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text('Exercise Analytics'),
                  subtitle: const Text('Track specific exercises'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    _showExerciseAnalyticsChoiceDialog();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showExerciseAnalyticsChoiceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Exercise Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(),
                ListTile(
                  title: const Text('1RM'),
                  subtitle: const Text('Track 1RM progression'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    String? exercise = await showDialog<String>(
                      context: context,
                      builder: (context) => ExerciseListDialog(
                        sessionName: 'sessionName',
                        onExerciseAdded: (exercise) {
                          addExerciseAnalyticsCard(exercise, "1RM");
                        },
                      ),
                    );
                  },
                ),
                ListTile(
                  title: const Text('Volume'),
                  subtitle: const Text('Track volume progression'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    String? exercise = await showDialog<String>(
                      context: context,
                      builder: (context) => ExerciseListDialog(
                        sessionName: 'sessionName',
                        onExerciseAdded: (exercise) {
                          addExerciseAnalyticsCard(exercise, "Volume");
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
