import 'package:cloud_firestore/cloud_firestore.dart';

class Session {
  final String title;
  final DateTime date;
  List<Map<String, dynamic>> _exercises;

  Session._({required this.title, required this.date, List<Map<String, dynamic>>? exercises})
      : _exercises = exercises ?? [];

  List<Map<String, dynamic>> get exercises => List.unmodifiable(_exercises);

  Map<String, dynamic> toJson() => {
        'title': title,
        'date': date.toIso8601String(),
        'exercises': _exercises,
      };

  factory Session.fromJson(Map<String, dynamic> data) {
    return Session._(
      title: data['title'] as String,
      date: _parseDate(data['date']),
      exercises: List<Map<String, dynamic>>.from(data['exercises'] as List),
    );
  }

  static DateTime _parseDate(dynamic date) {
    if (date is Timestamp) {
      return date.toDate();
    } else if (date is String) {
      return DateTime.parse(date);
    } else {
      throw FormatException('Invalid date format');
    }
  }

  factory Session.withTitle(String title) {
    return Session._(title: title, date: DateTime.now());
  }

  void addExercise(String exerciseName) {
    _exercises.add({
      'title': exerciseName,
      'reps': [],
      'weights': [],
    });
  }

  void addReps(String exerciseName, int reps) {
    _updateExercise(exerciseName, (exercise) {
      exercise['reps'].add(reps);
    });
  }

  void addWeight(String exerciseName, num weight) {
    _updateExercise(exerciseName, (exercise) {
      exercise['weights'].add(weight);
    });
  }

  void updateWeight(String exerciseName, num weight, int setNumber) {
    _updateExercise(exerciseName, (exercise) {
      if (setNumber < exercise['weights'].length) {
        exercise['weights'][setNumber] = weight;
      }
    });
  }

  void updateReps(String exerciseName, int reps, int setNumber) {
    _updateExercise(exerciseName, (exercise) {
      if (setNumber < exercise['reps'].length) {
        exercise['reps'][setNumber] = reps;
      }
    });
  }

  void removeExercise(String exerciseName) {
    _exercises.removeWhere((exercise) => exercise['title'] == exerciseName);
  }

  void removeSet(String exerciseName, int setNumber) {
    _updateExercise(exerciseName, (exercise) {
      if (setNumber < exercise['reps'].length && setNumber < exercise['weights'].length) {
        exercise['reps'].removeAt(setNumber);
        exercise['weights'].removeAt(setNumber);
      }
    });
  }

  void _updateExercise(String exerciseName, Function(Map<String, dynamic>) updateFunction) {
    final exercise = _exercises.firstWhere(
      (exercise) => exercise['title'] == exerciseName,
      orElse: () => throw Exception('Exercise not found: $exerciseName'),
    );
    updateFunction(exercise);
  }
}