import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Palestra/components/my_button.dart';
import 'package:Palestra/helper/helper_functions.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({Key? key}) : super(key: key);

  @override
  _EmailVerificationPageState createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  Future<void> _sendVerificationEmail() async {
    isLoading.value = true;
    try {
      await _auth.currentUser?.sendEmailVerification();
      displayMessage('Verification email sent. Please check your inbox.', context);
    } catch (e) {
      displayMessage('Error sending verification email: ${e.toString()}', context);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _checkEmailVerified() async {
    isLoading.value = true;
    try {
      await _auth.currentUser?.reload();
      if (_auth.currentUser?.emailVerified ?? false) {
        // Navigate to home page or refresh the auth state
        Navigator.of(context).pushReplacementNamed('/');
      } else {
        displayMessage('Email not verified yet. Please check your inbox and verify your email.', context);
      }
    } catch (e) {
      displayMessage('Error checking email verification: ${e.toString()}', context);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 25),
                  Image.asset('lib/images/logo.png', height: 150),
                  const SizedBox(height: 25),
                  Text(
                    'Verify Your Email',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: Text(
                      'Please check your email and click on the verification link to complete your registration.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 25),
                  MyButton(
                    onTap: _sendVerificationEmail,
                    buttonText: 'Resend Verification Email',
                  ),
                  const SizedBox(height: 15),
                  MyButton(
                    onTap: _checkEmailVerified,
                    buttonText: 'I\'ve Verified My Email',
                  ),
                  const SizedBox(height: 25),
                  TextButton(
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    child: Text(
                      'Back to Login',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: isLoading,
              builder: (context, value, child) {
                if (value) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
