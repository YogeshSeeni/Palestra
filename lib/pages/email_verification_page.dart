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
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Image.asset('lib/images/logo_black.png', height: 180),
                  const SizedBox(height: 40),
                  const Text(
                    'Verify Your Email',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Please check your email and click on the verification link to complete your registration.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[700], fontSize: 16),
                  ),
                  const SizedBox(height: 40),
                  MyButton(
                    onTap: _sendVerificationEmail,
                    buttonText: 'Resend Verification Email',
                  ),
                  const SizedBox(height: 20),
                  MyButton(
                    onTap: _checkEmailVerified,
                    buttonText: 'I\'ve Verified My Email',
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    child: Text(
                      'Back to Login',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

    