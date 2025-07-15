import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:homecare_plus/screens/forgot_password_confirmation.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  // Animation controllers for moving bubbles (12 bubbles)
  late AnimationController _bubble1Controller;
  late AnimationController _bubble2Controller;
  late AnimationController _bubble3Controller;
  late AnimationController _bubble4Controller;
  late AnimationController _bubble5Controller;
  late AnimationController _bubble6Controller;
  late AnimationController _bubble7Controller;
  late AnimationController _bubble8Controller;
  late AnimationController _bubble9Controller;
  late AnimationController _bubble10Controller;
  late AnimationController _bubble11Controller;
  late AnimationController _bubble12Controller;
  
  // Animations for bubble positions
  late Animation<Offset> _bubble1Animation;
  late Animation<Offset> _bubble2Animation;
  late Animation<Offset> _bubble3Animation;
  late Animation<Offset> _bubble4Animation;
  late Animation<Offset> _bubble5Animation;
  late Animation<Offset> _bubble6Animation;
  late Animation<Offset> _bubble7Animation;
  late Animation<Offset> _bubble8Animation;
  late Animation<Offset> _bubble9Animation;
  late Animation<Offset> _bubble10Animation;
  late Animation<Offset> _bubble11Animation;
  late Animation<Offset> _bubble12Animation;

  @override
  void initState() {
    super.initState();
    _initializeBubbleAnimations();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _bubble1Controller.dispose();
    _bubble2Controller.dispose();
    _bubble3Controller.dispose();
    _bubble4Controller.dispose();
    _bubble5Controller.dispose();
    _bubble6Controller.dispose();
    _bubble7Controller.dispose();
    _bubble8Controller.dispose();
    _bubble9Controller.dispose();
    _bubble10Controller.dispose();
    _bubble11Controller.dispose();
    _bubble12Controller.dispose();
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

  Future<void> _sendPasswordResetEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(
          email: _emailController.text.trim(),
        );
        
        if (!mounted) return;
        
        // Navigate to confirmation page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ForgotPasswordConfirmationPage(
              email: _emailController.text.trim(),
            ),
          ),
        );
      } on FirebaseAuthException catch (e) {
        String message = 'An error occurred';
        if (e.code == 'user-not-found') {
          message = 'No user found with this email address';
        } else if (e.code == 'invalid-email') {
          message = 'Invalid email address';
        }
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred. Please try again.'),
            backgroundColor: Colors.red,
          ),
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
            // Bubble 6
            AnimatedBuilder(
              animation: _bubble6Animation,
              builder: (context, child) {
                return Positioned(
                  left: _bubble6Animation.value.dx * MediaQuery.of(context).size.width,
                  top: _bubble6Animation.value.dy * MediaQuery.of(context).size.height,
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
            // Bubble 7
            AnimatedBuilder(
              animation: _bubble7Animation,
              builder: (context, child) {
                return Positioned(
                  left: _bubble7Animation.value.dx * MediaQuery.of(context).size.width,
                  top: _bubble7Animation.value.dy * MediaQuery.of(context).size.height,
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
            // Bubble 8
            AnimatedBuilder(
              animation: _bubble8Animation,
              builder: (context, child) {
                return Positioned(
                  left: _bubble8Animation.value.dx * MediaQuery.of(context).size.width,
                  top: _bubble8Animation.value.dy * MediaQuery.of(context).size.height,
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
            // Bubble 9
            AnimatedBuilder(
              animation: _bubble9Animation,
              builder: (context, child) {
                return Positioned(
                  left: _bubble9Animation.value.dx * MediaQuery.of(context).size.width,
                  top: _bubble9Animation.value.dy * MediaQuery.of(context).size.height,
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
            // Bubble 10
            AnimatedBuilder(
              animation: _bubble10Animation,
              builder: (context, child) {
                return Positioned(
                  left: _bubble10Animation.value.dx * MediaQuery.of(context).size.width,
                  top: _bubble10Animation.value.dy * MediaQuery.of(context).size.height,
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
            // Bubble 11
            AnimatedBuilder(
              animation: _bubble11Animation,
              builder: (context, child) {
                return Positioned(
                  left: _bubble11Animation.value.dx * MediaQuery.of(context).size.width,
                  top: _bubble11Animation.value.dy * MediaQuery.of(context).size.height,
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
            // Bubble 12
            AnimatedBuilder(
              animation: _bubble12Animation,
              builder: (context, child) {
                return Positioned(
                  left: _bubble12Animation.value.dx * MediaQuery.of(context).size.width,
                  top: _bubble12Animation.value.dy * MediaQuery.of(context).size.height,
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
                            Navigator.pop(context);
                          },
                        ),
                        const SizedBox(height: 40),
                        const Text(
                          'Forgot Password?',
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
                          'Enter your email address and we\'ll send you a link to reset your password.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 40),
                        
                        // Email Input Field
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
                              labelText: 'Email Address',
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
                                return 'Please enter your email address';
                              }
                              if (!value.contains('@') || !value.contains('.')) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Send Reset Link Button
                        _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: _sendPasswordResetEmail,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF159BBD),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: const Text(
                                    'Send Reset Link',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                        const SizedBox(height: 24),
                        
                        // Back to Login
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Back to Login',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ),
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