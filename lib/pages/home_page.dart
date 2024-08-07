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
        builder: (context) => const GoalsPage(isInitialSetup: true),
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
                      child: const Text("Save",
                          style: TextStyle(color: Colors.black))),
                  MaterialButton(
                      onPressed: cancel,
                      child: const Text("Cancel",
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

  Widget _buildSessionHistory() {
    return StreamBuilder<QuerySnapshot>(
      stream: sessionFirestore?.getSessionStream(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          List sessionsList = snapshot.data!.docs
              .where((doc) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                // Include sessions that are explicitly not templates or don't have the isTemplate property
                return data['isTemplate'] == false || !data.containsKey('isTemplate');
              })
              .toList();

          if (sessionsList.isEmpty) {
            return const Column(children: [
              SizedBox(height: 150),
              Center(child: Text("No non-template sessions available")),
            ]);
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
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
                    ...session.exercises.map((exercise) => ListTile(
                          title: Text(
                              "${exercise['title'] ?? 'Unknown Exercise'}: ${(exercise['reps'] as List?)?.length ?? 0} sets",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            'Best set: ${_getBestSet(exercise['weights'] as List? ?? [], exercise['reps'] as List? ?? [])}',
                          ),
                        )),
                    ButtonBar(
                      alignment: MainAxisAlignment.spaceEvenly,
                      children: [
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
      },
    );
  }

  Widget _buildTemplatesSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: sessionFirestore?.getTemplateStream(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          List templatesList = snapshot.data!.docs
              .where((doc) => (doc.data() as Map<String, dynamic>)['isTemplate'] == true)
              .toList();

          if (templatesList.isEmpty) {
            return const SizedBox.shrink();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Templates",
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: templatesList.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot document = templatesList[index];
                  String docID = document.id;
                  Session template =
                      Session.fromJson(document.data() as Map<String, dynamic>);

                  return Card(
                    color: Colors.grey[400],
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ExpansionTile(
                      title: Text(template.title,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Exercises: ${template.exercises.length}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editTemplate(template, docID),
                          ),
                          IconButton(
                            icon: const Icon(Icons.play_arrow),
                            onPressed: () => _useTemplate(template, docID),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteTemplate(docID),
                          ),
                        ],
                      ),
                      children: [
                        ...template.exercises
                            .map((exercise) => ListTile(
                                  title: Text(exercise['title'] ?? 'Unknown Exercise'),
                                  subtitle:
                                      Text("Sets: ${(exercise['reps'] as List?)?.length ?? 0}"),
                                )),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  void _editTemplate(Session template, String templateId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionPage(
          session: template,
          sessionID: templateId,
          sessionFirestore: sessionFirestore!,
          isTemplate: true,
        ),
      ),
    );
  }

  void _useTemplate(Session template, String templateId) {
    Session newSession = Session(
      title: "${template.title} ${DateTime.now().toString().split(' ')[0]}",
      date: DateTime.now(),
      exercises: template.exercises,
      isTemplate: false,
    );

    sessionFirestore?.addSession(newSession).then((sessionDoc) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SessionPage(
            session: newSession,
            sessionID: sessionDoc.id,
            sessionFirestore: sessionFirestore!,
          ),
        ),
      );
    });
  }

  void _deleteTemplate(String templateId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Template"),
        content: const Text("Are you sure you want to delete this template?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () async {
              await sessionFirestore?.deleteSession(templateId);
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _startTemplateWorkout(Map<String, dynamic> template) async {
    String sessionName =
        "${template['name']} - ${DateTime.now().toString().split(' ')[0]}";
    Session newSession = Session.withTitle(sessionName);

    for (var exercise in template['exercises']) {
      newSession.addExercise(exercise['name']);
      for (int i = 0; i < exercise['sets']; i++) {
        newSession.addReps(exercise['name'], 0);
        newSession.addWeight(exercise['name'], 0);
      }
    }

    DocumentReference<Object?>? sessionDoc =
        await sessionFirestore?.addSession(newSession);

    if (sessionDoc != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SessionPage(
            session: newSession,
            sessionID: sessionDoc.id,
            sessionFirestore: sessionFirestore!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    BottomNavigationBarController controller =
        Get.put(BottomNavigationBarController());
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GoalsPage()),
          ),
        ),
        title: const Text(
          "Palestra",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
        backgroundColor: Colors.grey[200],
        scrolledUnderElevation: 0.0
      ),
      backgroundColor: Colors.grey[200],
      body: Obx(() {
        if (controller.index.value == 1) {
          return SingleChildScrollView(
            child: Column(
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
                _buildTemplatesSection(),
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
                _buildSessionHistory(),
              ],
            ),
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