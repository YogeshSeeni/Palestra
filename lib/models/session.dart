class Session {
  final String title;
  final DateTime date = DateTime.now();
  final List<Map<String, dynamic>> exercises;

  Session._({required this.title, required this.exercises});

  Map<String, dynamic> toJson() => {
    'title': title,
    'date': date,
    'exercises': exercises
  };

  factory Session.fromJson(Map<String, dynamic> data) {
    var exercisesArray = data['exercises'];

    return Session._(
      title: data['title'] as String,
      exercises: List<Map<String, dynamic>>.from(exercisesArray)
    );
  }

  factory Session.withTitle(String title) {
    return Session._(
      title: title,
      exercises: []
    );
  }

  void addExercise(String exerciseName) {
    exercises.add({
      'title': exerciseName,
      'reps': [],
      'weights': []
    });
  }

  void addReps(String exerciseName, int reps) {
    for (var i = 0; i < exercises.length; i++) {
      if (exercises[i]['title'] == exerciseName) {
        exercises[i]['reps'].add(reps);
      }
    }
  }

  void addWeight(String exerciseName, int weight) {
    for (var i = 0; i < exercises.length; i++) {
      if (exercises[i]['title'] == exerciseName) {
        exercises[i]['weights'].add(weight);
      }
    }
  }

  void updateWeight(String exerciseName, int weight, int setNumber) {
    for (var i = 0; i < exercises.length; i++) {
      if (exercises[i]['title'] == exerciseName) {
        exercises[i]['weights'][setNumber] = weight;
      }
    }
  }

  void updateReps(String exerciseName, int reps, int setNumber) {
    for (var i = 0; i < exercises.length; i++) {
      if (exercises[i]['title'] == exerciseName) {
        exercises[i]['reps'][setNumber] = reps;
      }
    }
  }
}
