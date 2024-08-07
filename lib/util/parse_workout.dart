List<Map<String, dynamic>> parseWorkoutPlan(String planText, List<Map<String, dynamic>> availableExercises) {
  List<Map<String, dynamic>> exercises = [];
  List<String> lines = planText.split('\n');
  
  print("Parsing workout plan:");
  for (String line in lines) {
    print("Processing line: $line");
    String cleanLine = line.replaceFirst(RegExp(r'^[-•\d.]\s*'), '').trim();
    List<String> parts = cleanLine.split('|').map((part) => part.trim()).toList();
    if (parts.length == 2) {
      String exerciseTitle = parts[0];
      int? sets = int.tryParse(parts[1]);
      
      print("Exercise: $exerciseTitle, Sets: $sets");
      
      if (sets != null && sets > 0) {
        Map<String, dynamic>? matchedExercise = fuzzyMatchExercise(exerciseTitle, availableExercises);
        if (matchedExercise != null) {
          exercises.add({
            "title": matchedExercise['title'],
            "sets": sets,
          });
          print("Added exercise: ${matchedExercise['title']} with $sets sets");
        } else {
          print("Skipped exercise: $exerciseTitle (not found in available exercises)");
        }
      } else {
        print("Skipped exercise: $exerciseTitle (invalid number of sets)");
      }
    } else {
      print("Skipped line: invalid format");
    }
  }
  
  print("Parsed exercises: $exercises");
  return exercises;
}

Map<String, dynamic>? fuzzyMatchExercise(String exerciseTitle, List<Map<String, dynamic>> availableExercises) {
  String cleanTitle = exerciseTitle.replaceFirst(RegExp(r'^[-\d.]\s*'), '').trim();
  String lowerTitle = cleanTitle.toLowerCase();
  
  for (var exercise in availableExercises) {
    if (exercise['title'].toLowerCase() == lowerTitle) {
      return exercise;
    }
  }

  for (var exercise in availableExercises) {
    if (exercise['title'].toLowerCase().contains(lowerTitle) || 
        lowerTitle.contains(exercise['title'].toLowerCase())) {
      return exercise;
    }
  }

  return null;
}