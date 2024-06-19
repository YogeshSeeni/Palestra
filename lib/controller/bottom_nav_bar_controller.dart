import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../pages/analyze_page.dart'; // Import the AnalyzePage
import '../pages/home_page.dart';    // Import the HomePage
import '../pages/exercises_page.dart'; // Import the ExercisesPage
import '../pages/ai_page.dart';      // Import the AIPage

class BottomNavigationBarController extends GetxController {
  RxInt index = 1.obs;

  var pages = [
    AnalyzePage(),
    HomePage(),
    ExercisesPage(),
    AiPage(),
  ];
}

