import 'dart:convert';

import 'package:Palestra/services/session_firestore.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  final Gemini gemini = Gemini.instance;
  String exerciseDataString = '';
  List<ChatMessage> messages = [];

  @override
  void initState() {
    super.initState();
    _fetchExerciseData();
  }

  void _fetchExerciseData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final sessionFirestore = SessionFirestore(userID: user.uid);
      Map<String, List<Map<String, dynamic>>> fetchedData = await sessionFirestore.fetchAllExercisesForChatbot();
      exerciseDataString = jsonEncode(fetchedData);
    }
  }

  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  ChatUser geminiUser = ChatUser(id: "1", firstName: "Palestra AI");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return DashChat(currentUser: currentUser, onSend: _sendMessage, messages: messages);
  }

  void _sendMessage(ChatMessage chatMessage) {
    setState(() {
      messages = [chatMessage, ...messages];
    });

    String prompt = """
Context:
The following data represents all the exercise sessions for a user, 
aggregated by exercise title. Each entry includes the date of the session,
the number of repetitions performed, and the weights used. 
This data will be used by the chatbot to provide personalized training advice, track progress, 
and suggest improvements. Respond to the user's query using this data.

Data:
$exerciseDataString

Query: 
$chatMessage.text
""";

    try {
      gemini.streamGenerateContent(prompt).listen((event) {
        ChatMessage? lastMessage = messages.firstOrNull;
        if (lastMessage != null && lastMessage.user == geminiUser) {
          lastMessage = messages.removeAt(0);
          String response = event.content?.parts?.fold("", (previous, current) => "$previous ${current.text}") ?? "";

          lastMessage.text += response;
          setState(() {
            messages = [lastMessage!, ...messages];
          });
        } else {
          String response = event.content?.parts?.fold("", (previous, current) => "$previous ${current.text}") ?? "";
          ChatMessage message = ChatMessage(user: geminiUser, createdAt: DateTime.now(), text: response);

          setState(() {
            messages = [message, ...messages];
          });
        }
      });
    } catch(e) {
      print(e);
    }
  }
}