import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GoalsPage extends StatefulWidget {
  final bool isInitialSetup;

  const GoalsPage({Key? key, this.isInitialSetup = false}) : super(key: key);

  @override
  _GoalsPageState createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _selectedFeet = 5;
  int _selectedInches = 0;
  final TextEditingController _weightController = TextEditingController();
  int _selectedYear = DateTime.now().year;

  final List<String> _goalOptions = [
    'General Fitness',
    'Bodybuilding',
    'Powerlifting',
    'Olympic Weightlifting',
    'Endurance Running',
    'Sprint Training',
    'Sport Specific',
    'Functional Fitness',
    'Rehabilitation',
    'Senior Fitness'
  ];
  List<String> _selectedGoals = [];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          if (data.containsKey('fitnessProfile')) {
            setState(() {
              _selectedFeet = data['fitnessProfile']['height']['feet'] ?? 5;
              _selectedInches = data['fitnessProfile']['height']['inches'] ?? 0;
              _weightController.text = (data['fitnessProfile']['weight'] ?? '').toString();
              _selectedYear = data['fitnessProfile']['yearStarted'] ?? DateTime.now().year;
              _selectedGoals = List<String>.from(data['fitnessProfile']['fitnessGoals'] ?? []);
            });
          }
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !widget.isInitialSetup,
      child: Scaffold(
        backgroundColor: Colors.grey[200],
        appBar: AppBar(
          title: Text('Set Your Fitness Profile'),
          backgroundColor: Colors.grey[200],
          foregroundColor: Colors.black,
          elevation: 0,
          automaticallyImplyLeading: !widget.isInitialSetup,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Biometrics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              _buildHeightDropdowns(),
              SizedBox(height: 10),
              _buildWeightTextField(),
              SizedBox(height: 20),

              Text('Experience', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              _buildYearStartedDropdown(),
              SizedBox(height: 20),

              Text('Fitness Goals', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              _buildGoalsMultiSelect(),
              SizedBox(height: 20),

              Center(
                child: ElevatedButton(
                  child: Text('Save Profile'),
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeightDropdowns() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            value: _selectedFeet,
            items: List.generate(8, (index) => index + 4).map((int value) {
              return DropdownMenuItem<int>(
                value: value,
                child: Text('$value ft'),
              );
            }).toList(),
            onChanged: (int? newValue) {
              setState(() {
                _selectedFeet = newValue!;
              });
            },
            decoration: InputDecoration(
              labelText: 'Feet',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
            ),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: DropdownButtonFormField<int>(
            value: _selectedInches,
            items: List.generate(12, (index) => index).map((int value) {
              return DropdownMenuItem<int>(
                value: value,
                child: Text('$value in'),
              );
            }).toList(),
            onChanged: (int? newValue) {
              setState(() {
                _selectedInches = newValue!;
              });
            },
            decoration: InputDecoration(
              labelText: 'Inches',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeightTextField() {
    return TextField(
      controller: _weightController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Weight (lbs)',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      ),
    );
  }

  Widget _buildYearStartedDropdown() {
    int currentYear = DateTime.now().year;
    return DropdownButtonFormField<int>(
      value: _selectedYear,
      items: List.generate(51, (index) => currentYear - index).map((int value) {
        return DropdownMenuItem<int>(
          value: value,
          child: Text(value.toString()),
        );
      }).toList(),
      onChanged: (int? newValue) {
        setState(() {
          _selectedYear = newValue!;
        });
      },
      decoration: InputDecoration(
        labelText: 'Year Started Training',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      ),
    );
  }

  Widget _buildGoalsMultiSelect() {
    return Column(
      children: _goalOptions.map((goal) {
        return CheckboxListTile(
          title: Text(goal),
          value: _selectedGoals.contains(goal),
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                _selectedGoals.add(goal);
              } else {
                _selectedGoals.remove(goal);
              }
            });
          },
        );
      }).toList(),
    );
  }

  void _saveProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'fitnessProfile': {
            'height': {
              'feet': _selectedFeet,
              'inches': _selectedInches,
            },
            'weight': int.tryParse(_weightController.text) ?? 0,
            'yearStarted': _selectedYear,
            'fitnessGoals': _selectedGoals,
          }
        }, SetOptions(merge: true));
        
        Navigator.of(context).pop();
      } catch (e) {
        print('Error saving profile: $e');
        // You can choose to show an error message here if you want
      }
    }
  }
}