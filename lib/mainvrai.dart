import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'screens/welcome1.dart'; 


void main() {
  runApp(HomeCareApp());
}

class HomeCareApp extends StatelessWidget {
  const HomeCareApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HomeCare+',
      debugShowCheckedModeBanner: false,
      home: SplashScreenWithAnimation(),
    );
  }
}

class SplashScreenWithAnimation extends StatefulWidget {
  const SplashScreenWithAnimation({Key? key}) : super(key: key);
  @override
  _SplashScreenWithAnimationState createState() => _SplashScreenWithAnimationState();
}

class _SplashScreenWithAnimationState extends State<SplashScreenWithAnimation> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _expansionController;
  late AnimationController _repositionController;
  late AnimationController _buttonFloatController;
  late AnimationController _buttonScaleController;

  late Animation<double> _rotationAnimation;
  late Animation<double> _expansionAnimation;
  late Animation<double> _repositionAnimation;
  late Animation<Offset> _buttonFloatAnimation;
  late Animation<double> _buttonScaleAnimation;

  bool _animationStarted = false;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _expansionController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _repositionController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _buttonFloatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _buttonScaleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    _expansionAnimation = Tween<double>(begin: 1.0, end: 20.0).animate(CurvedAnimation(
      parent: _expansionController,
      curve: Curves.easeOut,
    ));

    _repositionAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(
      parent: _repositionController,
      curve: Curves.linear,
    ));

    _buttonFloatAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(0, -0.05),
    ).animate(CurvedAnimation(
      parent: _buttonFloatController,
      curve: Curves.easeInOut,
    ));

    _buttonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _buttonScaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _expansionController.dispose();
    _repositionController.dispose();
    _buttonFloatController.dispose();
    _buttonScaleController.dispose();
    super.dispose();
  }

  void _startAnimation() {
    if (!_animationStarted) {
      setState(() {
        _animationStarted = true;
      });

      _rotationController.stop();

      _repositionController.forward().then((_) {
        Timer(Duration(seconds: 1), () {
          _expansionController.forward().then((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Welcome1Page()),
            );
          });
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'The Best Platform for Online Consultation!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF159BBD),
                      fontFamily: 'Ubuntu',
                      shadows: [
                        Shadow(
                          offset: Offset(5.0, 5.0),
                          blurRadius: 10.0,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  SlideTransition(
                    position: _buttonFloatAnimation,
                    child: ScaleTransition(
                      scale: _buttonScaleAnimation,
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _animationStarted ? null : _startAnimation,
                          child: Text('Get Started'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF159BBD),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            textStyle: TextStyle(
                              fontSize: 20,
                              fontFamily: 'Ubuntu',
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            elevation: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _rotationController,
                _expansionController,
                _repositionController,
              ]),
              builder: (context, child) {
                double rotationValue = _animationStarted
                    ? _repositionAnimation.value * 2 * vector.radians(180)
                    : _rotationAnimation.value * 2 * vector.radians(180);
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(rotationValue)
                    ..scale(_expansionAnimation.value),
                  child: Text(
                    'H',
                    style: TextStyle(
                      fontSize: 200.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF159BBD),
                      shadows: [
                        Shadow(
                          offset: Offset(10, 10),
                          blurRadius: 10.0,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
