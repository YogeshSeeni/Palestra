import 'package:Palestra/models/session.dart';
import 'package:Palestra/services/session_firestore.dart';
import 'package:flutter/material.dart';

class ExerciseTile extends StatefulWidget {
  final String exerciseName;
  final VoidCallback onRemove;
  String sessionID;
  Session session;
  late SessionFirestore? sessionFirestore;

  ExerciseTile({
    super.key,
    required this.exerciseName,
    required this.onRemove,
    required this.sessionID,
    required this.session,
    required this.sessionFirestore
  });

  @override
  _ExerciseTileState createState() => _ExerciseTileState();
}

class _ExerciseTileState extends State<ExerciseTile> {
  List<Widget> sets = [];
  List<dynamic> reps = [];
  List<dynamic> weights = [];

  @override
  void initState() {
    super.initState();

    // Get reps and weights for current exercise
    for (int i = 0; i < widget.session.exercises.length; i++) {
      Map<String, dynamic> exercise = widget.session.exercises[i];

      if (exercise['title'] == widget.exerciseName) {
        reps = exercise['reps'];
        weights = exercise['weights'];
      }
    }

    if (reps.isNotEmpty) {
      for (int i = 0; i < reps.length; i++) {
        sets.add(createSetRow(i + 1, reps[i], weights[i], false));
      }
    } else {
      sets.add(createSetRow(1, 0, 0, true));
    }
  }

  void updateWeight(int setNumber, int weight) async {
    widget.session.updateWeight(widget.exerciseName, weight, setNumber - 1);
    await widget.sessionFirestore?.updateSession(widget.session, widget.sessionID);
  }

  void updateReps(int setNumber, int reps) async {
    widget.session.updateReps(widget.exerciseName, reps, setNumber - 1);
    await widget.sessionFirestore?.updateSession(widget.session, widget.sessionID);
  }

  void removeSet(int setNumber) async {
    widget.session.removeSet(widget.exerciseName, setNumber - 1);
    await widget.sessionFirestore?.updateSession(widget.session, widget.sessionID);
    setState(() {
      sets.removeAt(setNumber - 1);
      // Update remaining set numbers
      for (int i = setNumber - 1; i < sets.length; i++) {
        sets[i] = createSetRow(i + 1, reps[i], weights[i], false);
      }
    });
  }

  Widget createSetRow(int setNumber, int reps, int weight, bool isNew) {
    if (isNew) {
      // Add set to current session
      widget.session.addReps(widget.exerciseName, 0);
      widget.session.addWeight(widget.exerciseName, 0);
      widget.sessionFirestore?.updateSession(widget.session, widget.sessionID);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(setNumber.toString()),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Weight'),
              SizedBox(
                width: 60,
                child: TextField(
                  controller: TextEditingController()..text = weight.toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Weight',
                  ),
                  onChanged: (weight) => {
                    updateWeight(setNumber, int.tryParse(weight) ?? 0)
                  },
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reps'),
              SizedBox(
                width: 60,
                child: TextField(
                  controller: TextEditingController()..text = reps.toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Reps',
                  ),
                  onChanged: (reps) => {
                    updateReps(setNumber, int.tryParse(reps) ?? 0)
                  },
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              removeSet(setNumber);
            },
          ),
        ],
      ),
    );
  }

  void addSet() {
    setState(() {
      sets.add(createSetRow(sets.length + 1, 0, 0, true));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      color: Colors.grey[300],
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.exerciseName,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            SizedBox(height: 16),
            Column(children: sets),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: addSet,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: Text('+ Add Set', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
