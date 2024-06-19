import 'package:flutter/material.dart';

class ExerciseTile extends StatelessWidget {
  final String exerciseName;
  final String weight;
  final String reps;
  final String sets;

  const ExerciseTile({
    super.key,
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.sets,
    });

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ListTile(
          title: Text(
            exerciseName,
          ),
          subtitle: Row(
            children: [
              // weight
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Chip(
                  label: Text(
                      "${weight}lbs"),
                ),
              ),

              // sets
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Chip(
                  label: Text(
                      "${sets} sets"),
                ),
              ),

              // reps
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Chip(
                  label: Text(
                      "${reps} reps"),
                ),
              )
            ],
          )
        ),
    );
  }
}
