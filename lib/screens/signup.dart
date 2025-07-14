import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;


  


  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _initializeBubbleAnimations() {
    // Initialize bubble animation controllers with different durations for variety
    _bubble1Controller = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    _bubble2Controller = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    );
    _bubble3Controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    _bubble4Controller = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );
    _bubble5Controller = AnimationController(
      duration: const Duration(seconds: 9),
      vsync: this,
    );
    _bubble6Controller = AnimationController(
      duration: const Duration(seconds: 13),
      vsync: this,
    );
    _bubble7Controller = AnimationController(
      duration: const Duration(seconds: 11),
      vsync: this,
    );
    _bubble8Controller = AnimationController(
      duration: const Duration(seconds: 14),
      vsync: this,
    );
    _bubble9Controller = AnimationController(
      duration: const Duration(seconds: 7),
      vsync: this,
    );
    _bubble10Controller = AnimationController(
      duration: const Duration(seconds: 16),
      vsync: this,
    );
    _bubble11Controller = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );
    _bubble12Controller = AnimationController(
      duration: const Duration(seconds: 18),
      vsync: this,
    );

    // Create bubble movement animations
    _bubble1Animation = Tween<Offset>(
      begin: const Offset(-0.1, 0.8),
      end: const Offset(1.1, -0.2),
    ).animate(CurvedAnimation(
      parent: _bubble1Controller,
      curve: Curves.linear,
    ));

    _bubble2Animation = Tween<Offset>(
      begin: const Offset(1.1, 0.9),
      end: const Offset(-0.1, -0.1),
    ).animate(CurvedAnimation(
      parent: _bubble2Controller,
      curve: Curves.linear,
    ));

    _bubble3Animation = Tween<Offset>(
      begin: const Offset(0.5, 1.2),
      end: const Offset(0.3, -0.3),
    ).animate(CurvedAnimation(
      parent: _bubble3Controller,
      curve: Curves.easeInOut,
    ));

    _bubble4Animation = Tween<Offset>(
      begin: const Offset(-0.2, 1.0),
      end: const Offset(1.2, 0.1),
    ).animate(CurvedAnimation(
      parent: _bubble4Controller,
      curve: Curves.easeInOut,
    ));

    _bubble5Animation = Tween<Offset>(
      begin: const Offset(0.8, 1.3),
      end: const Offset(0.1, -0.3),
    ).animate(CurvedAnimation(
      parent: _bubble5Controller,
      curve: Curves.linear,
    ));

    _bubble6Animation = Tween<Offset>(
      begin: const Offset(0.3, 1.4),
      end: const Offset(0.7, -0.4),
    ).animate(CurvedAnimation(
      parent: _bubble6Controller,
      curve: Curves.easeInOut,
    ));

    _bubble7Animation = Tween<Offset>(
      begin: const Offset(1.0, 1.1),
      end: const Offset(0.0, -0.1),
    ).animate(CurvedAnimation(
      parent: _bubble7Controller,
      curve: Curves.linear,
    ));

    _bubble8Animation = Tween<Offset>(
      begin: const Offset(-0.3, 1.5),
      end: const Offset(1.3, -0.5),
    ).animate(CurvedAnimation(
      parent: _bubble8Controller,
      curve: Curves.easeInOut,
    ));

    _bubble9Animation = Tween<Offset>(
      begin: const Offset(0.6, 1.0),
      end: const Offset(0.4, 0.0),
    ).animate(CurvedAnimation(
      parent: _bubble9Controller,
      curve: Curves.linear,
    ));

    _bubble10Animation = Tween<Offset>(
      begin: const Offset(0.1, 1.6),
      end: const Offset(0.9, -0.6),
    ).animate(CurvedAnimation(
      parent: _bubble10Controller,
      curve: Curves.easeInOut,
    ));

    _bubble11Animation = Tween<Offset>(
      begin: const Offset(1.2, 0.8),
      end: const Offset(-0.2, 0.2),
    ).animate(CurvedAnimation(
      parent: _bubble11Controller,
      curve: Curves.linear,
    ));

    _bubble12Animation = Tween<Offset>(
      begin: const Offset(0.4, 1.7),
      end: const Offset(0.6, -0.7),
    ).animate(CurvedAnimation(
      parent: _bubble12Controller,
      curve: Curves.easeInOut,
    ));

    // Start bubble animations
    _bubble1Controller.repeat();
    _bubble2Controller.repeat();
    _bubble3Controller.repeat();
    _bubble4Controller.repeat();
    _bubble5Controller.repeat();
    _bubble6Controller.repeat();
    _bubble7Controller.repeat();
    _bubble8Controller.repeat();
    _bubble9Controller.repeat();
    _bubble10Controller.repeat();
    _bubble11Controller.repeat();
    _bubble12Controller.repeat();
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Create user with email and password
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
          password: _passwordController.text,
      );

        // Add user details to Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
          'role': 'patient',
        });

        // Navigate to login page
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage;
        switch (e.code) {
          case 'weak-password':
            errorMessage = 'The password provided is too weak.';
            break;
          case 'email-already-in-use':
            errorMessage = 'An account already exists for that email.';
            break;
          case 'invalid-email':
            errorMessage = 'The email address is invalid.';
            break;
          default:
            errorMessage = 'An error occurred. Please try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
    } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred. Please try again.')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
                decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF159BBD),
              const Color(0xFF0D5C73),
              const Color(0xFF0D5C73).withOpacity(0.8),
              Colors.white,
            ],
            stops: const [0.0, 0.4, 0.7, 0.9],
          ),
        ),
        child: Stack(
          children: [
            // Animated Bubbles Background
            // Bubble 1
            AnimatedBuilder(
              animation: _bubble1Animation,
              builder: (context, child) {
                return Positioned(
                  left: _bubble1Animation.value.dx * MediaQuery.of(context).size.width,
                  top: _bubble1Animation.value.dy * MediaQuery.of(context).size.height,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.15),
                          Colors.white.withOpacity(0.05),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            // Bubble 2
            AnimatedBuilder(
              animation: _bubble2Animation,
              builder: (context, child) {
                return Positioned(
                  left: _bubble2Animation.value.dx * MediaQuery.of(context).size.width,
                  top: _bubble2Animation.value.dy * MediaQuery.of(context).size.height,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.2),
                          Colors.white.withOpacity(0.08),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            // Bubble 3
            AnimatedBuilder(
              animation: _bubble3Animation,
              builder: (context, child) {
                return Positioned(
                  left: _bubble3Animation.value.dx * MediaQuery.of(context).size.width,
                  top: _bubble3Animation.value.dy * MediaQuery.of(context).size.height,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.03),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            // Bubble 4
            AnimatedBuilder(
              animation: _bubble4Animation,
              builder: (context, child) {
                return Positioned(
                  left: _bubble4Animation.value.dx * MediaQuery.of(context).size.width,
                  top: _bubble4Animation.value.dy * MediaQuery.of(context).size.height,
                  child: Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.25),
                          Colors.white.withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            // Bubble 5
            AnimatedBuilder(
              animation: _bubble5Animation,
              builder: (context, child) {
                return Positioned(
                  left: _bubble5Animation.value.dx * MediaQuery.of(context).size.width,
                  top: _bubble5Animation.value.dy * MediaQuery.of(context).size.height,
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.withOpacity(0.3),
                          Colors.blue.withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            // Bubble 6
            AnimatedBuilder(
              animation: _bubble6Animation,
              builder: (context, child) {
                return Positioned(
                  left: _bubble6Animation.value.dx * MediaQuery.of(context).size.width,
                  top: _bubble6Animation.value.dy * MediaQuery.of(context).size.height,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.teal.withOpacity(0.25),
                          Colors.teal.withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            // Bubble 7
            AnimatedBuilder(
              animation: _bubble7Animation,
              builder: (context, child) {
                return Positioned(
                  left: _bubble7Animation.value.dx * MediaQuery.of(context).size.width,
                  top: _bubble7Animation.value.dy * MediaQuery.of(context).size.height,
                  child: Container(
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.withOpacity(0.2),
                          Colors.purple.withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            // Bubble 8
            AnimatedBuilder(
              animation: _bubble8Animation,
              builder: (context, child) {
                return Positioned(
                  left: _bubble8Animation.value.dx * MediaQuery.of(context).size.width,
                  top: _bubble8Animation.value.dy * MediaQuery.of(context).size.height,
                  child: Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.cyan.withOpacity(0.3),
                          Colors.cyan.withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            // Bubble 9
            AnimatedBuilder(
              animation: _bubble9Animation,
              builder: (context, child) {
                return Positioned(
                  left: _bubble9Animation.value.dx * MediaQuery.of(context).size.width,
                  top: _bubble9Animation.value.dy * MediaQuery.of(context).size.height,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.withOpacity(0.25),
                          Colors.orange.withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            // Bubble 10
            AnimatedBuilder(
              animation: _bubble10Animation,
              builder: (context, child) {
                return Positioned(
                  left: _bubble10Animation.value.dx * MediaQuery.of(context).size.width,
                  top: _bubble10Animation.value.dy * MediaQuery.of(context).size.height,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.pink.withOpacity(0.2),
                          Colors.pink.withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            // Bubble 11
            AnimatedBuilder(
              animation: _bubble11Animation,
              builder: (context, child) {
                return Positioned(
                  left: _bubble11Animation.value.dx * MediaQuery.of(context).size.width,
                  top: _bubble11Animation.value.dy * MediaQuery.of(context).size.height,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.lime.withOpacity(0.3),
                          Colors.lime.withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            // Bubble 12
            AnimatedBuilder(
              animation: _bubble12Animation,
              builder: (context, child) {
                return Positioned(
                  left: _bubble12Animation.value.dx * MediaQuery.of(context).size.width,
                  top: _bubble12Animation.value.dy * MediaQuery.of(context).size.height,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.indigo.withOpacity(0.25),
                          Colors.indigo.withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            // Main Content
            SafeArea(
          child: SingleChildScrollView(
              child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 2),
                            blurRadius: 4,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign up to get started',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(Icons.person_outline, color: Colors.white70),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(Icons.email, color: Colors.white70),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(Icons.phone, color: Colors.white70),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        controller: _passwordController,
                            obscureText: _obscurePassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                          suffixIcon: IconButton(
                            icon: Icon(
                                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                            setState(() {
                                    _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                          suffixIcon: IconButton(
                            icon: Icon(
                                  _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF159BBD),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF159BBD)),
                                ),
                              )
                            : const Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(color: Color(0xFF159BBD)),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginPage()),
                            );
                          },
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              color: Color(0xFF159BBD),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
            ),
          ],
        ),
      ),
    );
  }
}
