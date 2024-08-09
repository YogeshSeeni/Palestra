import 'package:Palestra/services/gemini_service.dart';
import 'package:Palestra/services/session_firestore.dart';
import 'package:Palestra/util/exercise_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyzeExercisePage extends StatefulWidget {
  final String exerciseName;
  const AnalyzeExercisePage({super.key, required this.exerciseName});

  @override
  State<AnalyzeExercisePage> createState() => _AnalyzeExercisePageState();
}

class _AnalyzeExercisePageState extends State<AnalyzeExercisePage> {
  late SessionFirestore sessionFirestore;
  late GeminiService geminiService;
  late String advice = "";
  Map<String, dynamic> exerciseData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    geminiService = GeminiService();
    getExerciseData();
  }

  void getExerciseData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      sessionFirestore = SessionFirestore(userID: user.uid);
      exerciseData = await sessionFirestore.getExercise(widget.exerciseName);
      advice = await geminiService.exerciseTip(widget.exerciseName, exerciseData);

      setState(() {
        advice = advice;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  LineChartData _generateRepsChartData(Map<String, dynamic> exercise) {
    List<FlSpot> repsSpots = [];

    for (int i = 0; i < exercise['reps'].length; i++) {
      repsSpots.add(FlSpot(i.toDouble(), exercise['reps'][i].toDouble()));
    }

    double maxY = exercise['reps'].reduce((a, b) => a > b ? a : b).toDouble() + 2;

    return LineChartData(
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: repsSpots,
          isCurved: true,
          barWidth: 4,
          colors: [Colors.blue],
          dotData: FlDotData(show: true),
          belowBarData: BarAreaData(show: false),
        ),
      ],
      titlesData: FlTitlesData(
        leftTitles: SideTitles(
          showTitles: true,
          interval: 1,
        ),
        bottomTitles: SideTitles(
          showTitles: false, // Hide x-axis ticks
          interval: 1,
        ),
      ),
      gridData: FlGridData(
        show: true,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey,
            strokeWidth: 0.5,
          );
        },
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey, width: 1),
      ),
    );
  }

  LineChartData _generateWeightsChartData(Map<String, dynamic> exercise) {
    List<FlSpot> weightSpots = [];

    for (int i = 0; i < exercise['weights'].length; i++) {
      weightSpots.add(FlSpot(i.toDouble(), exercise['weights'][i].toDouble()));
    }

    double maxY = exercise['weights'].reduce((a, b) => a > b ? a : b).toDouble() + 10;

    return LineChartData(
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: weightSpots,
          isCurved: true,
          barWidth: 4,
          colors: [Colors.red],
          dotData: FlDotData(show: true),
          belowBarData: BarAreaData(show: false),
        ),
      ],
      titlesData: FlTitlesData(
        leftTitles: SideTitles(
          showTitles: true,
          interval: 10,
        ),
        bottomTitles: SideTitles(
          showTitles: false, // Hide x-axis ticks
          interval: 1,
        ),
      ),
      gridData: FlGridData(
        show: true,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey,
            strokeWidth: 0.5,
          );
        },
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey, width: 1),
      ),
    );
  }

  Widget _buildStats(Map<String, dynamic> exercise) {
    int totalReps = exercise['reps'].reduce((a, b) => a + b);
    int totalWeight = exercise['weights'].reduce((a, b) => a + b);
    int numberOfSets = exercise['reps'].length;
    double averageReps = totalReps / numberOfSets;
    double averageWeight = totalWeight / numberOfSets;
    int maxReps = exercise['reps'].reduce((a, b) => a > b ? a : b);
    int maxWeight = exercise['weights'].reduce((a, b) => a > b ? a : b);
    double estimated1RM = maxWeight * (1 + maxReps / 30.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Reps: $totalReps', style: TextStyle(fontSize: 16)),
          Text('Total Sets: $numberOfSets', style: TextStyle(fontSize: 16)),
          Text('Total Weight Lifted: $totalWeight lb', style: TextStyle(fontSize: 16)),
          Text('Average Reps per Set: ${averageReps.toStringAsFixed(2)}', style: TextStyle(fontSize: 16)),
          Text('Average Weight per Set: ${averageWeight.toStringAsFixed(2)} lb', style: TextStyle(fontSize: 16)),
          Text('Max Reps in a Single Set: $maxReps', style: TextStyle(fontSize: 16)),
          Text('Max Weight in a Single Set: $maxWeight lb', style: TextStyle(fontSize: 16)),
          Text('Estimated 1 Rep Max: $estimated1RM lb', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exerciseName + " Analysis", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.grey[200],
        scrolledUnderElevation: 0.0,
      ),
      backgroundColor: Colors.grey[200],
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Personalized Tips by Palestra AI',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    advice
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Reps over Time',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(8.0), // Even padding
                    decoration: BoxDecoration(
                      color: Colors.grey[300], // Background color similar to the bar chart
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: LineChart(_generateRepsChartData(exerciseData)),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Weights over Time',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(8.0), // Even padding
                    decoration: BoxDecoration(
                      color: Colors.grey[300], // Background color similar to the bar chart
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: LineChart(_generateWeightsChartData(exerciseData)),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'General Statistics',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildStats(exerciseData),
                  ),
                  SizedBox(height: 8),
                ],
              ),
            ),
    );
  }
}