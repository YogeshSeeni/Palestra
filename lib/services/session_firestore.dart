import 'package:Palestra/models/session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SessionFirestore {
  final String userID;
  late final CollectionReference sessions;

  SessionFirestore({required this.userID}) {
    sessions = FirebaseFirestore.instance.collection('users/$userID/sessions');
  }

  Future<DocumentReference<Object?>> addSession(Session session) {
    return sessions.add(session.toJson());
  }

  Stream<QuerySnapshot> getSessionStream() {
    final sessionStream = sessions.orderBy('date', descending: true).snapshots();
    return sessionStream;
  }

  Future<void> updateSession(Session session, String sessionID) {
    return sessions.doc(sessionID).update(session.toJson());
  }

  Future<List<Map<String, dynamic>>> fetchUserSessions() async {
    try {
      QuerySnapshot querySnapshot = await sessions.get();
      return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print("Error fetching sessions: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getExercises() async {
    QuerySnapshot querySnapshot = await sessions.orderBy('date', descending: false).get();
    final List<Object?> allSessions = querySnapshot.docs.map((doc) => doc.data()).toList();

    List<Map<String, dynamic>> exercises = [];

    allSessions.forEach((data) {
      Session session = Session.fromJson(data as Map<String, dynamic>);

      session.exercises.forEach((exercise) {
        bool added = false;

        for (var i = 0; i < exercises.length; i++) {
          if (exercises[i]['title'] == exercise['title']) {
            exercises[i]['reps'] = exercises[i]['reps'] + exercise['reps'];
            exercises[i]['weights'] = exercises[i]['weights'] + exercise['weights'];
            added = true;
            break;
          }
        }

        if (added == false) {
          exercises.add(exercise);
        }
      });
    });

    return exercises;
  }

  Future<List<Map<String, dynamic>>> fetchExerciseData(String exerciseTitle) async {
    try {
      QuerySnapshot querySnapshot = await sessions.get();
      List<Map<String, dynamic>> fetchedExercises = [];

      for (var doc in querySnapshot.docs) {
        List<dynamic> exercises = doc['exercises'];
        for (var ex in exercises) {
          if (ex['title'] == exerciseTitle) {
            fetchedExercises.add({
              'date': doc['date'],
              'reps': ex['reps'],
              'weights': ex['weights']
            });
          }
        }
      }

      return fetchedExercises;
    } catch (e) {
      print("Error fetching exercise data: $e");
      return [];
    }
  }
}
