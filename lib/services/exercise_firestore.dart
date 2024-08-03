import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:Palestra/models/exercise.dart';

class ExerciseFirestore {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Getting the current user ID
  String? get userId {
    User? user = _auth.currentUser;
    return user?.uid;
  }

  CollectionReference get customExercises {
    if (userId == null) {
      throw FirebaseAuthException(
          code: 'NO_USER',
          message: 'No user is currently signed in. Custom exercises cannot be accessed.');
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('customExercises');
  }

  Future<void> addExercise(ExerciseInfo exercise) {
    return customExercises.add(exercise.toJson());
  }

  Future<void> deleteExercise(String docId) {
    return customExercises.doc(docId).delete();
  }

  Stream<List<DocumentSnapshot>> getExercisesStream() {
    final defaultExercises = FirebaseFirestore.instance.collection('exercises').orderBy('title').snapshots();
    final userCustomExercises = customExercises.orderBy('title').snapshots();

    return Rx.combineLatest2(defaultExercises, userCustomExercises, (QuerySnapshot defaultData, QuerySnapshot customData) {
      // Combine the documents from both snapshots
      final allDocuments = [...defaultData.docs, ...customData.docs];
      return allDocuments;
    });
  }
}
