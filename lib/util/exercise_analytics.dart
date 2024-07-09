import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:Palestra/services/session_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class ExerciseAnalyticsCard extends StatefulWidget {
  final String exercise;
  final String metric;
  final VoidCallback onRemove;

  const ExerciseAnalyticsCard({super.key, required this.exercise, required this.metric, required this.onRemove});

  @override
  _ExerciseAnalyticsCardState createState() => _ExerciseAnalyticsCardState();
}

class _ExerciseAnalyticsCardState extends State<ExerciseAnalyticsCard> {
  late SessionFirestore sessionFirestore;
  List<Map<String, dynamic>> exerciseData = [];
  bool isLoading = true;
  double targetValue = 0; // Example target value for 1RM or volume

  @override
  void initState() {
    super.initState();
    _initializeSessionFirestore();
    _fetchExerciseData(widget.exercise);
  }

  void _initializeSessionFirestore() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      sessionFirestore = SessionFirestore(userID: user.uid);
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _fetchExerciseData(String exercise) async {
    setState(() {
      isLoading = true;
    });
    try {
      List<Map<String, dynamic>> fetchedData = await sessionFirestore.fetchExerciseData(exercise);
      setState(() {
        exerciseData = fetchedData;
        isLoading = false;
        if (fetchedData.isNotEmpty) {
          double maxValue = fetchedData
              .map((data) {
                List<dynamic> repsList = data['reps'];
                List<dynamic> weightsList = data['weights'];
                double highestValue = 0;
                for (int i = 0; i < repsList.length; i++) {
                  int reps = repsList[i];
                  double weight = weightsList[i].toDouble();
                  double value = widget.metric == "1RM" ? weight * (1 + reps / 30) : weight * reps;
                  if (value > highestValue) {
                    highestValue = value;
                  }
                }
                return highestValue;
              })
              .reduce((a, b) => a > b ? a : b);
          targetValue = (maxValue * 1.05).roundToDouble();
          targetValue = (targetValue / 5).round() * 5; // Round to nearest 5 or 0
        }
      });
    } catch (e) {
      print("Error fetching exercise data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  LineChartData _generateChartData() {
    Map<String, double> highestValuePerDate = {};

    for (var data in exerciseData) {
      List<dynamic> repsList = data['reps'];
      List<dynamic> weightsList = data['weights'];
      var date = data['date'];

      if (date != null && date is Timestamp) {
        String formattedDate = DateFormat('yyyy-MM-dd').format(date.toDate());

        for (int i = 0; i < repsList.length; i++) {
          int reps = repsList[i];
          double weight = weightsList[i].toDouble();
          double value = widget.metric == "1RM" ? weight * (1 + reps / 30) : weight * reps;

          if (highestValuePerDate.containsKey(formattedDate)) {
            if (value > highestValuePerDate[formattedDate]!) {
              highestValuePerDate[formattedDate] = value;
            }
          } else {
            highestValuePerDate[formattedDate] = value;
          }
        }
      }
    }

    List<FlSpot> spots = highestValuePerDate.entries
        .map((entry) => FlSpot(DateFormat('yyyy-MM-dd').parse(entry.key).millisecondsSinceEpoch.toDouble(), entry.value))
        .toList();

    if (spots.isEmpty) {
      return LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: [FlSpot(0, 0)],
            isCurved: false,
            barWidth: 2,
            colors: [Colors.transparent], // Make it transparent
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: SideTitles(showTitles: false),
          bottomTitles: SideTitles(showTitles: false),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: false),
      );
    }

    double minX = spots.map((e) => e.x).reduce(math.min);
    double maxX = spots.map((e) => e.x).reduce(math.max);
    double minY = spots.map((e) => e.y).reduce(math.min);
    double maxY = spots.map((e) => e.y).reduce(math.max);

    double interval;
    String Function(double) dateFormatter;

    if (maxX - minX <= const Duration(days: 7).inMilliseconds) {
      interval = const Duration(days: 1).inMilliseconds.toDouble();
      dateFormatter = (value) => DateFormat('M/d').format(DateTime.fromMillisecondsSinceEpoch(value.toInt()));
    } else if (maxX - minX <= const Duration(days: 30).inMilliseconds) {
      interval = const Duration(days: 7).inMilliseconds.toDouble();
      dateFormatter = (value) => DateFormat('M/d').format(DateTime.fromMillisecondsSinceEpoch(value.toInt()));
    } else if (maxX - minX <= const Duration(days: 365).inMilliseconds) {
      interval = const Duration(days: 30).inMilliseconds.toDouble();
      dateFormatter = (value) => DateFormat('MMM').format(DateTime.fromMillisecondsSinceEpoch(value.toInt()));
    } else {
      interval = const Duration(days: 365).inMilliseconds.toDouble();
      dateFormatter = (value) => DateFormat('yyyy').format(DateTime.fromMillisecondsSinceEpoch(value.toInt()));
    }

    return LineChartData(
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: false,
          barWidth: 2,
          colors: [Colors.blue],
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      ],
      titlesData: FlTitlesData(
        leftTitles: SideTitles(
          showTitles: true,
          getTitles: (value) => value.toInt().toString(),
          reservedSize: 40,
          interval: (maxY - minY) / 5,
        ),
        bottomTitles: SideTitles(
          showTitles: true,
          getTitles: dateFormatter,
          interval: interval,
        ),
      ),
      borderData: FlBorderData(show: true),
      gridData: FlGridData(
        show: true,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey,
            strokeWidth: 0.5,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: Colors.grey,
            strokeWidth: 0.5,
          );
        },
      ),
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: math.max(targetValue, maxY) + 10,
      extraLinesData: ExtraLinesData(horizontalLines: [
        HorizontalLine(
          y: targetValue,
          color: Colors.red,
          strokeWidth: 2,
          dashArray: [5, 5],
        ),
      ]),
    );
  }

  void _showTargetInputDialog(BuildContext context) {
    TextEditingController controller = TextEditingController(text: targetValue.toString());
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Set Target ${widget.metric}'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Target ${widget.metric}'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                double? newTarget = double.tryParse(controller.text);
                if (newTarget != null && newTarget > 0) {
                  setState(() {
                    targetValue = (newTarget / 5).round() * 5; // Round to nearest 5 or 0
                  });
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      color: Colors.grey[300],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${widget.exercise}: ${widget.metric}",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.adjust),
                      onPressed: () {
                        _showTargetInputDialog(context);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: widget.onRemove,
                    ),
                  ],
                ),
              ],
            ),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : exerciseData.isEmpty
                    ? const Center(child: Text('No data available for selected exercise'))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: SizedBox(
                              height: 300, // Define a fixed height for the chart
                              child: LineChart(_generateChartData()),
                            ),
                          ),
                          Text(
                            'Target: $targetValue pounds',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
          ],
        ),
      ),
    );
  }
}
