import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../models/workout.dart';

class WorkoutData extends ChangeNotifier {
  /* 

  WORKOUT DATA STRUCTURE

  This overall list contains the different workouts
  Each workout has a name and list of exercises

  How to incorporate exercise progress? Perhaps exercise data structure?

  */

  List<Workout> workoutList = [
    // default workout
    Workout(name: "Upper Body", exercises: [
      Exercise(
        name: "Bicep Curls",
        weight: "10",
        reps: "10",
        sets: "3",
      ),
    ]),

    Workout(name: "Lower Body", exercises: [
      Exercise(
        name: "Bicep Curls",
        weight: "10",
        reps: "10",
        sets: "3",
      ),
    ])
  ];

  // get the list of workouts

  List<Workout> getWorkoutList() {
    return workoutList;
  }

  // get length of given workout
  int numberOfExercisesInWorkout(String workoutName) {
    Workout relevantWorkout = getRelevantWorkout(workoutName);

    return relevantWorkout.exercises.length;
  }

  // add a workout
  void addWorkout(String name) {
    // add a new workout with a blank list of exercises
    workoutList.add(Workout(name: name, exercises: []));
    
    notifyListeners();
  }

  // add an exercise to a workout
  void addExercise(String workoutName, String exerciseName, String weight,
      String reps, String sets) {
    // find the relevant workout
    Workout relevantWorkout = getRelevantWorkout(workoutName);

    relevantWorkout.exercises.add(Exercise(
      name: exerciseName,
      weight: weight,
      reps: reps,
      sets: sets,
    ));

    notifyListeners();
  }

  // add sessions to an exercise (so as to track progress)
  // Yogesh Method(String yoMama)

  // find relevant workout
  Workout getRelevantWorkout(String workoutName) {
    Workout relevantWorkout =
        workoutList.firstWhere((workout) => workout.name == workoutName);

    return relevantWorkout;
  }

  // find relevant exercise
  Exercise getRelevantExercise(String workoutName, String exerciseName) {
    Workout relevantWorkout = getRelevantWorkout(workoutName);

    Exercise relevantExercise = relevantWorkout.exercises
        .firstWhere((exercise) => exercise.name == exerciseName);

    return relevantExercise;
  }
}
