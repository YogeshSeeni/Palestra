import 'package:Palestra/controller/bottom_nav_bar_controller.dart';
import 'package:Palestra/models/session.dart';
import 'package:Palestra/pages/session_page.dart';
import 'package:Palestra/services/session_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:get/get.dart';
import 'package:Palestra/pages/profile_page.dart';
import 'package:intl/intl.dart';
import 'package:Palestra/pages/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? currentUser;
  SessionFirestore? sessionFirestore;
  bool? showQuickStartGuide = true;

  @override
  void initState() {
    super.initState();
    refreshUser();
    checkTrainingGoals();
  }

  final newSessionNameController = TextEditingController();

  void refreshUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();

      setState(() {
        currentUser = FirebaseAuth.instance.currentUser;
      });

      // sessions firestore reference
      sessionFirestore = SessionFirestore(userID: currentUser!.uid);

      List<Map<String, dynamic>>? sessions =
          await sessionFirestore?.fetchUserSessions();

      setState(() {
        showQuickStartGuide = sessions?.isEmpty;
      });
    }
  }

  void checkTrainingGoals() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
      if (!userDoc.exists ||
          userData == null ||
          !userData.containsKey('fitnessProfile')) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const ProfilePage(isInitialSetup: true),
        ));
      }
    }
  }

  void createNewSession() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text("Start Workout Session"),
                content: TextField(
                  controller: newSessionNameController,
                  decoration: const InputDecoration(
                    hintText: 'Session Name',
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: cancel,
                    child: const Text("Cancel",
                        style: TextStyle(color: Colors.black)),
                  ),
                  TextButton(
                    onPressed: saveSession,
                    child: const Text("Save",
                        style: TextStyle(color: Colors.black)),
                  ),
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
            child: const Text("Delete", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void reuseSession(Session session) async {
    Session newSession = Session.withTitle(session.title);
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

  Widget _buildSessionHistory(bool isSmallScreen) {
    return StreamBuilder<QuerySnapshot>(
      stream: sessionFirestore?.getSessionStream(),
      builder: (context, snapshot) {
        return Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: true,
            title: Padding(
              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8.0 : 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Session History",
                    style: TextStyle(
                      fontSize: isSmallScreen ? 18 : 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            children: [
              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty)
                Builder(builder: (context) {
                  List<DocumentSnapshot> sortedDocs = snapshot.data!.docs
                      .toList()
                    ..sort((a, b) {
                      Session sessionA =
                          Session.fromJson(a.data() as Map<String, dynamic>);
                      Session sessionB =
                          Session.fromJson(b.data() as Map<String, dynamic>);
                      return sessionB.date.compareTo(sessionA.date);
                    });

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedDocs.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot document = sortedDocs[index];
                      String docID = document.id;
                      Session session = Session.fromJson(
                          document.data() as Map<String, dynamic>);

                      return Card(
                        color: Colors.grey[300],
                        margin: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 6 : 8,
                          horizontal: isSmallScreen ? 12 : 16,
                        ),
                        child: ExpansionTile(
                          title: Text(
                            session.title,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            DateFormat.yMMMd()
                                .format(session.date)
                                .toString(),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                          ),
                          children: [
                            ...session.exercises.map((exercise) => ListTile(
                                  title: Text(
                                    "${exercise['title'] ?? 'Unknown Exercise'}: ${(exercise['reps'] as List?)?.length ?? 0} sets",
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Best set: ${_getBestSet(exercise['weights'] as List? ?? [], exercise['reps'] as List? ?? [])}',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 12 : 14,
                                    ),
                                  ),
                                )),
                            ButtonBar(
                              alignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, size: isSmallScreen ? 18 : 24),
                                  onPressed: () => _editSession(session, docID),
                                ),
                                IconButton(
                                  icon: Icon(Icons.recycling, size: isSmallScreen ? 18 : 24),
                                  onPressed: () => _makeTemplate(session),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, size: isSmallScreen ? 18 : 24),
                                  onPressed: () => deleteSession(docID),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                })
              else
                Column(
                  children: [
                    SizedBox(height: isSmallScreen ? 12 : 25),
                    Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      child: Center(
                        child: Text(
                          "No session data available.\nStart a workout and begin tracking your progress!",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: isSmallScreen ? 12 : 16),
                        ),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 25),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  void _editSession(Session session, String sessionId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionPage(
          session: session,
          sessionID: sessionId,
          sessionFirestore: sessionFirestore!,
        ),
      ),
    );
  }

  void _makeTemplate(Session session) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String templateName = session.title;
        return AlertDialog(
          title: const Text("Create Template from Session"),
          content: TextField(
            onChanged: (value) {
              templateName = value;
            },
            decoration: const InputDecoration(
              hintText: "Enter template name",
              labelText: "Template Name",
            ),
            controller: TextEditingController(text: session.title),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Save"),
              onPressed: () {
                if (templateName.isNotEmpty) {
                  Session newTemplate = Session(
                    title: templateName,
                    date: DateTime.now(),
                    exercises: session.exercises,
                    isTemplate: true,
                  );
                  sessionFirestore?.addSession(newTemplate).then((_) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Template created successfully")),
                    );
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTemplatesSection(bool isSmallScreen) {
    return StreamBuilder<QuerySnapshot>(
      stream: sessionFirestore?.getTemplateStream(),
      builder: (context, snapshot) {
        return Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: true,
            title: Padding(
              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8.0 : 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Templates",
                    style: TextStyle(
                      fontSize: isSmallScreen ? 18 : 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addNewTemplate,
                    icon: Icon(Icons.add, size: isSmallScreen ? 18 : 24),
                    label: Text(
                      "Add Template",
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            children: [
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator())
              else if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                Column(
                  children: [
                    SizedBox(height: isSmallScreen ? 12 : 25),
                    Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      child: Center(
                        child: Text(
                          "No templates available.\nCreate one to supercharge your workout routine!",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: isSmallScreen ? 12 : 16),
                        ),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 25),
                  ],
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot document = snapshot.data!.docs[index];
                    String docID = document.id;
                    Session template = Session.fromJson(
                        document.data() as Map<String, dynamic>);

                    return Card(
                      color: Colors.grey[300],
                      margin: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 6 : 8,
                        horizontal: isSmallScreen ? 12 : 16,
                      ),
                      child: ExpansionTile(
                        title: Text(
                          template.title,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          "Exercises: ${template.exercises.length}",
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 14,
                          ),
                        ),
                        children: [
                          ...template.exercises.map((exercise) => ListTile(
                                title: Text(
                                  exercise['title'] ?? 'Unknown Exercise',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16,
                                  ),
                                ),
                                subtitle: Text(
                                  "Sets: ${(exercise['reps'] as List?)?.length ?? 0}",
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 12 : 14,
                                  ),
                                ),
                              )),
                          ButtonBar(
                            alignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, size: isSmallScreen ? 18 : 24),
                                onPressed: () => _editTemplate(template, docID),
                              ),
                              IconButton(
                                icon: Icon(Icons.play_arrow, size: isSmallScreen ? 18 : 24),
                                onPressed: () => _useTemplate(template, docID),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, size: isSmallScreen ? 18 : 24),
                                onPressed: () => _deleteTemplate(docID),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _addNewTemplate() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newTemplateName = "";
        return AlertDialog(
          title: const Text("Create New Template"),
          content: TextField(
            onChanged: (value) {
              newTemplateName = value;
            },
            decoration: const InputDecoration(hintText: "Enter template name"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Save"),
              onPressed: () {
                if (newTemplateName.isNotEmpty) {
                  Session newTemplate = Session.withTitle(newTemplateName);
                  newTemplate.isTemplate = true;
                  sessionFirestore?.addSession(newTemplate).then((sessionDoc) {
                    Navigator.of(context).pop(); // Close the dialog
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SessionPage(
                          session: newTemplate,
                          sessionID: sessionDoc.id,
                          sessionFirestore: sessionFirestore!,
                          isTemplate: true,
                        ),
                      ),
                    );
                  });
                }
              },
            ),
          ],
        );
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
      title: template.title,
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
            child: const Text("Delete", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStartGuide(bool isSmallScreen) {
    if (!showQuickStartGuide!) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Quick Start Guide",
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _markQuickStartGuideAsSeen,
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Text(
            "Welcome to Palestra!",
            style: TextStyle(
              fontSize: isSmallScreen ? 20 : 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Text(
            "Your personal fitness journey starts here. Track your workouts, analyze your progress, and create personalized workout plans.",
            style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          _buildGuideStep(
            icon: Icons.add_circle_outline,
            title: "Create a Session",
            description: "Start by creating your first workout session.",
            isSmallScreen: isSmallScreen,
          ),
          _buildGuideStep(
            icon: Icons.fitness_center,
            title: "Log Your Workouts",
            description: "Record your exercises, sets, reps, and weights for each session.",
            isSmallScreen: isSmallScreen,
          ),
          _buildGuideStep(
            icon: Icons.save_alt,
            title: "Create Templates",
            description: "Save your favorite workouts as templates for quick access.",
            isSmallScreen: isSmallScreen,
          ),
          _buildGuideStep(
            icon: Icons.create,
            title: "Add Custom Exercises",
            description: "Can't find an exercise? Add your own to the database.",
            isSmallScreen: isSmallScreen,
          ),
          _buildGuideStep(
            icon: Icons.smart_toy,
            title: "AI Workout Generation",
            description: "Use AI to generate personalized workouts or regimens.",
            isSmallScreen: isSmallScreen,
          ),
          _buildGuideStep(
            icon: Icons.analytics,
            title: "Analyze Your Progress",
            description: "Utilize AI and graphs to visualize and understand your fitness journey.",
            isSmallScreen: isSmallScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildGuideStep({
    required IconData icon,
    required String title,
    required String description,
    required bool isSmallScreen,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: isSmallScreen ? 20 : 24),
          SizedBox(width: isSmallScreen ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 2 : 4),
                Text(
                  description,
                  style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _markQuickStartGuideAsSeen() async {
    setState(() {
      showQuickStartGuide = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    BottomNavigationBarController controller =
        Get.put(BottomNavigationBarController());
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.person),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfilePage()),
          ),
        ),
        title: const Text(
          "Palestra",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            ),
          ),
        ],
        backgroundColor: Colors.grey[200],
        scrolledUnderElevation: 0.0
      ),
      backgroundColor: Colors.grey[200],
      body: Obx(() {
        if (controller.index.value == 1) {
          return LayoutBuilder(
            builder: (context, constraints) {
              bool isSmallScreen = constraints.maxHeight < 700;
              return _buildHomeContent(isSmallScreen);
            },
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

  Widget _buildHomeContent(bool isSmallScreen) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
            child: Container(
              alignment: Alignment.centerLeft,
              child: Text(
                currentUser?.displayName != null
                    ? "Let's work, ${currentUser!.displayName}."
                    : "Start Workout",
                style: TextStyle(
                  fontSize: isSmallScreen ? 28 : 35,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 6.0 : 8.0),
            child: ElevatedButton(
              onPressed: createNewSession,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16 : 20, 
                  vertical: isSmallScreen ? 16 : 20
                ),
                textStyle: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
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
          SizedBox(height: isSmallScreen ? 12 : 16),
          _buildQuickStartGuide(isSmallScreen),
          _buildTemplatesSection(isSmallScreen),
          _buildSessionHistory(isSmallScreen),
        ],
      ),
    );
  }
}
