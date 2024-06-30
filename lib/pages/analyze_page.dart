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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.grey[200], 
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
