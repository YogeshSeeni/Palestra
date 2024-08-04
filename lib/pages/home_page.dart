import 'package:Palestra/controller/bottom_nav_bar_controller.dart';
import 'package:Palestra/models/session.dart';
import 'package:Palestra/pages/session_page.dart';
import 'package:Palestra/services/session_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:get/get.dart';
import 'package:Palestra/pages/goals_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? currentUser;
  SessionFirestore? sessionFirestore;

  @override
  void initState() {
    super.initState();
    refreshUser();
    checkTrainingGoals();
  }

  final newSessionNameController = TextEditingController();

 void checkTrainingGoals() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    
    Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
    if (!userDoc.exists || userData == null || !userData.containsKey('fitnessProfile')) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => GoalsPage(isInitialSetup: true),
      ));
    }
  }
}
  

  void createNewSession() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text("Start workout session"),
                content: TextField(
                  controller: newSessionNameController,
                  decoration: const InputDecoration(
                    hintText: 'Session Name',
                  ),
                ),
                actions: [
                  MaterialButton(
                      onPressed: saveSession,
                      child: const Text("save",
                          style: TextStyle(color: Colors.black))),
                  MaterialButton(
                      onPressed: cancel,
                      child: const Text("cancel",
                          style: TextStyle(color: Colors.black)))
                ]));
  }

  void saveSession() async {
    String newSessionName = newSessionNameController.text;
    Session newSession = Session.withTitle(newSessionName);

    DocumentReference<Object?>? sessionDoc =
        await sessionFirestore?.addSession(newSession);
    Navigator.pop(context);
    clear();
    if (sessionDoc != null) {
      goToSessionPage(newSession, sessionDoc.id);
    }
  }

  void goToSessionPage(Session session, String sessionID) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => SessionPage(
                session: session,
                sessionID: sessionID,
                sessionFirestore: sessionFirestore!)));
  }

  void cancel() {
    Navigator.pop(context);
    clear();
  }

  void clear() {
    newSessionNameController.clear();
  }

  void refreshUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();

      setState(() {
        currentUser = FirebaseAuth.instance.currentUser;
      });

      // sessions firestore reference
      sessionFirestore = SessionFirestore(userID: currentUser!.uid);
    }
  }

  void logout() {
    FirebaseAuth.instance.signOut();
  }

  void renameSession(String sessionId, String currentTitle) {
    TextEditingController renameController =
        TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Rename Session"),
        content: TextField(
          controller: renameController,
          decoration: const InputDecoration(
            hintText: 'New Session Name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () async {
              String newTitle = renameController.text;
              await sessionFirestore?.updateSessionTitle(sessionId, newTitle);
              Navigator.pop(context);
            },
            child: const Text("Save", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void deleteSession(String sessionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Session"),
        content: const Text("Are you sure you want to delete this session?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () async {
              await sessionFirestore?.deleteSession(sessionId);
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void reuseSession(Session session) async {
    Session newSession = Session.withTitle("${session.title} (Copy)");
    // Copy exercises from the original session to the new session
    for (var exercise in session.exercises) {
      newSession.addExercise(exercise['title']);
      for (int i = 0; i < exercise['reps'].length; i++) {
        newSession.addReps(exercise['title'], exercise['reps'][i]);
        newSession.addWeight(exercise['title'], exercise['weights'][i]);
      }
    }
    DocumentReference<Object?>? sessionDoc =
        await sessionFirestore?.addSession(newSession);
    if (sessionDoc != null) {
      goToSessionPage(newSession, sessionDoc.id);
    }
  }

  String _getBestSet(List<dynamic> weights, List<dynamic> reps) {
    if (weights.isEmpty || reps.isEmpty) return 'N/A';

    int bestIndex = 0;
    for (int i = 1; i < weights.length; i++) {
      if (weights[i] > weights[bestIndex]) {
        bestIndex = i;
      }
    }

    return '${weights[bestIndex]} x ${reps[bestIndex]}';
  }

  @override
  Widget build(BuildContext context) {
    BottomNavigationBarController controller =
        Get.put(BottomNavigationBarController());
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Palestra",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(onPressed: logout, icon: const Icon(Icons.logout)),
        ],
        backgroundColor: Colors.grey[200],
      ),
      backgroundColor: Colors.grey[200],
      body: Obx(() {
        if (controller.index.value == 1) {
          return Column(
            children: [
              if (currentUser?.displayName != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Let's work, ${currentUser?.displayName}.",
                      style: const TextStyle(
                          fontSize: 35, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: createNewSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.start, color: Colors.white),
                      Text(' Start Workout Session'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Session History",
                        style: TextStyle(
                            fontSize: 25, fontWeight: FontWeight.bold),
                      ),
                    ]),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                    stream: sessionFirestore?.getSessionStream(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        List sessionsList = snapshot.data!.docs;

                        return ListView.builder(
                          itemCount: sessionsList.length,
                          itemBuilder: (context, index) {
                            DocumentSnapshot document = sessionsList[index];
                            String docID = document.id;
                            Session session = Session.fromJson(
                                document.data() as Map<String, dynamic>);

                            return Card(
                              color: Colors.grey[400],
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              child: ExpansionTile(
                                title: Text(session.title,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  session.date.toString(),
                                ),
                                children: [
                                  ...session.exercises
                                      .map((exercise) => ListTile(
                                            title: Text(
                                                "${exercise['title']}: ${exercise['reps'].length} sets",
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            subtitle: Text(
                                              'Best set: ${_getBestSet(exercise['weights'], exercise['reps'])}',
                                            ),
                                          )),
                                  ButtonBar(
                                    alignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () =>
                                            renameSession(docID, session.title),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.recycling),
                                        onPressed: () => reuseSession(session),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () => deleteSession(docID),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      } else {
                        return const Column(children: [
                          SizedBox(height: 150),
                          Center(child: Text("No data available")),
                        ]);
                      }
                    }),
              ),
            ],
          );
        } else {
          return controller.pages[controller.index.value];
        }
      }),
      bottomNavigationBar: Container(
        color: Colors.black,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
          child: GNav(
            backgroundColor: Colors.black,
            color: Colors.white,
            activeColor: Colors.white,
            tabBackgroundColor: Colors.grey.shade800,
            iconSize: 30,
            gap: 8,
            padding: const EdgeInsets.all(16),
            tabs: const [
              GButton(icon: Icons.trending_up, text: "Analyze"),
              GButton(icon: Icons.add, text: "Workout"),
              GButton(icon: Icons.fitness_center, text: "Exercises"),
              GButton(icon: Icons.chat, text: "AI"),
            ],
            selectedIndex: controller.index.value,
            onTabChange: (value) {
              controller.index.value = value;
            },
          ),
        ),
      ),
    );
  }
}
