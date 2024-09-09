import 'package:Palestra/components/my_button.dart';
import 'package:Palestra/components/my_textfield.dart';
import 'package:Palestra/helper/helper_functions.dart';
import 'package:Palestra/pages/email_verification_page.dart';
import 'package:Palestra/pages/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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

  String generateNonce([int length = 32]) {
    final charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Returns the sha256 hash of [input] in hex notation.
  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  void signInWithApple() async {
    // To prevent replay attacks with the credential returned from Apple, we
    // include a nonce in the credential request. When signing in with
    // Firebase, the nonce in the id token returned by Apple, is expected to
    // match the sha256 hash of `rawNonce`.
    final rawNonce = generateNonce();
    final nonce = sha256ofString(rawNonce);

    // Request credential for the currently signed in Apple account.
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    // Create an `OAuthCredential` from the credential returned by Apple.
    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    // Sign in the user with Firebase. If the nonce we generated earlier does
    // not match the nonce in `appleCredential.identityToken`, sign in will fail.
    await FirebaseAuth.instance.signInWithCredential(oauthCredential);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }

  Widget _buildContent(BuildContext context, BoxConstraints constraints) {
    bool isSmallScreen = constraints.maxHeight < 700; // Adjust this threshold as needed

    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: isSmallScreen ? 10 : 20),
            Image.asset('lib/images/logo_black.png', height: isSmallScreen ? 120 : 180),
            Text(
              'Create a new account',
              style: TextStyle(
                color: Colors.black,
                fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isSmallScreen ? 20 : 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: MyTextField(
                controller: emailController,
                hintText: 'Email',
                obscureText: false,
                prefixIcon: Icon(Icons.email, color: Colors.grey[600]),
              ),
            ),
            SizedBox(height: isSmallScreen ? 5 : 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: MyTextField(
                controller: usernameController,
                hintText: 'Name',
                obscureText: false,
                prefixIcon: Icon(Icons.person, color: Colors.grey[600]),
              ),
            ),
            SizedBox(height: isSmallScreen ? 5 : 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: MyTextField(
                controller: passwordController,
                hintText: 'Password',
                obscureText: true,
                prefixIcon: Icon(Icons.lock, color: Colors.grey[600]),
              ),
            ),
            SizedBox(height: isSmallScreen ? 5 : 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: MyTextField(
                controller: confirmController,
                hintText: 'Confirm Password',
                obscureText: true,
                prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600]),
              ),
            ),
            SizedBox(height: isSmallScreen ? 15 : 25),
            MyButton(
              onTap: register,
              buttonText: "Register",
            ),
            SizedBox(height: isSmallScreen ? 15 : 25),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[400])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Text('Or continue with',
                        style: TextStyle(color: Colors.grey[700], fontSize: isSmallScreen ? 14 : 16)),
                  ),
                  Expanded(child: Divider(color: Colors.grey[400])),
                ],
              ),
            ),
            SizedBox(height: isSmallScreen ? 20 : 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialSignInButton(
                  onTap: signInWithGoogle,
                  imagePath: 'lib/images/google.png',
                  text: 'Google',
                  isSmallScreen: isSmallScreen,
                ),
                SizedBox(width: isSmallScreen ? 16 : 20),
                _buildSocialSignInButton(
                  onTap: signInWithApple,
                  imagePath: 'lib/images/apple.png',
                  text: 'Apple',
                  isSmallScreen: isSmallScreen,
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 20 : 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account?',
                  style: TextStyle(color: Colors.grey[700], fontSize: isSmallScreen ? 14 : 16),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: widget.onTap,
                  child: Text(
                    'Login here',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSocialSignInButton({
    required VoidCallback onTap,
    required String imagePath,
    required String text,
    required bool isSmallScreen,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isSmallScreen ? 120 : 150,
        padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16, vertical: isSmallScreen ? 8 : 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, height: isSmallScreen ? 20 : 24, width: isSmallScreen ? 20 : 24),
            SizedBox(width: isSmallScreen ? 8 : 10),
            Text(
              text,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return _buildContent(context, constraints);
              },
            ),
            ValueListenableBuilder<bool>(
              valueListenable: isLoading,
              builder: (context, value, child) {
                if (value) {
                  return const Center(child: CircularProgressIndicator());
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
