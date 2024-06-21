import 'package:flutter/material.dart';

class Exercise {
  final String name;
  final String weight;
  final String sets;
  final String reps;

  Exercise({
    required this.name,
    required this.weight,
    required this.sets,
    required this.reps,
  });
}

class Workout {
  final String name;
  List<Exercise> exercises;

  Workout({
    required this.name,
    required this.exercises,
  });
}

class WorkoutData extends ChangeNotifier {
  final List<Workout> _workouts = [];

  List<Workout> get workouts => _workouts;

  void addSession(String name) {
    // add a new session with a blank list of exercises
  }

  void addWorkout(String name) {
    _workouts.add(Workout(name: name, exercises: []));
    notifyListeners();
  }

  void addExercise(String workoutName, String name, String weight, String sets, String reps) {
    final workout = _workouts.firstWhere((workout) => workout.name == workoutName, orElse: () {
      Workout newWorkout = Workout(name: workoutName, exercises: []);
      _workouts.add(newWorkout);
      return newWorkout;
    });
    workout.exercises.add(Exercise(name: name, weight: weight, sets: sets, reps: reps));
    notifyListeners();
  }

  void removeExercise(String workoutName, String exerciseName) {
    try {
      final workout = _workouts.firstWhere((workout) => workout.name == workoutName);
      workout.exercises.removeWhere((exercise) => exercise.name == exerciseName);
      notifyListeners();
    } catch (e) {
      // Handle the case where the workout is not found
      // Optionally, you can print the error or handle it accordingly
      print('Workout not found: $workoutName');
    }
  }

  Workout getRelevantWorkout(String workoutName) {
    return _workouts.firstWhere(
      (workout) => workout.name == workoutName,
      orElse: () {
        Workout newWorkout = Workout(name: workoutName, exercises: []);
        _workouts.add(newWorkout);
        return newWorkout;
      },
    );
  }
}
