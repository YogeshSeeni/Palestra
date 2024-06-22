import 'package:Palestra/models/session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SessionFirestore {
  final String userID;
  late final CollectionReference sessions;

  SessionFirestore({required this.userID}) {
    sessions = FirebaseFirestore.instance.collection('users/$userID/sessions');
  }

  Future<void> addSession(Session session) {
    return sessions.add(session.toJson());
  }

  Stream<QuerySnapshot> getSessionStream() {
    final sessionStream = sessions.orderBy('date', descending: true).snapshots();

    return sessionStream;
  }
}
