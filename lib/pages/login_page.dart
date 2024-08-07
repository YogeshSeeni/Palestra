import 'package:Palestra/components/my_button.dart';
import 'package:Palestra/components/my_textfield.dart';
import 'package:Palestra/components/square_tile.dart';
import 'package:Palestra/helper/helper_functions.dart';
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

    //Sign User In
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: emailController.text, password: passwordController.text);
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
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
    await FirebaseAuth.instance.signInWithCredential(credential);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Stack(
          children: [SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 25),
          
                  // logo
                  Image.asset('lib/images/logo.png', height: 150),
          
                  const SizedBox(height: 10),
          
                  // "Welcome to the future of fitness."
                  Text('Welcome to the future of fitness.',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 16,
                      )),
          
                  const SizedBox(height: 25),
          
                  // Username text field
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: MyTextField(
                        controller: emailController,
                        hintText: 'Email',
                        obscureText: false),
                  ),
          
                  const SizedBox(height: 10),
          
                  // Password text field
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: MyTextField(
                        controller: passwordController,
                        hintText: 'Password',
                        obscureText: true),
                  ),
          
                  // Forgot password?
                  Text('Forgot Password?',
                      style: TextStyle(color: Colors.grey[600])),
          
                  const SizedBox(height: 25),
          
                  // Sign in button
                  MyButton(
                    buttonText: "Sign In",
                    onTap: login,
                  ),
          
                  const SizedBox(height: 50),
          
                  // Or continue with
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            thickness: 0.5,
                            color: Colors.grey[400],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Text('Or continue with',
                              style: TextStyle(color: Colors.grey[700])),
                        ),
                        Expanded(
                          child: Divider(
                            thickness: 0.5,
                            color: Colors.grey[400],
                          ),
                        )
                      ],
                    ),
                  ),
          
                  const SizedBox(height: 25),
          
                  // Google + apple sign in button
                  GestureDetector(
                    onTap: signInWithGoogle,
                    child: const SquareTile(imagePath: 'lib/images/google.png')
                  ),
          
                  const SizedBox(height: 25),
          
                  // Not a user? Register now
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
                        child: const Text('Register now',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            )),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          ValueListenableBuilder<bool>(valueListenable: isLoading, builder: (context, value, child) {
            if (value) {
              return const Center(child: CircularProgressIndicator());
            } else {
              return const SizedBox.shrink();
            }
          })
          ]
        ),
      ),
    );
  }
}
