import 'package:Palestra/controller/bottom_nav_bar_controller.dart';
import 'package:Palestra/data/workout_data.dart';
import 'package:Palestra/pages/workout_page.dart';
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

  // create a new workout
  void createNewWorkout() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text("Create new workout"),
                content: TextField(
                  controller: newWorkoutNameController,
                  decoration: InputDecoration(
                    hintText: 'Workout Name',
                  ),
                ),
                actions: [
                  MaterialButton(
                      onPressed: save,
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

  void save() {
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
          floatingActionButton: Obx(() {
            // Only show the floating action button on the "Workout" tab
            if (controller.index.value == 1) {
              return FloatingActionButton(
                onPressed: createNewWorkout,
                child: Icon(Icons.add, color: Colors.white),
                backgroundColor: Colors.black,
              );
            } else {
              return Container(); // Return an empty container when the FAB is not needed
            }
          }),
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
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Welcome, ${currentUser?.displayName}",
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ),
                  Expanded(
                    child: workoutList.isNotEmpty
                        ? ListView.builder(
                            itemCount: workoutList.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(workoutList[index].name),
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
