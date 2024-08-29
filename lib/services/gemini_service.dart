import 'dart:convert';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:Palestra/util/parse_workout.dart';

class GeminiService {
  final Gemini _gemini = Gemini.instance;

  Future<String> getGeminiResponse(String prompt) async {
    String response = '';
    await for (var event in _gemini.streamGenerateContent(prompt)) {
      response +=
          event.content?.parts?.map((part) => part.text).join(" ") ?? '';
    }
    response = response.replaceAll("**", "");
    response = response.replaceAll("* ", "• ");
    return response.trim();
  }

  Future<String> exerciseAnalysis(String exerciseName,
      List<Map<String, dynamic>> exerciseData, Map<String, dynamic> profile) async {
    String prompt = """
Provide a brief analysis and feedback for the $exerciseName exercise based on the following data:
$exerciseData
User's profile: ${json.encode(profile)}

Focus on:
1. Overall performance trend
2. Areas of improvement
3. A specific, actionable tip to enhance performance
4. How the exercise can be taken advantage of to reach user's goal. Be specific here. How should the exercise be done in a way that tailors to the user's goals and overall profile? For example, is there an optimal range for # sets or # reps? Think of ways to tailor it better to the user.

Keep the response concise (3-4 sentences max for pointers 1-3, 3 sentences max for pointer 4).

Analysis and Tip:
""";

    return await getGeminiResponse(prompt);
  }

  Future<String> generateGoalBasedFeedback(String exerciseName,
    String metric,
    List<Map<String, dynamic>> exerciseData,
    Map<String, dynamic> profile) async {
    String prompt = """
  Generate goal-based feedback for the $exerciseName exercise, focusing on the $metric metric.
  User's profile: ${json.encode(profile)}
  Exercise data: ${json.encode(exerciseData)}

  Instructions:
  1. Analyze the exercise data in the context of the user's full fitness profile. Place emphasis on ensuring that your advice aligns with the user's goal.
  2. Provide specific, actionable feedback related to the $metric that aligns with the user's primary fitness goal (${profile['fitnessProfile']?['fitnessGoals']?[0] ?? 'general fitness'}).
  3. Consider the user's workout frequency (${profile['fitnessProfile']?['workoutDaysPerWeek'] ?? 'unknown'} days per week) and duration (${profile['fitnessProfile']?['workoutTimePerDay'] ?? 'unknown'} minutes per day) when giving advice.
  4. If relevant, factor in the user's height (${profile['fitnessProfile']?['height']?['feet'] ?? 'unknown'}' ${profile['fitnessProfile']?['height']?['inches'] ?? 'unknown'}"), weight (${profile['fitnessProfile']?['weight'] ?? 'unknown'} lbs), and years of training (since ${profile['fitnessProfile']?['yearStarted'] ?? 'unknown'}).
  5. Keep the feedback concise (2-3 sentences) and motivational.
  6. If the data shows good progress towards the user's goals, acknowledge it. If there's room for improvement, suggest how.
  7. Tailor the feedback to the specific exercise, metric, and the user's overall fitness profile.

  Feedback:
  """;

    return await getGeminiResponse(prompt);
  }

  Future<String> sendMessage(
      String message, List<ChatMessage> chatHistory, Map<String, dynamic> userProfile, Map<String, List<Map<String, dynamic>>> exerciseData) async {
    String conversationContext = chatHistory
        .map((msg) => "${msg.user.firstName}: ${msg.text}")
        .join("\n");

    String prompt = """
Previous conversation:
$conversationContext

User's new message: $message

User's profile:
${json.encode(userProfile)}

User's Previous Session:
$exerciseData

Instructions:
1. Respond to the user's message in the context of being an AI fitness coach.
2. Keep the response concise but informative.
3. If asked about exercises, provide brief explanations and safety tips.
4. If asked about workout plans, suggest consulting the workout regimen feature.
5. Always encourage safe and healthy practices.
6. Tailor your response to the user's profile when relevant.

Please provide your response:
""";

    print(prompt);
    return await getGeminiResponse(prompt);
  }

  Future<String> generateSingleWorkout(Map<String, dynamic> profile,
      List<Map<String, dynamic>> availableExercises, String userInput) async {
    String prompt = """
Create a single workout session based on the following user profile and input:
Height: ${profile['height']['feet']}'${profile['height']['inches']}"
Weight: ${profile['weight']} lbs
Training since: ${profile['yearStarted']}
Goals: ${profile['fitnessGoals'].join(', ')}
Special condition: ${profile['specialCondition']}
Workout time: ${profile['workoutTimePerDay']} minutes
Gym access: ${profile['gymAccess']}

User wants: $userInput

Available exercises: ${availableExercises.map((e) => e['title']).join(', ')}

Instructions:
1. Suggest 4-6 exercises from the available list, considering the user's input, goals, and profile.
2. For each exercise, suggest only the number of sets (3-5).
3. Format your response as a simple list, with each line containing:
   Exercise name | Number of sets

Example output:
Bench Press | 3
Squats | 4
...

Ensure the workout is balanced and appropriate for the user's goals, experience level, and preferences.
Limit the workout to approximately ${profile['workoutTimePerDay']} minutes.
Only include exercises from the provided 'Available exercises' list.
""";

    return await getGeminiResponse(prompt);
  }

  Future<List<Map<String, dynamic>>> generateWorkoutRegimen(
      Map<String, dynamic> profile,
      List<Map<String, dynamic>> availableExercises,
      String preferredSplit) async {
    String prompt = """
Create a personalized weekly workout regimen overview based on the following user profile:
Height: ${profile['height']?['feet'] ?? 'N/A'}'${profile['height']?['inches'] ?? 'N/A'}"
Weight: ${profile['weight'] ?? 'N/A'} lbs
Training since: ${profile['yearStarted'] ?? 'N/A'}
Goals: ${profile['fitnessGoals']?.join(', ') ?? 'Not specified'}
Special condition: ${profile['specialCondition'] ?? 'None'}
Workout days per week: ${profile['workoutDaysPerWeek'] ?? 'N/A'}
Workout time per day: ${profile['workoutTimePerDay'] ?? 'N/A'} minutes
Gym access: ${profile['gymAccess'] ?? 'N/A'}
Preferred split: $preferredSplit

Instructions:
1. Create a ${profile['workoutDaysPerWeek'] ?? 3}-day workout plan overview for the week, considering the user's preferred split of "$preferredSplit". Note: fit the split to the user's preferred workout days per week. 
2. For each day, provide a name and focus (e.g., "Upper Body", "Lower Body", etc.). Do NOT list rest days no matter the user. 
3. For users who train 5 or more days a week, ensure all muscles are targeted and generate creative workouts (e.g. Beach Muscles (Chest, Biceps, Abs)).
4. Ensure the regimen is balanced and appropriate for the user's goals, experience level, and preferences.
5. Format your response as a simple list, with each day on a new line. Order the workouts in a reasonable manner. 
6. Do not include rest days.

Example output:
Upper Body
Lower Body
Full Body

Do NOT list dashes, numbers, or days. Only list with new lines. For example, do not output the following:
- Upper Body
- Lower Body
- Full Body

We want the user to choose the order.

Only provide the overview, not the specific exercises.
""";

    String regimenOverview = await getGeminiResponse(prompt);
    List<String> workoutDays = regimenOverview
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    List<Map<String, dynamic>> fullRegimen = [];
    for (String day in workoutDays) {
      String workoutPlan =
          await generateDayWorkout(profile, availableExercises, day);
      List<Map<String, dynamic>> exercises =
          parseWorkoutPlan(workoutPlan, availableExercises);
      fullRegimen.add({
        "name": day,
        "exercises": exercises,
      });
    }

    return fullRegimen;
  }

  Future<String> generateDayWorkout(Map<String, dynamic> profile,
      List<Map<String, dynamic>> availableExercises, String dayFocus) async {
    return await generateSingleWorkout(
        profile, availableExercises, "Workout for $dayFocus");
  }

  Future<String> generateRecommendation(
      Map<String, List<Map<String, dynamic>>> exerciseData) async {
    String exerciseDataJson = json.encode(exerciseData);
    String prompt = """
Generate a concise recommendation (30 words or less) for the user's next workout session based on their exercise data.
Be motivational and focus on progress or variety. Avoid suggesting specific exercises.

Exercise Data:
$exerciseDataJson

Recommendation:
""";

    return await getGeminiResponse(prompt);
  }

  Future<String> getTip(Map<String, List<Map<String, dynamic>>> exerciseData) async {
    String prompt = """
User's Previous Exercise Data:
$exerciseData

Provide a quick, useful workout tip. The tip should be:
1. Concise (20 words or less)
2. Generally applicable to most fitness routines
3. Focused on form, safety, or motivation
4. Easy to understand and implement

Workout tip:
""";

    return await getGeminiResponse(prompt);
  }
}
