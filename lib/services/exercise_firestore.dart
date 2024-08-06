import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:Palestra/models/exercise.dart';

class ExerciseFirestore {
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
    Map<String, dynamic> exerciseData = exercise.toJson();
    exerciseData['isCustom'] = true;
    return customExercises.add(exerciseData);
  }

  Future<void> deleteExercise(String docId) {
    return customExercises.doc(docId).delete();
  }

  Stream<List<DocumentSnapshot>> getExercisesStream() {
  final defaultExercises = FirebaseFirestore.instance.collection('exercises')
      .orderBy('title')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data();
            data['isCustom'] = false;
            return doc;
          }).toList());

  final userCustomExercises = customExercises
      .orderBy('title')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            data['isCustom'] = true;
            return doc;
          }).toList());

  return Rx.combineLatest2(defaultExercises, userCustomExercises, 
    (List<DocumentSnapshot> defaultData, List<DocumentSnapshot> customData) {
      final allDocuments = [...defaultData, ...customData];
      return allDocuments;
    });
}
}