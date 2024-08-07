import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:Palestra/models/session.dart';
import 'package:Palestra/services/session_firestore.dart';
import 'package:Palestra/services/gemini_service.dart';
import 'package:Palestra/pages/session_page.dart';
import 'package:Palestra/util/parse_workout.dart';  // Updated import

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<ChatMessage> _messages = [];
  List<Map<String, dynamic>> _availableExercises = [];
  bool _isLoading = false;
  Map<String, dynamic> _userProfile = {};
  String _recommendation = '';
  late SessionFirestore _sessionFirestore;
  late GeminiService _geminiService;

  final ChatUser _currentUser = ChatUser(id: "0", firstName: "User");
  final ChatUser _geminiUser = ChatUser(id: "1", firstName: "Palestra AI");

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _fetchExercises();
    _loadUserProfile();
    _fetchExerciseData();
    _greetUser();
  }

  void _initializeServices() {
    final user = _auth.currentUser;
    if (user != null) {
      _sessionFirestore = SessionFirestore(userID: user.uid);
    }
    _geminiService = GeminiService();
  }

  Future<void> _fetchExercises() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('exercises').get();
      setState(() {
        _availableExercises = querySnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  'title': doc['title'] as String,
                  'primaryMuscles': doc['primaryMuscles'] as List<dynamic>,
                })
            .toList();
      });
    } catch (e) {
      print("Error fetching exercises: $e");
    }
  }

  Future<void> _loadUserProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        _userProfile = userDoc.data() as Map<String, dynamic>;
      });
    }
  }

  Future<void> _fetchExerciseData() async {
    if (!mounted) return;
    try {
      Map<String, List<Map<String, dynamic>>> fetchedData = await _sessionFirestore.fetchAllExercisesForChatbot();
      if (mounted) {
        await _generateRecommendation(fetchedData);
      }
    } catch (e) {
      print("Error fetching exercise data: $e");
    }
  }

  Future<void> _generateRecommendation(Map<String, List<Map<String, dynamic>>> exerciseData) async {
    try {
      String generatedRecommendation = await _geminiService.generateRecommendation(exerciseData);
      if (mounted) {
        setState(() {
          _recommendation = generatedRecommendation.isNotEmpty
              ? generatedRecommendation
              : "I couldn't generate a recommendation at this time. How about we discuss your fitness goals?";
        });
      }
    } catch (e) {
      print("Error generating recommendation: $e");
      if (mounted) {
        setState(() {
          _recommendation =
              "Let's focus on your fitness journey. What would you like to work on today?";
        });
      }
    }
  }

  void _greetUser() {
    _addMessage(_geminiUser,
        "Hello! I'm your AI fitness coach. How can I help you with your workout today? You can ask me to create a workout plan or for advice on specific exercises.");
  }

  void _createWorkout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Create Workout',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(),
                ListTile(
                  title: const Text('Single Workout'),
                  subtitle: const Text('Generate a one-time workout routine'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _createSingleWorkout();
                  },
                ),
                ListTile(
                  title: const Text('Workout Regimen'),
                  subtitle: const Text('Create a weekly workout plan'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _createWorkoutRegimen();
                  },
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Tip: Fitness experts recommend following a regimen for at least 4-6 weeks to see noticeable progress.',
                    style:
                        TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _createSingleWorkout() async {
    String? userInput = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        String inputText = '';
        return AlertDialog(
          title: const Text('What kind of workout are you looking for?'),
          content: TextField(
            onChanged: (value) {
              inputText = value;
            },
            decoration: const InputDecoration(hintText: "E.g., Quick upper body workout"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(inputText);
              },
            ),
          ],
        );
      },
    );

    if (userInput == null || userInput.isEmpty) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      String workoutPlan = await _geminiService.generateSingleWorkout(
        _userProfile['fitnessProfile'],
        _availableExercises,
        userInput,
      );
      List<Map<String, dynamic>> exercises = parseWorkoutPlan(workoutPlan, _availableExercises);

      if (exercises.isEmpty) {
        throw const FormatException('No valid exercises generated');
      }

      String sessionName = userInput;

      // Create template
      Session templateSession = Session.withTitle(sessionName);
      templateSession.isTemplate = true;
      for (var exercise in exercises) {
        templateSession.addExercise(exercise['title']);
        for (int i = 0; i < exercise['sets']; i++) {
          templateSession.addReps(exercise['title'], 0);
          templateSession.addWeight(exercise['title'], 0);
        }
      }
      await _sessionFirestore.addSession(templateSession);

      // Create actual session
      Session newSession = Session.withTitle(sessionName);
      for (var exercise in exercises) {
        newSession.addExercise(exercise['title']);
        for (int i = 0; i < exercise['sets']; i++) {
          newSession.addReps(exercise['title'], 0);
          newSession.addWeight(exercise['title'], 0);
        }
      }

      DocumentReference<Object?>? sessionDoc = await _sessionFirestore.addSession(newSession);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SessionPage(
            session: newSession,
            sessionID: sessionDoc.id,
            sessionFirestore: _sessionFirestore,
          ),
        ),
      );

      _addMessage(_geminiUser,
          "I've created a workout based on your request: '$userInput'. You can now start your session, and I've also saved a template for future use. You can find the template in the Templates section on the home page. Feel free to customize it as needed!");
    } catch (e) {
      print("Error processing workout plan: $e");
      _addMessage(_geminiUser,
          "I'm sorry, I encountered an error while creating your workout. Could you try simplifying your request or being more specific?");
    }

    setState(() => _isLoading = false);
  }

  void _createWorkoutRegimen() async {
    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>> regimenPlan = await _geminiService.generateWorkoutRegimen(
          _userProfile['fitnessProfile'], _availableExercises);

      for (var template in regimenPlan) {
        Session newSession = Session(
          title: "${template['name']}",
          date: DateTime.now(),
          exercises: (template['exercises'] as List<dynamic>).map((e) => {
            'title': e['title'],
            'sets': e['sets'],
            'reps': List.filled(e['sets'], 0),
            'weights': List.filled(e['sets'], 0),
          }).toList(),
          isTemplate: true,
        );
        await _sessionFirestore.addSession(newSession);
      }

      _addMessage(_geminiUser,
          "I've created a personalized weekly workout regimen based on your profile and preferences. You can find these workout templates in the Templates section on the home page. Feel free to adjust them as needed. Remember, consistency is key - try to follow this regimen for at least 4-6 weeks to see significant progress!");
    } catch (e) {
      print("Error processing workout regimen: $e");
      _addMessage(_geminiUser,
          "I'm sorry, I encountered an error while creating your workout regimen. Could you try again later?");
    }

    setState(() => _isLoading = false);
  }

  void _addMessage(ChatUser user, String text) {
    if (mounted) {
      setState(() {
        _messages.insert(
          0,
          ChatMessage(
            user: user,
            createdAt: DateTime.now(),
            text: text,
          ),
        );
      });
    }
  }

  void _handleUserMessage(ChatMessage message) async {
    setState(() => _messages.insert(0, message));
    setState(() => _isLoading = true);

    try {
      String response =
          await _geminiService.sendMessage(message.text, _messages);
      _addMessage(_geminiUser, response);
    } catch (e) {
      print("Error processing message: $e");
      _addMessage(_geminiUser,
          "I apologize, but I couldn't process your request at the moment. Could you please try rephrasing your question?");
    }

    setState(() => _isLoading = false);
  }

  void _getTip() async {
    setState(() => _isLoading = true);

    try {
      String tip = await _geminiService.getTip();
      _addMessage(_geminiUser, "Here's a quick workout tip: $tip");
    } catch (e) {
      print("Error getting tip: $e");
      _addMessage(_geminiUser,
          "I'm sorry, I couldn't generate a tip right now. Let me know if you have any specific questions!");
    }

    setState(() => _isLoading = false);
  }

  Widget _buildRecommendationWidget() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        color: Colors.white,
        shadowColor: Colors.black,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.black),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  _recommendation,
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Coach',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          _buildHeader(),
          if (_recommendation.isNotEmpty) _buildRecommendationWidget(),
          Expanded(
            child: DashChat(
              currentUser: _currentUser,
              onSend: _handleUserMessage,
              messages: _messages,
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: Colors.black),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Create Workout'),
                  onPressed: _createWorkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.lightbulb_outline),
                  label: const Text('Get Tip'),
                  onPressed: _getTip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}