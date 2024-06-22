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
}
