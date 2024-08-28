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

  const ExerciseAnalyticsCard({super.key, required this.exercise, required this.metric});

  @override
  _ExerciseAnalyticsCardState createState() => _ExerciseAnalyticsCardState();
}

class _ExerciseAnalyticsCardState extends State<ExerciseAnalyticsCard> {
  late SessionFirestore sessionFirestore;
  List<Map<String, dynamic>> exerciseData = [];
  bool isLoading = true;
  double targetValue = 0;

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
          double maxValue = _calculateMaxValue(fetchedData);
          targetValue = (maxValue * 1.1 / 5).round() * 5; // Round to nearest 5
        } else {
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  double _calculateMaxValue(List<Map<String, dynamic>> data) {
    return data.map((session) {
      List<dynamic> repsList = session['reps'];
      List<dynamic> weightsList = session['weights'];
      double highestValue = 0;
      
      if (widget.metric == 'Sets') {
        return repsList.length.toDouble(); // Count of sets
      } else {
        for (int i = 0; i < repsList.length; i++) {
          int reps = repsList[i];
          double weight = weightsList[i].toDouble();
          double value = _calculateMetricValue(reps, weight);
          if (value > highestValue) {
            highestValue = value;
          }
        }
      }
      return highestValue;
    }).reduce((a, b) => a > b ? a : b);
  }

  double _calculateMetricValue(int reps, double weight) {
    switch (widget.metric) {
      case '1RM':
        return weight * (1 + reps / 30);
      case 'Volume':
        return reps * weight;
      case 'Reps':
        return reps.toDouble();
      case 'Sets':
        return 1; // Each entry represents a set
      default:
        return 0;
    }
  }

  LineChartData _generateChartData() {
    Map<DateTime, double> valuePerDate = {};

    for (var data in exerciseData) {
      List<dynamic> repsList = data['reps'];
      List<dynamic> weightsList = data['weights'];
      var date = data['date'];

      if (date != null && date is Timestamp) {
        DateTime sessionDate = date.toDate();
        double sessionValue = 0;

        for (int i = 0; i < repsList.length; i++) {
          int reps = repsList[i];
          double weight = weightsList[i].toDouble();
          double value = _calculateMetricValue(reps, weight);

          if (widget.metric == 'Sets') {
            sessionValue += 1;
          } else if (widget.metric == 'Reps') {
            sessionValue += reps;
          } else {
            sessionValue = math.max(sessionValue, value);
          }
        }

        if (widget.metric == 'Reps') {
          sessionValue /= repsList.length; // Average reps per set
        }

        valuePerDate[sessionDate] = sessionValue;
      }
    }

    // Sort the data points chronologically
    List<MapEntry<DateTime, double>> sortedEntries = valuePerDate.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    List<FlSpot> spots = sortedEntries
        .map((entry) => FlSpot(entry.key.millisecondsSinceEpoch.toDouble(), entry.value))
        .toList();

    if (spots.isEmpty) {
      return LineChartData(
        lineBarsData: [LineChartBarData(spots: [FlSpot(0, 0)])],
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: false),
      );
    }

    double minX = spots.map((e) => e.x).reduce(math.min);
    double maxX = spots.map((e) => e.x).reduce(math.max);
    double minY = math.min(spots.map((e) => e.y).reduce(math.min), 0);
    double maxY = math.max(spots.map((e) => e.y).reduce(math.max), targetValue);

    // Adjust Y-axis scale
    double yRange = maxY - minY;
    minY = math.max(0, minY - yRange * 0.1);
    maxY = maxY + yRange * 0.1;

    // Round minY and maxY for non-1RM metrics
    if (widget.metric != '1RM') {
      minY = minY.floor().toDouble();
      maxY = maxY.ceil().toDouble();
    }

    // Generate y-axis labels
    List<double> yLabels = _generateYLabels(minY, maxY);

    return LineChartData(
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: false,  // Change this to false
          barWidth: 3,
          colors: [Colors.blue],
          dotData: FlDotData(show: true),
          belowBarData: BarAreaData(show: false),
        ),
      ],
      titlesData: FlTitlesData(
        leftTitles: SideTitles(
          showTitles: true,
          getTitles: (value) => _formatYLabel(value),
          reservedSize: 40,
          interval: (yLabels.last - yLabels.first) / (yLabels.length - 1),
        ),
        bottomTitles: SideTitles(
          showTitles: true,
          getTitles: (value) => DateFormat('MM/dd').format(DateTime.fromMillisecondsSinceEpoch(value.toInt())),
          reservedSize: 22,
          interval: (maxX - minX) / 5,
        ),
      ),
      borderData: FlBorderData(show: true),
      gridData: FlGridData(show: true),
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
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

  List<double> _generateYLabels(double minY, double maxY) {
    int desiredLabelCount = 5;
    double interval;
    
    if (widget.metric == '1RM') {
      interval = (maxY - minY) / (desiredLabelCount - 1);
    } else if (widget.metric == 'Volume') {
      interval = ((maxY - minY) / (desiredLabelCount - 1) / 5).ceil() * 5;
    } else { // 'Reps' or 'Sets'
      interval = ((maxY - minY) / (desiredLabelCount - 1)).ceil().toDouble();
    }

    return List.generate(desiredLabelCount, (index) {
      double value = minY + index * interval;
      if (widget.metric == 'Volume') {
        return (value / 5).ceil() * 5;
      } else if (widget.metric != '1RM') {
        return value.ceil().toDouble();
      }
      return value;
    });
  }

  String _formatYLabel(double value) {
    if (widget.metric == '1RM') {
      return value.toStringAsFixed(1);
    } else {
      return value.toInt().toString();
    }
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
                    targetValue = newTarget;
                  });
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    ).then((_) => setState(() {})); // Trigger rebuild after dialog closes
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
                IconButton(
                  icon: const Icon(Icons.adjust),
                  onPressed: () {
                    _showTargetInputDialog(context);
                  },
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
                          SizedBox(
                            height: 300,
                            child: LineChart(_generateChartData()),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Target: ${widget.metric == "1RM" || widget.metric == "Volume" ? targetValue.toInt() : targetValue.toStringAsFixed(1)} ${widget.metric == "Reps" || widget.metric == "Sets" ? "" : "pounds"}',
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