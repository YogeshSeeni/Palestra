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
  // Text controllers
  final exerciseNameController = TextEditingController();
  final weightController = TextEditingController();
  final setsController = TextEditingController();
  final repsController = TextEditingController();

  void createNewExercise() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add a new exercise'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: exerciseNameController,
              decoration: InputDecoration(hintText: 'Exercise Name'),
            ),
            TextField(
              controller: weightController,
              decoration: InputDecoration(hintText: 'Weight'),
            ),
            TextField(
              controller: setsController,
              decoration: InputDecoration(hintText: 'Sets'),
            ),
            TextField(
              controller: repsController,
              decoration: InputDecoration(hintText: 'Reps'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              saveExercise();
              Navigator.of(context).pop();
            },
            child: Text('Add', style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              clearControllers();
            },
            child: Text('Cancel', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void saveExercise() {
    Provider.of<WorkoutData>(context, listen: false).addExercise(
      widget.workoutName,
      exerciseNameController.text,
      weightController.text,
      setsController.text,
      repsController.text,
    );
    clearControllers();
  }

  void clearControllers() {
    exerciseNameController.clear();
    weightController.clear();
    setsController.clear();
    repsController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutData>(
      builder: (context, value, child) {
        final workout = value.getRelevantWorkout(widget.workoutName);
        return Scaffold(
          backgroundColor: Colors.grey[200],
          appBar: AppBar(
            title: Text(
              widget.workoutName,
              style: TextStyle(fontSize: 24),
            ),
            backgroundColor: Colors.grey[200],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.black,
            onPressed: createNewExercise,
            child: Icon(Icons.add, color: Colors.white),
          ),
          body: ListView.builder(
            itemCount: workout.exercises.length,
            itemBuilder: (context, index) {
              final exercise = workout.exercises[index];
              return ExerciseTile(
                exerciseName: exercise.name,
                weight: exercise.weight,
                reps: exercise.reps,
                sets: exercise.sets,
              );
            },
          ),
        );
      },
    );
  }
}
