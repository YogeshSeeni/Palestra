import 'package:Palestra/components/my_button.dart';
import 'package:Palestra/components/my_textfield.dart';
import 'package:Palestra/components/square_tile.dart';
import 'package:Palestra/helper/helper_functions.dart';
import 'package:Palestra/pages/email_verification_page.dart';
import 'package:Palestra/pages/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class RegisterPage extends StatefulWidget {
  final void Function()? onTap;

  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // text editing controllers
  final emailController = TextEditingController();

  final usernameController = TextEditingController();

  final passwordController = TextEditingController();

  final confirmController = TextEditingController();

  // loading
  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  //Register Method
  void register() async {
    // check if passwords don't match
    if (passwordController.text != confirmController.text) {
      // Display error message
      displayMessage("Passwords Don't Match!!", context);
      return;
    }

    isLoading.value = true;

    try {
      // create user
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: emailController.text, password: passwordController.text);

      // Send email verification
      await userCredential.user?.sendEmailVerification();
      // Update display name
      await userCredential.user?.updateDisplayName(usernameController.text);

      Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => EmailVerificationPage()),
    );
    } on FirebaseAuthException catch (e) {
      // Display error message
      displayMessage(e.message ?? 'An error occurred', context);
    } catch (e) {
      // Display error message
      displayMessage('An unexpected error occurred', context);
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

    Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => HomePage()),
    );
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
                    'Create a new account',
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
                  const SizedBox(height: 10),
                  MyTextField(
                    controller: usernameController,
                    hintText: 'Name',
                    obscureText: false,
                    prefixIcon: Icon(Icons.person, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 10),
                  MyTextField(
                    controller: passwordController,
                    hintText: 'Password',
                    obscureText: true,
                    prefixIcon: Icon(Icons.lock, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 10),
                  MyTextField(
                    controller: confirmController,
                    hintText: 'Confirm Password',
                    obscureText: true,
                    prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 25),
                  MyButton(
                    onTap: register,
                    buttonText: "Register",
                  ),
                  const SizedBox(height: 25),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[400])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Text('Or continue with', style: TextStyle(color: Colors.grey[700])),
                        ),
                        Expanded(child: Divider(color: Colors.grey[400])),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
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
                            'Sign up with Google',
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
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: widget.onTap,
                        child: const Text('Login here',
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

