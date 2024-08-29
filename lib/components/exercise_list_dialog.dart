import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercise.dart';
import 'package:Palestra/services/exercise_firestore.dart';

class ExerciseListDialog extends StatefulWidget {
  final String sessionName;
  final Function(String) onExerciseAdded;

  const ExerciseListDialog({super.key, required this.sessionName, required this.onExerciseAdded});

  @override
  _ExerciseListDialogState createState() => _ExerciseListDialogState();
}

class _ExerciseListDialogState extends State<ExerciseListDialog> {
  final ExerciseFirestore exerciseFirestore = ExerciseFirestore();
  String searchQuery = '';

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        onChanged: (value) {
          setState(() {
            searchQuery = value.toLowerCase();
          });
        },
        decoration: InputDecoration(
          labelText: 'Search exercises',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[200],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Center(
                child: Text(
                  "Exercises",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildSearchBar(),
              Flexible(
                child: StreamBuilder<List<DocumentSnapshot>>(
                  stream: exerciseFirestore.getExercisesStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      List<DocumentSnapshot> exerciseList = snapshot.data!;
                      
                      List<DocumentSnapshot> filteredList = exerciseList.where((doc) {
                        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                        String title = data['title'].toString().toLowerCase();
                        List<String> primaryMuscles = List<String>.from(data['primaryMuscles'] ?? []);
                        return title.contains(searchQuery) || 
                               primaryMuscles.any((muscle) => muscle.toLowerCase().contains(searchQuery));
                      }).toList();
        
                      if (filteredList.isEmpty) {
                        return const Center(child: Text("No matching exercises"));
                      }
        
                      return ListView.builder(
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          DocumentSnapshot document = filteredList[index];
                          ExerciseInfo exerciseInfo = ExerciseInfo.fromJson(
                              document.data() as Map<String, dynamic>);
                      
                          return ListTile(
                            title: Text(exerciseInfo.title),
                            subtitle: Text(exerciseInfo.primaryMuscles.isNotEmpty ? exerciseInfo.primaryMuscles[0] : 'No primary muscle'),
                            onTap: () {
                              widget.onExerciseAdded(exerciseInfo.title);
                              Navigator.of(context).pop();
                            },
                            trailing: const Icon(Icons.add),
                          );
                        },
                      );
                    } else if (snapshot.hasError) {
                      return const Center(child: Text("Error loading exercises"));
                    } else {
                      return const Center(child: CircularProgressIndicator());
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
