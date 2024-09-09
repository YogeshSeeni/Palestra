import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Palestra/auth/auth.dart';
import 'package:Palestra/components/my_textfield.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  void logout(BuildContext context) {
    FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => AuthPage()),
      (Route<dynamic> route) => false,
    );
  }

  String generateNonce([int length = 32]) {
    final charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
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
                    // Check the user's provider data
                    var providers = user.providerData.map((e) => e.providerId).toList();
                    
                    if (providers.contains('apple.com')) {
                      // For Apple Sign-In users
                      final rawNonce = generateNonce();
                      final nonce = sha256ofString(rawNonce);

                      final appleCredential = await SignInWithApple.getAppleIDCredential(
                        scopes: [
                          AppleIDAuthorizationScopes.email,
                          AppleIDAuthorizationScopes.fullName,
                        ],
                        nonce: nonce,
                      );

                      final oauthCredential = OAuthProvider("apple.com").credential(
                        idToken: appleCredential.identityToken,
                        rawNonce: rawNonce,
                      );

                      await user.reauthenticateWithCredential(oauthCredential);
                    } else if (providers.contains('google.com')) {
                      // For Google Sign-In users
                      final GoogleSignIn googleSignIn = GoogleSignIn();
                      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
                      if (googleUser != null) {
                        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
                        final credential = GoogleAuthProvider.credential(
                          accessToken: googleAuth.accessToken,
                          idToken: googleAuth.idToken,
                        );
                        await user.reauthenticateWithCredential(credential);
                      } else {
                        throw Exception('Google Sign-In failed');
                      }
                    } else {
                      // For email/password users
                      String password = await _getPassword(context);
                      if (password.isEmpty) {
                        throw Exception('Password is required');
                      }
                      AuthCredential credential = EmailAuthProvider.credential(
                        email: user.email!,
                        password: password,
                      );
                      await user.reauthenticateWithCredential(credential);
                    }

                    print('Starting account deletion process for user: ${user.uid}');
                    
                    // Delete user data from Firestore
                    print('Deleting user data from Firestore...');
                    await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
                    print('Firestore data deleted successfully');
                    
                    // Delete the user's authentication account
                    print('Deleting user authentication account...');
                    await user.delete();
                    print('User authentication account deleted successfully');
                    
                    // Sign out and navigate
                    print('Logging out and navigating...');
                    await FirebaseAuth.instance.signOut();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => AuthPage()),
                      (Route<dynamic> route) => false,
                    );
                  } else {
                    print('No user currently signed in');
                  }
                } catch (e) {
                  print('Error during account deletion: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete account: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<String> _getPassword(BuildContext context) async {
    final passwordController = TextEditingController();
    bool? result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[200],
          title: Text(
            'Confirm Password',
            style: TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Please enter your password to confirm account deletion.',
                style: TextStyle(color: Colors.grey[700], fontSize: 16),
              ),
              SizedBox(height: 20),
              MyTextField(
                controller: passwordController,
                hintText: 'Password',
                obscureText: true,
                prefixIcon: Icon(Icons.lock, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[700]),
              ),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text(
                'Confirm',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    return result == true ? passwordController.text : '';
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
