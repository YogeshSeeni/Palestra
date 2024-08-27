import 'package:Palestra/models/session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SessionFirestore {
  final String userID;
  late final CollectionReference sessions;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  SessionFirestore({required this.userID}) {
    sessions = _firestore.collection('users/$userID/sessions');
  }

  Future<DocumentReference<Object?>> addSession(Session session) =>
      sessions.add(session.toJson());

  Stream<QuerySnapshot> getSessionStream() =>
      sessions.orderBy('date', descending: true).snapshots();

  Stream<QuerySnapshot> getTemplateStream() =>
      sessions.where('isTemplate', isEqualTo: true).snapshots();

  Future<void> updateSession(Session session, String sessionID) =>
      sessions.doc(sessionID).update(session.toJson());

  Future<void> updateSessionTitle(String sessionID, String newTitle) =>
      sessions.doc(sessionID).update({'title': newTitle});

  Future<void> deleteSession(String sessionID) =>
      sessions.doc(sessionID).delete();

  Future<List<Map<String, dynamic>>> fetchUserSessions() async {
    try {
      QuerySnapshot querySnapshot = await sessions.get();
      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get every single exercise performed by user for analysis 
  Future<List<String>> fetchUniqueExercises() async {
    Set<String> exercises = {};

    try {
      QuerySnapshot querySnapshot = await sessions.get();
      
      for (var doc in querySnapshot.docs) {
        Session session = Session.fromJson(doc.data() as Map<String, dynamic>);
        if (session.isTemplate == true) {
          continue;
        }

        for (var exercise in session.exercises) {
          exercises.add(exercise['title']);
        }
      } 
    } catch (e) {
    }
    return exercises.toList();
  }

  // Get Exercise Data for analyzsis
  Future<Map<String, dynamic>> getExercise(String exerciseName) async {
    try {
      QuerySnapshot querySnapshot =
          await sessions.orderBy('date', descending: false).get();
      Map<String, dynamic> exerciseData = {'reps': [], 'weights': []};

      for (var doc in querySnapshot.docs) {
        Session session = Session.fromJson(doc.data() as Map<String, dynamic>);
        for (var exercise in session.exercises) {
          String title = exercise['title'];

          if (title == exerciseName) {
            exerciseData['reps'] = exerciseData['reps'] + exercise['reps'];
            exerciseData['weights'] = exerciseData['weights'] + exercise['weights'];
          }
        }
      }
      return exerciseData;
    } catch (e) {
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> fetchExerciseData(String exerciseTitle) async {
    try {
      QuerySnapshot querySnapshot = await sessions.where('isTemplate', isEqualTo: false).get();

      List<Map<String, dynamic>> result = querySnapshot.docs
          .expand((doc) {
            List exercises = doc['exercises'] as List;
            return exercises
                .where((ex) => ex['title'] == exerciseTitle)
                .map((ex) {
                  return {
                    'date': doc['date'],
                    'reps': ex['reps'],
                    'weights': ex['weights']
                  };
                });
          })
          .toList();

      return result;
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> fetchAllExercisesForChatbot() async {
    try {
      QuerySnapshot querySnapshot = await sessions.get();
      Map<String, List<Map<String, dynamic>>> exerciseData = {};

      for (var doc in querySnapshot.docs) {
        for (var ex in doc['exercises']) {
          String title = ex['title'];
          exerciseData.putIfAbsent(title, () => []).add({
            'date': (doc['date'] as Timestamp).toDate().toIso8601String(),
            'reps': ex['reps'],
            'weights': ex['weights']
          });
        }
      }

      return exerciseData;
    } catch (e) {
      return {};
    }
  }

  Stream<QuerySnapshot> getNonTemplateSessionStream() {
    return _firestore
        .collection('users')
        .doc(userID)
        .collection('sessions')
        .where('isTemplate', isEqualTo: false)
        .snapshots();
  }
}
