class ExerciseInfo {
  final String title;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final String technique;

  ExerciseInfo({
    required this.title,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.technique,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'primaryMuscles': primaryMuscles,
    'secondaryMuscles': secondaryMuscles,
    'technique': technique,
  };

  factory ExerciseInfo.fromJson(Map<String, dynamic> data) {
    return ExerciseInfo(
      title: data['title'] as String,
      primaryMuscles: List<String>.from(data['primaryMuscles']),
      secondaryMuscles: List<String>.from(data['secondaryMuscles']),
      technique: data['technique'] as String,
    );
  }
}
