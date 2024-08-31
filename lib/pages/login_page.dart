import 'package:Palestra/components/my_button.dart';
import 'package:Palestra/components/my_textfield.dart';
import 'package:Palestra/components/square_tile.dart';
import 'package:Palestra/helper/helper_functions.dart';
import 'package:Palestra/pages/email_verification_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  final void Function()? onTap;

  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // text editing controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // loading
  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  //Login Method
  void login() async {
    isLoading.value = true;

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text, 
        password: passwordController.text
      );

      if (userCredential.user != null) {
        if (!userCredential.user!.emailVerified) {
          // Instead of showing a message, navigate to the EmailVerificationPage
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => EmailVerificationPage()),
          );
        }
        // If email is verified, the AuthPage will automatically navigate to HomePage
      }
    } on FirebaseAuthException catch (e) {
      displayMessage(e.code, context);
    } finally {
      isLoading.value = false;
    }
  }

  void signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
    await FirebaseAuth.instance.signInWithCredential(credential);
  }

  // Forgot Password Method
  void forgotPassword() async {
    if (emailController.text.isEmpty) {
      displayMessage("Please enter your email address", context);
      return;
    }

    isLoading.value = true;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: emailController.text);
      displayMessage("Password reset email sent. Check your inbox.", context);
    } on FirebaseAuthException catch (e) {
      displayMessage(e.message ?? "An error occurred", context);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Stack(children: [
          SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Image.asset('lib/images/logo_black.png', height: 180),
                  const SizedBox(height: 40),
                  const Text(
                    'Login to your account',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  MyTextField(
                    controller: emailController,
                    hintText: 'Email',
                    obscureText: false,
                    prefixIcon: Icon(Icons.email, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  MyTextField(
                    controller: passwordController,
                    hintText: 'Password',
                    obscureText: true,
                    prefixIcon: Icon(Icons.lock, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: forgotPassword,
                    child: Text('Forgot Password?',
                        style: TextStyle(color: Colors.grey[600])),
                  ),
                  const SizedBox(height: 30),
                  MyButton(
                    buttonText: "Sign In",
                    onTap: login,
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[400])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Or continue with', style: TextStyle(color: Colors.grey[600])),
                      ),
                      Expanded(child: Divider(color: Colors.grey[400])),
                    ],
                  ),
                  const SizedBox(height: 30),
                  GestureDetector(
                    onTap: signInWithGoogle,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SquareTile(imagePath: 'lib/images/google.png'),
                          const SizedBox(width: 10),
                          Text(
                            'Sign in with Google',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Not a member?',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: widget.onTap,
                        child: const Text(
                          'Register now',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          ValueListenableBuilder<bool>(
              valueListenable: isLoading,
              builder: (context, value, child) {
                if (value) {
                  return const Center(child: CircularProgressIndicator());
                }
                return const SizedBox.shrink();
              })
        ]),
      ),
    );
  }
}
