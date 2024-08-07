import 'package:Palestra/components/exercise_list_dialog.dart';
import 'package:Palestra/components/exercise_tile.dart';
import 'package:Palestra/models/session.dart';
import 'package:Palestra/services/session_firestore.dart';
import 'package:flutter/material.dart';

class SessionPage extends StatefulWidget {
  final Session session;
  final String sessionID;
  final SessionFirestore sessionFirestore;
  final bool isTemplate;

  const SessionPage({
    super.key,
    required this.session,
    required this.sessionID,
    required this.sessionFirestore,
    this.isTemplate = false,
  });

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  void createNewExercise() {
    showDialog(
      context: context,
      builder: (context) => ExerciseListDialog(
        sessionName: widget.session.title,
        onExerciseAdded: (exerciseTitle) {
          setState(() {
            widget.session.addExercise(exerciseTitle);
            widget.sessionFirestore.updateSession(widget.session, widget.sessionID);
          });
        },
      ),
    );
  }

  void removeExerciseTile(String exerciseName) {
    setState(() {
      widget.session.removeExercise(exerciseName);
      widget.sessionFirestore.updateSession(widget.session, widget.sessionID);
    });
  }

  void _saveTemplate() {
    widget.sessionFirestore.updateSession(widget.session, widget.sessionID);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Template saved successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(
          widget.isTemplate ? widget.session.title : widget.session.title,
          style: const TextStyle(fontSize: 24),
        ),
        backgroundColor: Colors.grey[200],
        actions: [
          if (widget.isTemplate)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveTemplate,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              alignment: Alignment.centerLeft,
              child: const Text(
                "Track Workout",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: createNewExercise,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 15, vertical: 15),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Add New Exercise'),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: widget.session.exercises.isNotEmpty
                  ? ListView.builder(
                      itemCount: widget.session.exercises.length,
                      itemBuilder: (context, index) {
                        final exercise = widget.session.exercises[index];
                        return ExerciseTile(
                          exerciseName: exercise['title'],
                          session: widget.session,
                          sessionFirestore: widget.sessionFirestore,
                          sessionID: widget.sessionID,
                          onRemove: () => removeExerciseTile(exercise['title']),
                        );
                      },
                    )
                  : const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('No exercises added yet.'),
                          SizedBox(height: 240),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}