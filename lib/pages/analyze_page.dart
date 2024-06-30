import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:Palestra/services/session_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnalyzePage extends StatefulWidget {
  @override
  _AnalyzePageState createState() => _AnalyzePageState();
}

class _AnalyzePageState extends State<AnalyzePage> {
  late SessionFirestore sessionFirestore;
  List<Map<String, dynamic>> exercises = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeSessionFirestore();
  }

  void _initializeSessionFirestore() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      sessionFirestore = SessionFirestore(userID: user.uid);
      _fetchExercises();
    } else {
      // Handle user not being logged in
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchExercises() async {
    try {
      List<Map<String, dynamic>> fetchedExercises = await sessionFirestore.getExercises();
      setState(() {
        exercises = fetchedExercises;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching exercises: $e");
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

    return LineChartData(
      lineBarsData: [
        LineChartBarData(
          spots: repsSpots,
          isCurved: true,
          barWidth: 2,
          colors: [Colors.blue],
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      ],
      titlesData: FlTitlesData(
        leftTitles: SideTitles(showTitles: true, getTitles: (value) => value.toInt().toString()),
        bottomTitles: SideTitles(showTitles: true, getTitles: (value) => (value + 1).toInt().toString()),
      ),
      borderData: FlBorderData(show: true),
      gridData: FlGridData(show: true),
    );
  }

  LineChartData _generateWeightsChartData(Map<String, dynamic> exercise) {
    List<FlSpot> weightSpots = [];

    for (int i = 0; i < exercise['weights'].length; i++) {
      weightSpots.add(FlSpot(i.toDouble(), exercise['weights'][i].toDouble()));
    }

    return LineChartData(
      lineBarsData: [
        LineChartBarData(
          spots: weightSpots,
          isCurved: true,
          barWidth: 2,
          colors: [Colors.red],
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      ],
      titlesData: FlTitlesData(
        leftTitles: SideTitles(showTitles: true, getTitles: (value) => value.toInt().toString()),
        bottomTitles: SideTitles(showTitles: true, getTitles: (value) => (value + 1).toInt().toString()),
      ),
      borderData: FlBorderData(show: true),
      gridData: FlGridData(show: true),
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
          
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            exercises[index]['title'],
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Reps',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          SizedBox(
                            height: 200,
                            child: LineChart(_generateRepsChartData(exercises[index])),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Weights',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          SizedBox(
                            height: 200,
                            child: LineChart(_generateWeightsChartData(exercises[index])),
                          ),
                          SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _buildStats(exercises[index]),
                          ),
                          SizedBox(height: 16),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
