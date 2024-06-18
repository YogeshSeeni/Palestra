import 'package:Palestra/components/my_button.dart';
import 'package:Palestra/components/my_textfield.dart';
import 'package:Palestra/components/square_tile.dart';
import 'package:flutter/material.dart';

class RegisterPage extends StatelessWidget {
  final void Function()? onTap;

  RegisterPage({super.key, required this.onTap});

  // text editing controllers
  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 25),
          
                // logo
                Image.asset(
                  'lib/images/logo.png',
                  height: 150
                ),
          
                const SizedBox(height: 10),
          
                // Email text field
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: MyTextField(
                    controller: emailController,
                    hintText: 'Email',
                    obscureText: false
                  ),
                ),
          
                const SizedBox(height: 10),

                // Username text field
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: MyTextField(
                    controller: usernameController,
                    hintText: 'Username',
                    obscureText: false
                  ),
                ),
          
                const SizedBox(height: 10),
          
                // Password text field
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: MyTextField(
                    controller: passwordController,
                    hintText: 'Password',
                    obscureText: true
                  ),
                ),

                const SizedBox(height: 10),

                // Confirm password text field
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: MyTextField(
                    controller: confirmController,
                    hintText: 'Confirm Password',
                    obscureText: true
                  ),
                ),
                
                const SizedBox(height: 25),
          
                // Register button
                MyButton(
                  buttonText: "Register",
                  onTap: onTap,
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
                        style: TextStyle(color: Colors.grey[700])
                        ),
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
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // google button
                    SquareTile(imagePath: 'lib/images/google.png'),
                    
                    SizedBox(width: 10),

                    // apple buttom
                    SquareTile(imagePath: 'lib/images/apple.png')
                  ],
                ),

                const SizedBox(height: 25),

                // Not a user? Register now
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account?',
                    style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Login Here',
                      style: TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.bold,
                      )
                    ),
                  ],
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
