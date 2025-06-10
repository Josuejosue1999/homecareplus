import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool isTermsAccepted = false;

  void onBackPressed(BuildContext context) {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  Future<void> onContinuePressed() async {
    if (!isTermsAccepted) {
      _showMessage('Please accept the Terms and Conditions');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showMessage('Passwords do not match');
      return;
    }

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'fullName': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      _showMessage("Account created successfully!");
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
    } catch (e) {
      _showMessage('Error: ${e.toString()}');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF159BBD),
                  borderRadius: BorderRadius.circular(30),
                ),
                width: 48,
                height: 48,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => onBackPressed(context),
                ),
              ),
            ),
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 90, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(child: Text('Sign Up', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF159BBD)))),
                    const SizedBox(height: 8),
                    Center(child: Container(width: 169, height: 3, color: const Color(0xFF159BBD))),
                    const SizedBox(height: 40),
                    const Text('Your Full Name', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    buildInputField(controller: _fullNameController),
                    const SizedBox(height: 20),
                    const Text('Your Email', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    buildInputField(controller: _emailController, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 20),
                    const Text('Password', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    buildInputField(controller: _passwordController, obscureText: true),
                    const SizedBox(height: 20),
                    const Text('Confirm Password', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    buildInputField(controller: _confirmPasswordController, obscureText: true),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: isTermsAccepted,
                          activeColor: const Color(0xFF159BBD),
                          onChanged: (value) {
                            setState(() {
                              isTermsAccepted = value ?? false;
                            });
                          },
                        ),
                        const Expanded(
                          child: Text('I accept the Terms and Conditions', style: TextStyle(fontSize: 14)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onContinuePressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF159BBD),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Continue', style: TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(child: Divider(color: Color(0xFFE1E1E1), thickness: 1)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('OR'),
                        ),
                        Expanded(child: Divider(color: Color(0xFFE1E1E1), thickness: 1)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFD9D9D9)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/pngwing2.png', width: 24, height: 24),
                            const SizedBox(width: 12),
                            const Text('Sign up with Google', style: TextStyle(fontSize: 16, color: Colors.black)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account? "),
                        GestureDetector(
                          onTap: () => onBackPressed(context),
                          child: const Text("Login", style: TextStyle(color: Color(0xFF159BBD), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInputField({required TextEditingController controller, bool obscureText = false, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: const InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFFD9D9D9)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFFD9D9D9)),
        ),
      ),
    );
  }
}
