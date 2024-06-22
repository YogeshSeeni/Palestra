import 'package:Palestra/components/exercise_list_dialog.dart';
import 'package:Palestra/components/exercise_tile.dart';
import 'package:Palestra/data/workout_data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SessionPage extends StatefulWidget {
  final String sessionName;
  const SessionPage({super.key, required this.sessionName});

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  void createNewExercise() {
    showDialog(
      context: context,
      builder: (context) => ExerciseListDialog(
        sessionName: widget.sessionName,
        onExerciseAdded: (exerciseTitle) {
          setState(() {
            Provider.of<WorkoutData>(context, listen: false).addExercise(
              widget.sessionName,
              exerciseTitle,
              '',
              '',
              '',
            );
          });
        },
      ),
    );
  }

  void removeExerciseTile(String exerciseName) {
    Provider.of<WorkoutData>(context, listen: false)
        .removeExercise(widget.sessionName, exerciseName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(
          widget.sessionName,
          style: const TextStyle(fontSize: 24),
        ),
        actions: [
          IconButton(onPressed: saveSession, icon: Icon(Icons.save))
        ],
        backgroundColor: Colors.grey[200],
      ),
      body: Consumer<WorkoutData>(
        builder: (context, workoutData, child) {
          final workout = workoutData.getRelevantWorkout(widget.sessionName);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    "Track Workout",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: createNewExercise,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 15),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.add, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Add New Exercise'),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: workout.exercises.isNotEmpty
                      ? ListView.builder(
                          itemCount: workout.exercises.length,
                          itemBuilder: (context, index) {
                            final exercise = workout.exercises[index];
                            return ExerciseTile(
                              exerciseName: exercise.name,
                              onRemove: () => removeExerciseTile(exercise.name),
                            );
                          },
                        )
                      : const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('No exercises added yet.'),
                              SizedBox(height: 240),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void saveSession() {
  }
}
