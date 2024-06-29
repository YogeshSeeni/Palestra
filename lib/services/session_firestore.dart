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
    
    List<Map<String, dynamic>> sessionList = querySnapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      // print('Fetched session: ${data.toString()}');  // Print each fetched session for debugging
      return data;
    }).toList();
    
    // print('Total sessions fetched: ${sessionList.length}');
    return sessionList;
  } catch (e) {
    print("Error fetching sessions: $e");
    return [];
  }
}

}
