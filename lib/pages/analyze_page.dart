import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class AnalyzePage extends StatefulWidget {
  @override
  _AnalyzePageState createState() => _AnalyzePageState();
}

class _AnalyzePageState extends State<AnalyzePage> with AutomaticKeepAliveClientMixin {
  List<WidgetData> widgetsData = [];

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Analyze',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.add, color: Colors.white),
                  label: Text(
                    'Widget',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                  onPressed: _showAddWidgetDialog,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: widgetsData.length,
              itemBuilder: (context, index) {
                return widgetsData[index].buildCard(() {
                  setState(() {
                    widgetsData.removeAt(index);
                  });
                }, context, () {
                  setState(() {});
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddWidgetDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Add Widget', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Divider(),
                ListTile(
                  title: Text('Workouts Per Week'),
                  subtitle: Text('Display workout consistency'),
                  onTap: () {
                    setState(() {
                      widgetsData.add(WorkoutsPerWeekData());
                    });
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: Text('Exercise Analytics'),
                  subtitle: Text('Track specific exercises'),
                  onTap: () {
                    setState(() {
                      widgetsData.add(ExerciseAnalyticsData());
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

abstract class WidgetData {
  Widget buildCard(VoidCallback onRemove, BuildContext context, VoidCallback updateState);
}

class WorkoutsPerWeekData extends WidgetData {
  int targetWorkouts = 4; // Changed to int

  @override
  Widget buildCard(VoidCallback onRemove, BuildContext context, VoidCallback updateState) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      color: Colors.grey[300],
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .collection('sessions')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
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
                    Text(
                      'Workouts Per Week',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.adjust),
                          onPressed: () {
                            _showTargetInputDialog(context, updateState);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: onRemove,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showTargetInputDialog(BuildContext context, VoidCallback updateState) {
    TextEditingController controller = TextEditingController(text: targetWorkouts.toString());
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Set Target Workouts'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Target workouts per week'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                int? newTarget = int.tryParse(controller.text);
                if (newTarget != null && newTarget > 0) {
                  targetWorkouts = newTarget;
                  updateState();
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class ExerciseAnalyticsData extends WidgetData {
  @override
  Widget buildCard(VoidCallback onRemove, BuildContext context, VoidCallback updateState) {
    // Implement the desired functionality here later.
    return Container();
  }
}