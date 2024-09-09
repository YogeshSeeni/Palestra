import 'package:Palestra/pages/analyze_exercise_page.dart';
import 'package:Palestra/services/session_firestore.dart';
import 'package:Palestra/util/workouts_per_week.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnalyzePage extends StatefulWidget {
  const AnalyzePage({super.key});

  @override
  State<AnalyzePage> createState() => _AnalyzePageState();
}

class _AnalyzePageState extends State<AnalyzePage> {
  User? currentUser;
  SessionFirestore? sessionFirestore;
  Map<String, int> uniqueExercises = {};
  List<String> filteredExercises = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    refreshUser();
  }

  void refreshUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
      currentUser = FirebaseAuth.instance.currentUser;
      sessionFirestore = SessionFirestore(userID: currentUser!.uid);

      await fetchExercises();
    }
  }

  Future<void> fetchExercises() async {
    setState(() {
      isLoading = true;
    });

    uniqueExercises = await sessionFirestore!.fetchUniqueExercisesWithCount();
    filterExercises();

    setState(() {
      isLoading = false;
    });
  }

  void filterExercises() {
    filteredExercises = uniqueExercises.entries
        .where((entry) => entry.value >= 3 && 
                          entry.key.toLowerCase().contains(searchQuery.toLowerCase()))
        .map((entry) => entry.key)
        .toList();
    filteredExercises.sort();
  }

  void updateSearchQuery(String query) {
    setState(() {
      searchQuery = query;
      filterExercises();
    });
  }

  Widget _buildSearchBar(bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? 6.0 : 8.0),
      child: TextField(
        onChanged: updateSearchQuery,
        decoration: InputDecoration(
          labelText: 'Search exercises',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[200],
          contentPadding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 8 : 12,
            horizontal: isSmallScreen ? 12 : 16,
          ),
        ),
      ),
    );
  }

  void _showExerciseSelectionDialog(bool isSmallScreen) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Select an Exercise',
            style: TextStyle(fontSize: isSmallScreen ? 18 : 20),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSearchBar(isSmallScreen),
                Expanded(
                  child: filteredExercises.isEmpty
                    ? Center(
                        child: Text(
                          'You don\'t have enough data to analyze yet. Try tracking some workouts!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredExercises.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(
                              filteredExercises[index],
                              style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AnalyzeExercisePage(
                                    exerciseName: filteredExercises[index],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isSmallScreen = constraints.maxHeight < 700;
          return _buildContent(isSmallScreen);
        },
      ),
    );
  }

  Widget _buildContent(bool isSmallScreen) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Analyze",
              style: TextStyle(
                fontSize: isSmallScreen ? 22 : 25,
                fontWeight: FontWeight.bold
              ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            const WorkoutsPerWeekCard(),
            SizedBox(height: isSmallScreen ? 12 : 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 20 : 24,
                  vertical: isSmallScreen ? 12 : 16
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                ),
              ),
              onPressed: isLoading ? null : () => _showExerciseSelectionDialog(isSmallScreen),
              child: Text(
                'Perform an AI-powered analysis on an exercise',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  color: Colors.black,
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
          ],
        ),
      ),
    );
  }
}