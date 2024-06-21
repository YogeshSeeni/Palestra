import 'package:Palestra/components/exercise_tile.dart';
import 'package:Palestra/data/workout_data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WorkoutPage extends StatefulWidget {
  final String workoutName;
  const WorkoutPage({super.key, required this.workoutName});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  final TextEditingController exerciseTitleController = TextEditingController();

  void createNewExercise() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Exercise Title'),
        content: TextField(
          controller: exerciseTitleController,
          decoration: const InputDecoration(hintText: "Exercise Title"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                String exerciseTitle = exerciseTitleController.text;
                if (exerciseTitle.isNotEmpty) {
                  Provider.of<WorkoutData>(context, listen: false).addExercise(
                    widget.workoutName,
                    exerciseTitle,
                    '', '', '',
                  );
                  exerciseTitleController.clear();
                }
              });
              Navigator.of(context).pop();
            },
            child: const Text('OK', style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              exerciseTitleController.clear();
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void removeExerciseTile(String exerciseName) {
    Provider.of<WorkoutData>(context, listen: false).removeExercise(widget.workoutName, exerciseName);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutData>(
      builder: (context, workoutData, child) {
        final workout = workoutData.getRelevantWorkout(widget.workoutName);
        return Scaffold(
          backgroundColor: Colors.grey[200],
          appBar: AppBar(
            title: Text(
              widget.workoutName,
              style: const TextStyle(fontSize: 24),
            ),
            backgroundColor: Colors.grey[200],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    "Template Editor",
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
          ),
        );
      },
    );
  }
}
