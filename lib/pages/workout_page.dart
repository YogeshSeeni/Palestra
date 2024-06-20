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
              decoration: InputDecoration(hintText: 'Exercise Name', focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black),), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black),),),
              
            ),
            TextField(
              controller: weightController,
              decoration: InputDecoration(hintText: 'Weight', focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black),), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black),),),
            ),
            TextField(
              controller: setsController,
              decoration: InputDecoration(hintText: 'Sets', focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black),), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black),),),
            ),
            TextField(
              controller: repsController,
              decoration: InputDecoration(hintText: 'Reps', focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black),), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black),),),
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
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Create Template",
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: createNewExercise,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, // Background color
                  foregroundColor: Colors.white, // Text color
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  textStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: Colors.white),
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
                            weight: exercise.weight,
                            reps: exercise.reps,
                            sets: exercise.sets,
                          );
                        },
                      )
                    : Center(
                        child: Column(
                          children: [
                            SizedBox(height: 240),
                            Text('No exercises added yet.'),
                          ],
                        )
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
