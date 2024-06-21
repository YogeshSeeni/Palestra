import 'package:Palestra/models/exercise.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseFirestore {
  final CollectionReference exercises = FirebaseFirestore.instance.collection('exercises');

  Future<void> addExercise(Exercise exercise) {
    return exercises.add(exercise.toJson());
  }

  Stream<QuerySnapshot> getExercisesStream() {
    final exerciseStream = exercises.orderBy('title').snapshots();

    return exerciseStream;
  }
}