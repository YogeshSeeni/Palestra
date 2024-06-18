import 'package:Palestra/components/my_button.dart';
import 'package:Palestra/components/my_textfield.dart';
import 'package:Palestra/components/square_tile.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  // text editing controllers
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  // sign user in method
  void signUserIn()
  {

  }

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
                const SizedBox(height: 50),
          
                // logo
                Image.asset(
                  'lib/images/logo.png',
                  height: 100
                ),
          
                const SizedBox(height: 25),

                // "Welcome to the future of fitness."
                Text('Welcome to the future of fitness.',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 16,
                    )),
          
                const SizedBox(height: 25),
          
                // Username text field
                MyTextField(
                  controller: usernameController,
                  hintText: 'Username',
                  obscureText: false
                ),
          
                const SizedBox(height: 10),
          
                // Password text field
                MyTextField(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: true
                ),
          
                // Forgot password?
                Text(
                  'Forgot Password?',
                  style: TextStyle(color: Colors.grey[600])
                ),
                
                const SizedBox(height: 25),
          
                // Sign in button
                MyButton(
                  onTap: signUserIn,
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
                    Text('Not a member?',
                    style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Register now',
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
