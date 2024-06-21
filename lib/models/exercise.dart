class ExerciseInfo {
  final String title;
  final String description;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final String technique;

  ExerciseInfo._({
    required this.title,
    required this.description,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.technique
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'primaryMuscles': primaryMuscles,
    'secondaryMuscles': secondaryMuscles,
    'technique': technique
  };

  factory ExerciseInfo.fromJson(Map<String, dynamic> data) {
    var primaryMusclesArray = data['primaryMuscles'];
    var secondaryMusclesArray = data['secondaryMuscles'];

    return ExerciseInfo._(
      title: data['title'] as String,
      description: data['description'] as String,
      primaryMuscles: List<String>.from(primaryMusclesArray),
      secondaryMuscles: List<String>.from(secondaryMusclesArray),
      technique: data['technique'] as String
    );
  }
}
