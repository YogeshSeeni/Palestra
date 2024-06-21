import 'package:flutter/material.dart';

class ExerciseTile extends StatefulWidget {
  final String exerciseName;
  final VoidCallback onRemove;

  const ExerciseTile({
    super.key,
    required this.exerciseName,
    required this.onRemove,
  });

  @override
  _ExerciseTileState createState() => _ExerciseTileState();
}

class _ExerciseTileState extends State<ExerciseTile> {
  List<Widget> sets = [];

  @override
  void initState() {
    super.initState();
    sets.add(createSetRow(1));
  }

  Widget createSetRow(int setNumber) {
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
            ),
          ),
          SizedBox(
            width: 50,
            child: TextField(
              decoration: InputDecoration(hintText: 'reps'),
              keyboardType: TextInputType.number,
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
