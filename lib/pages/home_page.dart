import 'package:Palestra/controller/bottom_nav_bar_controller.dart';
import 'package:Palestra/data/workout_data.dart';
import 'package:Palestra/pages/workout_page.dart';
import 'package:Palestra/pages/session_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // text controller
  final newWorkoutNameController = TextEditingController();
  final newSessionNameController = TextEditingController();

  void createNewSession() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text("Start workout session"),
                content: TextField(
                  controller: newSessionNameController,
                  decoration: InputDecoration(
                    hintText: 'Session Name',
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                ),
                actions: [
                  MaterialButton(
                      onPressed: saveSession,
                      child: const Text("save",
                          style: TextStyle(color: Colors.black))),
                  MaterialButton(
                      onPressed: cancel,
                      child: const Text("cancel",
                          style: TextStyle(color: Colors.black)))
                ]));
  }

  void saveSession() {
    String newSessionName = newSessionNameController.text;
    Provider.of<WorkoutData>(context, listen: false).addSession(newSessionName);
    Navigator.pop(context);
    clear();
    goToSessionPage(newSessionName);
  }

  void goToSessionPage(String sessionName) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => SessionPage(sessionName: sessionName)));
  }

  // create a new workout
  void createNewWorkout() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text("Create new template"),
                content: TextField(
                  controller: newWorkoutNameController,
                  decoration: const InputDecoration(
                    hintText: 'Workout Name',
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                ),
                actions: [
                  MaterialButton(
                      onPressed: saveWorkout,
                      child: const Text("save",
                          style: TextStyle(color: Colors.black))),
                  MaterialButton(
                      onPressed: cancel,
                      child: const Text("cancel",
                          style: TextStyle(color: Colors.black)))
                ]));
  }

  void goToWorkoutPage(String workoutName) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => WorkoutPage(workoutName: workoutName)));
  }

  void saveWorkout() {
    String newWorkoutName = newWorkoutNameController.text;
    Provider.of<WorkoutData>(context, listen: false).addWorkout(newWorkoutName);

    Navigator.pop(context);
    clear();
  }

  void cancel() {
    Navigator.pop(context);
    clear();
  }

  void clear() {
    newWorkoutNameController.clear();
  }

  User? currentUser;

  @override
  void initState() {
    super.initState();
    refreshUser();
  }

  void refreshUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();

      setState(() {
        currentUser = FirebaseAuth.instance.currentUser;
      });
    }
  }

  void logout() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    BottomNavigationBarController controller =
        Get.put(BottomNavigationBarController());
    return Consumer<WorkoutData>(
      builder: (context, value, child) {
        var workoutList = value.getWorkoutList();
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              "Palestra",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(onPressed: logout, icon: Icon(Icons.logout)),
            ],
            backgroundColor: Colors.grey[200],
          ),
          backgroundColor:
              Colors.grey[200], // Set the background color of the app to grey
          body: Obx(() {
            // Check which page is selected
            if (controller.index.value == 1) {
              // If "Workout" page is selected, show the workout list
              return Column(
                children: [
                  if (currentUser?.displayName != null)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Let's work, ${currentUser?.displayName}.",
                          style: const TextStyle(
                              fontSize: 35, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: createNewSession,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black, // Background color
                        foregroundColor: Colors.white, // Text color
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        textStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.start, color: Colors.white),
                          Text(' Start Workout Session'),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Templates",
                            style: const TextStyle(
                                fontSize: 21, fontWeight: FontWeight.bold),
                          ),
                          ElevatedButton(
                            onPressed: createNewWorkout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black, // Background color
                              foregroundColor: Colors.white, // Text color
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 20),
                              textStyle: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, color: Colors.white),
                                Text('Template'),
                              ],
                            ),
                          ),
                        ]),
                  ),
                  Expanded(
                    child: workoutList.isNotEmpty
                        ? ListView.builder(
                            itemCount: workoutList.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(workoutList[index].name,
                                    style: const TextStyle(fontSize: 18)),
                                trailing: IconButton(
                                  icon: Icon(Icons.arrow_forward_ios),
                                  onPressed: () =>
                                      goToWorkoutPage(workoutList[index].name),
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Text("No data available"),
                          ),
                  ),
                ],
              );
            } else {
              // Otherwise, show the selected page from the controller
              return controller.pages[controller.index.value];
            }
          }),
          bottomNavigationBar: Container(
            color: Colors.black,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              child: GNav(
                backgroundColor: Colors.black,
                color: Colors.white,
                activeColor: Colors.white,
                tabBackgroundColor: Colors.grey.shade800,
                iconSize: 30,
                gap: 8,
                padding: EdgeInsets.all(16),
                tabs: const [
                  GButton(icon: Icons.trending_up, text: "Analyze"),
                  GButton(icon: Icons.add, text: "Workout"),
                  GButton(icon: Icons.fitness_center, text: "Exercises"),
                  GButton(icon: Icons.chat, text: "AI"),
                ],
                selectedIndex: controller.index.value,
                onTabChange: (value) {
                  controller.index.value = value;
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
