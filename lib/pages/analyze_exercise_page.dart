import 'package:Palestra/services/gemini_service.dart';
import 'package:Palestra/services/session_firestore.dart';
import 'package:Palestra/util/exercise_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AnalyzeExercisePage extends StatefulWidget {
  final String exerciseName;
  const AnalyzeExercisePage({super.key, required this.exerciseName});

  @override
  State<AnalyzeExercisePage> createState() => _AnalyzeExercisePageState();
}

class _AnalyzeExercisePageState extends State<AnalyzeExercisePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late SessionFirestore sessionFirestore;
  late GeminiService geminiService;
  String advice = "";
  List<Map<String, dynamic>> exerciseData = [];
  Map<String, dynamic> _userProfile = {};
  String _repsFeedback = "";
  String _setsFeedback = "";
  String _oneRMFeedback = "";
  String _volumeFeedback = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    geminiService = GeminiService();
    _loadUserProfile();
    getExerciseData();
  }

  Future<void> _loadUserProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        _userProfile = userDoc.data() as Map<String, dynamic>;
        print("Loaded user profile: $_userProfile"); // Debug print
        
      });
    }
  }

  void getExerciseData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _loadUserProfile();

      sessionFirestore = SessionFirestore(userID: user.uid);
      exerciseData = await sessionFirestore.fetchExerciseData(widget.exerciseName);

      // Convert Timestamp to ISO8601 string to avoid JSON serialization issues
      List<Map<String, dynamic>> serializedData = exerciseData.map((session) {
        var newSession = Map<String, dynamic>.from(session);
        if (newSession['date'] is Timestamp) {
          newSession['date'] = (newSession['date'] as Timestamp).toDate().toIso8601String();
        }
        return newSession;
      }).toList();

      advice = await geminiService.exerciseAnalysis(
          widget.exerciseName, serializedData, _userProfile);
      _repsFeedback = await geminiService.generateGoalBasedFeedback(
          widget.exerciseName, "Reps", serializedData, _userProfile);
      _setsFeedback = await geminiService.generateGoalBasedFeedback(
          widget.exerciseName, "Sets", serializedData, _userProfile);
      _oneRMFeedback = await geminiService.generateGoalBasedFeedback(
          widget.exerciseName, "1RM", serializedData, _userProfile);
      _volumeFeedback = await geminiService.generateGoalBasedFeedback(
          widget.exerciseName, "Volume", serializedData, _userProfile);

      setState(() {
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildGraphWithFeedback(String title, String metric, String feedback) {
    return Column(
      children: [
        ExerciseAnalyticsCard(exercise: widget.exerciseName, metric: metric),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("$title Feedback",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(feedback, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.exerciseName} Analysis",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.grey[200],
        scrolledUnderElevation: 0.0,
      ),
      backgroundColor: Colors.grey[200],
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'AI-powered Analysis for ${widget.exerciseName}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(advice),
                  const SizedBox(height: 16),
                  _buildGraphWithFeedback('1RM over Time', '1RM', _oneRMFeedback),
                  const SizedBox(height: 16),
                  _buildGraphWithFeedback('Volume over Time', 'Volume', _volumeFeedback),
                  const SizedBox(height: 16),
                  _buildGraphWithFeedback('Reps over Time', 'Reps', _repsFeedback),
                  const SizedBox(height: 16),
                  _buildGraphWithFeedback('Sets over Time', 'Sets', _setsFeedback),
                  const SizedBox(height: 16),
                  _buildEnhancedStats(),
                ],
              ),
            ),
    );
  }
  
  Widget _buildEnhancedStats() {
    if (exerciseData.isEmpty) {
      return const SizedBox.shrink();
    }

    int totalReps = 0;
    int totalWeight = 0;
    int numberOfSets = 0;
    int maxReps = 0;
    int maxWeight = 0;

    for (var session in exerciseData) {
      List<dynamic> reps = session['reps'];
      List<dynamic> weights = session['weights'];
      
      totalReps += reps.fold<int>(0, (sum, rep) => sum + (rep as int));
      totalWeight += weights.fold<int>(0, (sum, weight) => sum + (weight as int));
      numberOfSets += reps.length;
      
      int sessionMaxReps = reps.cast<int>().reduce((a, b) => a > b ? a : b);
      int sessionMaxWeight = weights.cast<int>().reduce((a, b) => a > b ? a : b);
      
      maxReps = maxReps > sessionMaxReps ? maxReps : sessionMaxReps;
      maxWeight = maxWeight > sessionMaxWeight ? maxWeight : sessionMaxWeight;
    }

    double averageReps = totalReps / numberOfSets;
    double averageWeight = totalWeight / numberOfSets;
    double estimated1RM = maxWeight * (1 + maxReps / 30.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performance Metrics',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMetricCard(
                'Total Volume', '$totalWeight lbs', Icons.fitness_center),
            _buildMetricCard(
                'Max Weight', '$maxWeight lbs', Icons.arrow_upward),
            _buildMetricCard('Est. 1RM',
                '${estimated1RM.toStringAsFixed(1)} lbs', Icons.speed),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMetricCard(
                'Avg Reps/Set', averageReps.toStringAsFixed(1), Icons.repeat),
            _buildMetricCard('Avg Weight/Set',
                '${averageWeight.toStringAsFixed(1)} lbs', Icons.scale),
            _buildMetricCard(
                'Total Sets', '$numberOfSets', Icons.format_list_numbered),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return SizedBox(
      width: 100,
      child: Column(
        children: [
          Icon(icon, size: 30),
          const SizedBox(height: 8),
          Text(title,
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
          Text(value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _fetchExerciseData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      SessionFirestore sessionFirestore = SessionFirestore(userID: user.uid);
      List<Map<String, dynamic>> fetchedData = await sessionFirestore.fetchExerciseData(widget.exerciseName);
      
      if (mounted) {
        setState(() {
          exerciseData = fetchedData;
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }
}