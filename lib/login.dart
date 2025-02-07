import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:srm_hope/Utilities/data_saver.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'Utilities/credentials.dart';


class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordHidden = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _verifyAndDeleteUserData();
  }

  Future<void> _verifyAndDeleteUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await UserSession.clearSession(); // Delete session file
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during session verification: $e')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.cyanAccent, Colors.yellow, Colors.deepOrange, Colors.blueAccent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                const Padding(
                  padding: EdgeInsets.only(bottom: 45),
                  child: CircleAvatar(
                    radius: 75,
                    backgroundColor: Colors.blue,
                    backgroundImage: AssetImage('assets/images/app_logo.png'),
                  ),
                ),

                // Title
                const Text(
                  "SRM One - Delhi-NCR",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Use your student portal details to sign in.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 30),

                // Email Input
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black,
                      hintText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Password Input
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _isPasswordHidden,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black,
                      hintText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordHidden
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            _isPasswordHidden = !_isPasswordHidden;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Sign In Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    final email = _emailController.text;
                    final password = _passwordController.text;

                    if (email.isEmpty || password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill in both email and password')),
                      );
                      return;
                    }

                    setState(() {
                      _isLoading = true;
                    });


                      final url = Uri.parse('https://api-srm-one.onrender.com/loginX');
                      final Map<String, String> body = {
                        'user': email,
                        'password': password,
                      };
                      final response = await http.post(
                        url,
                        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
                        body: body,
                      );
                    final responseBody1 = jsonDecode(response.body);
                      if (responseBody1['Status'] == null) {
                        final responseBody = jsonDecode(response.body);
                        await UserSession.saveSession(responseBody['sid']);
                        await UserCredentials.saveCredentials(email, password);
                        final sName = responseBody['studentname'];
                          // Navigate to the next screen after login
                        Navigator.pushReplacementNamed(context, '/home');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Welcome $sName")),
                        );

                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invalid Net ID or Password')),
                        );
                      }


                    setState(() {
                      _isLoading = false;
                    });
                  },
                  child: const Text(
                    'Sign In',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 15),

                // Forgot Password Link
                TextButton(
                  onPressed: () async {
                    final Uri url = Uri.parse('https://ssp.srmist.edu.in/resetpassword/');
                    await launchUrl(url);
                  },
                  child: const Text(
                    'Forgot Password',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 15),

              ],
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
