import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:Palestra/models/session.dart';
import 'package:Palestra/pages/session_page.dart';
import 'package:Palestra/services/session_firestore.dart';
import 'package:Palestra/pages/goals_page.dart';

class AiPage extends StatefulWidget {
  const AiPage({Key? key}) : super(key: key);

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  final Gemini _gemini = Gemini.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<ChatMessage> _messages = [];
  List<Map<String, dynamic>> _availableExercises = [];
  bool _isLoading = false;
  Map<String, dynamic> _userProfile = {};
  String _recommendation = '';
  late SessionFirestore _sessionFirestore;
  String _exerciseDataString = '';

  final ChatUser _currentUser = ChatUser(id: "0", firstName: "User");
  final ChatUser _geminiUser = ChatUser(id: "1", firstName: "Palestra AI");

  @override
  void initState() {
    super.initState();
    _initializeSessionFirestore();
    _fetchExercises();
    _loadUserProfile();
    _fetchExerciseData();
    _greetUser();
  }

  void _initializeSessionFirestore() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _sessionFirestore = SessionFirestore(userID: user.uid);
    }
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
      print("Fetched exercises: $_availableExercises");
    } catch (e) {
      print("Error fetching exercises: $e");
    }
  }

  Future<void> _fetchExerciseData() async {
    if (!mounted) return;
    try {
      Map<String, List<Map<String, dynamic>>> fetchedData =
          await _sessionFirestore.fetchAllExercisesForChatbot();
      if (mounted) {
        setState(() {
          _exerciseDataString = json.encode(fetchedData);
        });
      }
      await _generateRecommendation(fetchedData);
    } catch (e) {
      print("Error fetching exercise data: $e");
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

  void _greetUser() {
    _addMessage(_geminiUser, "Hello! I'm your AI fitness coach. How can I help you with your workout today? You can ask me to create a workout plan or for advice on specific exercises.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          _buildHeader(),
          if (_recommendation.isNotEmpty) _buildRecommendationWidget(),
          Expanded(child: _buildChatUI()),
          if (_isLoading) const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(color: Colors.black),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildActionButtons(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Coach',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GoalsPage()),
              ).then((_) => _loadUserProfile());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Recommendation",
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 4.0),
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.black),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  _recommendation,
                  style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500, color: Colors.black),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatUI() {
    return DashChat(
      currentUser: _currentUser,
      onSend: _handleUserMessage,
      messages: _messages,
      inputOptions: InputOptions(
        inputTextStyle: const TextStyle(fontSize: 16.0, color: Colors.black),
        inputDecoration: InputDecoration(
          hintText: "Ask about exercises or request a workout plan...",
          hintStyle: TextStyle(color: Colors.grey[600]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
            borderSide: BorderSide(color: Colors.black),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
            borderSide: BorderSide(color: Colors.black, width: 2.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
            borderSide: BorderSide(color: Colors.black),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
      messageOptions: const MessageOptions(
        currentUserTextColor: Colors.white,
        currentUserContainerColor: Colors.black,
        containerColor: Colors.white,
        textColor: Colors.black,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.fitness_center),
          label: const Text("Create Workout Plan"),
          onPressed: _createWorkoutPlan,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.lightbulb_outline),
          label: const Text("Get Exercise Tip"),
          onPressed: _getTip,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  void _handleUserMessage(ChatMessage message) async {
    setState(() => _messages.insert(0, message));
    await _sendMessage(message.text);
  }

  Future<void> _sendMessage(String text) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final String prompt = """
Provide a concise response to the user's fitness query. Focus on clear, actionable advice.
Ensure proper formatting and correct spacing in your response. Avoid typos and formatting errors.

User's query: $text

Instructions:
1. Keep the response under 100 words.
2. Use proper spacing, especially around numbers and after punctuation.
3. Avoid technical jargon unless specifically asked.
4. If suggesting exercises, stick to common ones or those likely in a typical gym.
""";

    try {
      String response = await _getGeminiResponse(prompt);
      _addMessage(_geminiUser, response);
    } catch (e) {
      print("Error processing message: $e");
      _addMessage(_geminiUser, "I apologize, but I couldn't process your request at the moment. Could you please try rephrasing your question?");
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _addMessage(ChatUser user, String text) {
    if (mounted) {
      setState(() {
        _messages.insert(0, ChatMessage(
          user: user,
          createdAt: DateTime.now(),
          text: text,
        ));
      });
    }
  }

  Future<void> _createWorkoutPlan() async {
    String bodyPart = await _showInputDialog("Body part to focus on");
    if (bodyPart.isEmpty) return;

    String preferences = await _showInputDialog("Any preferences?");
    if (preferences.isEmpty) return;

    _handleWorkoutPlanCreation(bodyPart, preferences);
  }

  Future<String> _showInputDialog(String hintText) async {
    String input = '';
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Create Workout Plan'),
          content: TextField(
            decoration: InputDecoration(hintText: hintText),
            onChanged: (value) {
              input = value;
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
    return input;
  }

  Future<void> _handleWorkoutPlanCreation(String bodyPart, String preferences) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final String exerciseList = _availableExercises.map((e) => e['title']).join(", ");
    final String prompt = _generateWorkoutPrompt(bodyPart, preferences, exerciseList);

    try {
      String workoutPlanText = await _getGeminiResponse(prompt);
      print("Gemini response:\n$workoutPlanText");

      List<Map<String, dynamic>> exercises = _parseWorkoutPlan(workoutPlanText);
      
      if (exercises.isEmpty) {
        throw FormatException('No valid exercises generated');
      }

      String sessionName = "Workout for $bodyPart";
      
      Session newSession = Session.withTitle(sessionName);
      for (var exercise in exercises) {
        newSession.addExercise(exercise['title']);
        for (int i = 0; i < exercise['sets']; i++) {
          newSession.addReps(exercise['title'], 0);
          newSession.addWeight(exercise['title'], 0);
        }
      }

      DocumentReference<Object?>? sessionDoc = await _createFirebaseSession(newSession);

      if (sessionDoc != null) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SessionPage(
                session: newSession,
                sessionID: sessionDoc.id,
                sessionFirestore: SessionFirestore(userID: _auth.currentUser!.uid),
              ),
            ),
          );
        }

        _addMessage(_geminiUser, "I've created a workout plan focused on $bodyPart, tailored to your goals and profile. You can now edit and customize it as you like.");
      }
    } catch (e) {
      print("Error processing workout plan: $e");
      _addMessage(_geminiUser, "I'm sorry, I encountered an error while creating your workout plan. Could you try simplifying your request or specifying fewer preferences?");
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  String _generateWorkoutPrompt(String bodyPart, String preferences, String exerciseList) {
    String goals = _userProfile['fitnessProfile']['fitnessGoals'].join(', ');
    int feet = _userProfile['fitnessProfile']['height']['feet'];
    int inches = _userProfile['fitnessProfile']['height']['inches'];
    int weight = _userProfile['fitnessProfile']['weight'];
    int yearStarted = _userProfile['fitnessProfile']['yearStarted'];

    return """
Create a personalized workout plan based on the following user profile and preferences:
Height: $feet'$inches"
Weight: $weight lbs
Training since: $yearStarted
Goals: $goals
Body part focus: $bodyPart
Preferences: $preferences

Available exercises: $exerciseList

Instructions:
1. Suggest 4-6 exercises from the available list, focusing on $bodyPart and considering the user's goals and preferences.
2. For each exercise, suggest the number of sets (3-5).
3. Format your response as a simple list, with each line containing:
   Exercise name | Number of sets

Example output:
Bench Press | 3
Squats | 4
...

Only include exercises from the provided 'Available exercises' list.
Ensure the exercises and parameters are appropriate for the user's goals, experience level, and preferences.
""";
  }

  Future<DocumentReference<Object?>?> _createFirebaseSession(Session session) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        return await _firestore.collection('users').doc(user.uid).collection('sessions').add(session.toJson());
      }
    } catch (e) {
      print("Error creating Firebase session: $e");
    }
    return null;
  }

  Map<String, dynamic>? _fuzzyMatchExercise(String exerciseTitle) {
    String cleanTitle = exerciseTitle.replaceFirst(RegExp(r'^[-\d.]\s*'), '').trim();
    String lowerTitle = cleanTitle.toLowerCase();
    
    for (var exercise in _availableExercises) {
      if (exercise['title'].toLowerCase() == lowerTitle) {
        return exercise;
      }
    }

    for (var exercise in _availableExercises) {
      if (exercise['title'].toLowerCase().contains(lowerTitle) || 
          lowerTitle.contains(exercise['title'].toLowerCase())) {
        return exercise;
      }
    }

    return null;
  }

  List<Map<String, dynamic>> _parseWorkoutPlan(String planText) {
    List<Map<String, dynamic>> exercises = [];
    List<String> lines = planText.split('\n');
    
    print("Parsing workout plan:");
    for (String line in lines) {
      print("Processing line: $line");
      String cleanLine = line.replaceFirst(RegExp(r'^[-•\d.]\s*'), '').trim();
      List<String> parts = cleanLine.split('|').map((part) => part.trim()).toList();
      if (parts.length == 2) {
        String exerciseTitle = parts[0];
        int? sets = int.tryParse(parts[1]);
        
        print("Exercise: $exerciseTitle, Sets: $sets");
        
        if (sets != null && sets > 0) {
          Map<String, dynamic>? matchedExercise = _fuzzyMatchExercise(exerciseTitle);
          if (matchedExercise != null) {
            exercises.add({
              "title": matchedExercise['title'],
              "sets": sets,
            });
            print("Added exercise: ${matchedExercise['title']} with $sets sets");
          } else {
            print("Skipped exercise: $exerciseTitle (not found in available exercises)");
          }
        } else {
          print("Skipped exercise: $exerciseTitle (invalid number of sets)");
        }
      } else {
        print("Skipped line: invalid format");
      }
    }
    
    print("Parsed exercises: $exercises");
    return exercises;
  }

  Future<String> _getGeminiResponse(String prompt) async {
    String response = '';
    await for (var event in _gemini.streamGenerateContent(prompt)) {
      response += event.content?.parts?.map((part) => part.text).join(" ") ?? '';
    }
    return response.trim();
  }

  Future<void> _generateRecommendation(Map<String, List<Map<String, dynamic>>> fetchedData) async {
    if (!mounted) return;
    const String prompt = """
Generate a concise recommendation (30 words or less) for the user's next workout session based on their exercise data.
Be motivational and focus on progress or variety. Avoid suggesting specific exercises.

Exercise Data:
""";

    try {
      String generatedRecommendation = await _getGeminiResponse(prompt + json.encode(fetchedData));
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
          _recommendation = "Let's focus on your fitness journey. What would you like to work on today?";
        });
      }
    }
  }

  void _getTip() {
    _handleUserMessage(ChatMessage(
      user: _currentUser,
      text: "Give me a quick workout tip!",
      createdAt: DateTime.now(),
    ));
  }
}