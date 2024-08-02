import 'package:Palestra/models/session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SessionFirestore {
  final String userID;
  late final CollectionReference sessions;

  SessionFirestore({required this.userID}) {
    sessions = FirebaseFirestore.instance.collection('users/$userID/sessions');
  }

  Future<DocumentReference<Object?>> addSession(Session session) => 
    sessions.add(session.toJson());

  Stream<QuerySnapshot> getSessionStream() => 
    sessions.orderBy('date', descending: true).snapshots();

  Future<void> updateSession(Session session, String sessionID) => 
    sessions.doc(sessionID).update(session.toJson());

  Future<List<Map<String, dynamic>>> fetchUserSessions() async {
    try {
      QuerySnapshot querySnapshot = await sessions.get();
      return querySnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
    } catch (e) {
      print("Error fetching sessions: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getExercises() async {
    try {
      QuerySnapshot querySnapshot = await sessions.orderBy('date', descending: false).get();
      Map<String, Map<String, dynamic>> exerciseMap = {};

      for (var doc in querySnapshot.docs) {
        Session session = Session.fromJson(doc.data() as Map<String, dynamic>);
        for (var exercise in session.exercises) {
          String title = exercise['title'];
          if (!exerciseMap.containsKey(title)) {
            exerciseMap[title] = {...exercise, 'reps': 0, 'weights': 0};
          }
          exerciseMap[title]!['reps'] += exercise['reps'];
          exerciseMap[title]!['weights'] += exercise['weights'];
        }
      }

      return exerciseMap.values.toList();
    } catch (e) {
      print("Error getting exercises: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchExerciseData(String exerciseTitle) async {
    try {
      QuerySnapshot querySnapshot = await sessions.get();
      return querySnapshot.docs
        .expand((doc) => (doc['exercises'] as List)
          .where((ex) => ex['title'] == exerciseTitle)
          .map((ex) => {
            'date': doc['date'],
            'reps': ex['reps'],
            'weights': ex['weights']
          }))
        .toList();
    } catch (e) {
      print("Error fetching exercise data: $e");
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
      print("Error fetching all exercise data: $e");
      return {};
    }
  }
}