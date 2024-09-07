import 'package:Palestra/pages/landing_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Palestra/auth/auth.dart';
import 'package:flutter/scheduler.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  void logout(BuildContext context) {
    FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => AuthPage()),
      (Route<dynamic> route) => false,
    );
  }

  void deleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text("Delete Account"),
          content: Text("Are you sure you want to delete your account? This action cannot be undone."),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: Text("Delete"),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  User? user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    print('Starting account deletion process for user: ${user.uid}');
                    
                    // Delete user data from Firestore
                    print('Deleting user data from Firestore...');
                    await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
                    print('Firestore data deleted successfully');
                    
                    // Delete the user's authentication account
                    print('Deleting user authentication account...');
                    await user.delete();
                    print('User authentication account deleted successfully');
                    
                    // Sign out
                    print('Logging out...');
                    await FirebaseAuth.instance.signOut();
                    
                    // Navigate to AuthPage
                    print('Navigating...');
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => AuthPage()),
                      (Route<dynamic> route) => false,
                    );
                  } else {
                    print('No user currently signed in');
                  }
                } catch (e) {
                  print('Error during account deletion: $e');
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.grey[200],
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () => logout(context),
          ),
          ListTile(
            leading: Icon(Icons.delete_forever),
            title: Text('Delete Account'),
            onTap: () => deleteAccount(context),
          ),
        ],
      ),
    );
  }
}
