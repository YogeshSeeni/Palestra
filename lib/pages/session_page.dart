import 'package:Palestra/components/exercise_tile.dart';
import 'package:Palestra/data/workout_data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SessionPage extends StatefulWidget {
  final String sessionName;
  const SessionPage({super.key, required this.sessionName});

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}