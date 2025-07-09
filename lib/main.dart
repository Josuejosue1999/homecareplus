import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/choose.dart';
import 'screens/pro_hospitals_page.dart';
import 'screens/patient_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HomeCare Plus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF159BBD),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF159BBD),
          primary: const Color(0xFF159BBD),
          secondary: const Color(0xFF42A5F5),
        ),
        useMaterial3: true,
        fontFamily: 'Ubuntu',
      ),
      home: const ProfessionalWelcomeScreen(),
    );
  }
}

class ProfessionalWelcomeScreen extends StatefulWidget {
  const ProfessionalWelcomeScreen({Key? key}) : super(key: key);

  @override
  State<ProfessionalWelcomeScreen> createState() => _ProfessionalWelcomeScreenState();
}

class _ProfessionalWelcomeScreenState extends State<ProfessionalWelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _featuresController;
  late AnimationController _buttonController;

  // Bubble animation controllers (12 bubbles)
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

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _textOpacity;
  late Animation<Offset> _featuresSlide;
  late Animation<double> _buttonScale;

  // Bubble position animations
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
    _initializeAnimations();
    _initializeBubbleAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _featuresController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _logoScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _logoOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));

    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));

    _featuresSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _featuresController,
      curve: Curves.easeOutCubic,
    ));

    _buttonScale = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.elasticOut,
    ));
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

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _textController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _featuresController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _buttonController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _featuresController.dispose();
    _buttonController.dispose();
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

  void _navigateToChoose() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const PatientDashboardPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF159BBD),
              Color(0xFF0D5C73),
              Color(0xFF0A4A5E),
              Color(0xFF083D4F),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
        children: [
              // Background Pattern
              Positioned.fill(
                child: CustomPaint(
                  painter: BackgroundPatternPainter(),
                ),
              ),
              
              // Animated Bubbles
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
              // Bubble 3
              AnimatedBuilder(
                animation: _bubble3Animation,
                builder: (context, child) {
                  return Positioned(
                    left: _bubble3Animation.value.dx * MediaQuery.of(context).size.width,
                    top: _bubble3Animation.value.dy * MediaQuery.of(context).size.height,
                    child: Container(
                      width: 50,
                      height: 50,
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
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.12),
                            Colors.white.withOpacity(0.04),
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
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.08),
                            Colors.white.withOpacity(0.02),
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
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0.12),
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
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.18),
                            Colors.white.withOpacity(0.06),
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
                      width: 75,
                      height: 75,
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
              // Bubble 11
              AnimatedBuilder(
                animation: _bubble11Animation,
                builder: (context, child) {
                  return Positioned(
                    left: _bubble11Animation.value.dx * MediaQuery.of(context).size.width,
                    top: _bubble11Animation.value.dy * MediaQuery.of(context).size.height,
                    child: Container(
                      width: 30,
                      height: 30,
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
              // Bubble 12
              AnimatedBuilder(
                animation: _bubble12Animation,
                builder: (context, child) {
                  return Positioned(
                    left: _bubble12Animation.value.dx * MediaQuery.of(context).size.width,
                    top: _bubble12Animation.value.dy * MediaQuery.of(context).size.height,
                    child: Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.14),
                            Colors.white.withOpacity(0.05),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              // Main Content
              SingleChildScrollView(
            child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      
                      // Logo Section
                      AnimatedBuilder(
                        animation: _logoController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _logoScale.value,
                            child: Opacity(
                              opacity: _logoOpacity.value,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(35),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 30,
                                      offset: const Offset(0, 15),
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.local_hospital,
                                  size: 70,
                                  color: Color(0xFF159BBD),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Text Section
                      SlideTransition(
                        position: _textSlide,
                        child: FadeTransition(
                          opacity: _textOpacity,
              child: Column(
                children: [
                              const Text(
                                'HomeCare Plus',
                    style: TextStyle(
                                  fontSize: 36,
                      fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                      shadows: [
                        Shadow(
                                      offset: Offset(0, 2),
                                      blurRadius: 8,
                                      color: Colors.black38,
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Your Health, Osur Priority',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 50),
                      
                      // Features Section
                      SlideTransition(
                        position: _featuresSlide,
                        child: Column(
                          children: [
                            _buildProfessionalFeature(
                              icon: Icons.medical_services,
                              title: 'Professional Healthcare',
                              subtitle: 'Connect with certified medical professionals',
                              color: Colors.blue,
                            ),
                            const SizedBox(height: 16),
                            _buildProfessionalFeature(
                              icon: Icons.schedule,
                              title: '24/7 Availability',
                              subtitle: 'Get medical assistance anytime, anywhere',
                              color: Colors.green,
                            ),
                            const SizedBox(height: 16),
                            _buildProfessionalFeature(
                              icon: Icons.security,
                              title: 'Secure & Private',
                              subtitle: 'Your health data is protected and confidential',
                              color: Colors.orange,
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                    ],
                  ),
                ),
              ),
              
              // Bottom Button Section
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        const Color(0xFF0A4A5E).withOpacity(0.8),
                        const Color(0xFF0A4A5E),
                      ],
                    ),
                  ),
                  child: AnimatedBuilder(
                    animation: _buttonController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _buttonScale.value,
                        child: SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _navigateToChoose,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF159BBD),
                              elevation: 12,
                              shadowColor: Colors.black.withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Get Started',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfessionalFeature({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
                        ),
                      ],
                    ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;

    // Draw diagonal lines
    for (int i = 0; i < size.width + size.height; i += 30) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(0, i.toDouble()),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}