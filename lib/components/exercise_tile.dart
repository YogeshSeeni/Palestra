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

  @override
  void initState() {
    super.initState();
    if (widget.session)
    sets.add(createSetRow(1));
  }

  void updateWeight(int setNumber, int weight) async {
    widget.session.updateWeight(widget.exerciseName, weight, setNumber - 1);
    await widget.sessionFirestore?.updateSession(widget.session, widget.sessionID);
  }

  void updateReps(int setNumber, int reps) async {
    widget.session.updateReps(widget.exerciseName, reps, setNumber - 1);
    await widget.sessionFirestore?.updateSession(widget.session, widget.sessionID);
  }

  Widget createSetRow(int setNumber) {
    //add set to current session
    widget.session.addReps(widget.exerciseName, 0);
    widget.session.addWeight(widget.exerciseName, 0);
    widget.sessionFirestore?.updateSession(widget.session, widget.sessionID);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(setNumber.toString()),
          SizedBox(
            width: 50,
            child: TextField(
              decoration: InputDecoration(hintText: 'lbs'),
              keyboardType: TextInputType.number,
              onChanged: (weight) => {updateWeight(setNumber, int.parse(weight))},
            ),
          ),
          SizedBox(
            width: 50,
            child: TextField(
              decoration: InputDecoration(hintText: 'reps'),
              keyboardType: TextInputType.number,
              onChanged: (reps) => {updateReps(setNumber, int.parse(reps))},
            ),
          ),
        ],
      ),
    );
  }

  void addSet() {
    setState(() {
      sets.add(createSetRow(sets.length + 1));
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
