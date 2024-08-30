import 'package:Palestra/auth/login_or_register.dart';
import 'package:Palestra/pages/home_page.dart';
import 'package:Palestra/pages/email_verification_page.dart'; // Add this import
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.userChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            User? user = snapshot.data;
            if (user != null && user.emailVerified) {
            return const HomePage();
            } else {
              // Return a widget prompting the user to verify their email
              return EmailVerificationPage();
          }
          } else {
            return const LoginOrRegister();
        }
  }
      ),
    );
}
}