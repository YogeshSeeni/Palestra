List<Map<String, dynamic>> parseWorkoutPlan(String planText, List<Map<String, dynamic>> availableExercises) {
  List<Map<String, dynamic>> exercises = [];
  List<String> lines = planText.split('\n');
  
  for (String line in lines) {
    String cleanLine = line.replaceFirst(RegExp(r'^[-•\d.]\s*'), '').trim();
    List<String> parts = cleanLine.split('|').map((part) => part.trim()).toList();
    if (parts.length == 2) {
      String exerciseTitle = parts[0];
      int? sets = int.tryParse(parts[1]);
      
      
      if (sets != null && sets > 0) {
        Map<String, dynamic>? matchedExercise = fuzzyMatchExercise(exerciseTitle, availableExercises);
        if (matchedExercise != null) {
          exercises.add({
            "title": matchedExercise['title'],
            "sets": sets,
          });
        } else {
        }
      } else {
      }
    } else {
    }
  }
  
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