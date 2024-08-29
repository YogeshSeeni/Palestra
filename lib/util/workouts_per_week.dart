import 'package:Palestra/services/session_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class WorkoutsPerWeekCard extends StatefulWidget {
  const WorkoutsPerWeekCard({super.key});

  @override
  _WorkoutsPerWeekCardState createState() => _WorkoutsPerWeekCardState();
}

class _WorkoutsPerWeekCardState extends State<WorkoutsPerWeekCard> {
  int targetWorkouts = 4; // Default target
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, dynamic> _userProfile = {};


  @override
  void initState() {
    super.initState();
    getTargetWorkouts();
  }

  void getTargetWorkouts() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .get();
    
    if (userDoc.exists) {
      _userProfile = userDoc.data() as Map<String, dynamic>;

      setState(() {
        targetWorkouts = _userProfile['fitnessProfile']['workoutDaysPerWeek'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      color: Colors.grey[300],
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .collection('sessions')
            .where('isTemplate', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          Map<String, int> workoutsPerWeek = {};
          DateTime today = DateTime.now();
          DateTime startOfWeek = today.subtract(Duration(days: today.weekday - 1));

          for (int i = 3; i >= 0; i--) {
            DateTime week = startOfWeek.subtract(Duration(days: i * 7));
            String weekLabel = DateFormat('M/d').format(week);
            workoutsPerWeek[weekLabel] = 0;
          }

          for (var doc in snapshot.data!.docs) {
            DateTime date = (doc['date'] as Timestamp).toDate();
            DateTime firstDayOfWeek = date.subtract(Duration(days: date.weekday - 1));
            String weekLabel = DateFormat('M/d').format(firstDayOfWeek);
            if (workoutsPerWeek.containsKey(weekLabel)) {
              workoutsPerWeek[weekLabel] = workoutsPerWeek[weekLabel]! + 1;
            }
          }

          int maxYValue = math.max(workoutsPerWeek.values.reduce((a, b) => a > b ? a : b), targetWorkouts) + 2;

          List<BarChartGroupData> barData = workoutsPerWeek.entries.map((entry) {
            return BarChartGroupData(
              x: workoutsPerWeek.keys.toList().indexOf(entry.key),
              barRods: [BarChartRodData(y: entry.value.toDouble(), width: 20, borderRadius: BorderRadius.zero)],
            );
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Workouts Per Week',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      maxY: maxYValue.toDouble(),
                      barGroups: barData,
                      titlesData: FlTitlesData(
                        leftTitles: SideTitles(showTitles: true),
                        bottomTitles: SideTitles(
                          showTitles: true,
                          margin: 8,
                          getTitles: (value) {
                            return workoutsPerWeek.keys.toList()[value.toInt()];
                          },
                        ),
                      ),
                      barTouchData: BarTouchData(enabled: true),
                      alignment: BarChartAlignment.spaceAround,
                      gridData: FlGridData(
                        show: true,
                        getDrawingHorizontalLine: (value) {
                          if (value == targetWorkouts) {
                            return FlLine(
                              color: Colors.red,
                              strokeWidth: 2,
                              dashArray: [5, 5],
                            );
                          }
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
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Target: $targetWorkouts workouts per week',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
