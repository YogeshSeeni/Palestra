import 'package:Palestra/components/my_button.dart';
import 'package:Palestra/components/my_textfield.dart';
import 'package:Palestra/components/square_tile.dart';
import 'package:Palestra/helper/helper_functions.dart';
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

      // update display name
      await userCredential.user?.updateDisplayName(usernameController.text);
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Stack(children: [
          SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 25),

                  // logo
                  Image.asset('lib/images/logo.png', height: 150),

                  const SizedBox(height: 10),

                  // Email text field
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: MyTextField(
                        controller: emailController,
                        hintText: 'Email',
                        obscureText: false),
                  ),

                  const SizedBox(height: 10),

                  // Username text field
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: MyTextField(
                        controller: usernameController,
                        hintText: 'Name',
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

                  const SizedBox(height: 10),

                  // Confirm password text field
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: MyTextField(
                        controller: confirmController,
                        hintText: 'Confirm Password',
                        obscureText: true),
                  ),

                  const SizedBox(height: 25),

                  // Register button
                  MyButton(
                    buttonText: "Register",
                    onTap: register,
                  ),

                  const SizedBox(height: 25),

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
                        'Already have an account?',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: widget.onTap,
                        child: const Text('Login Here',
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
