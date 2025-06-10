import 'package:flutter/material.dart';
import 'welcome1.dart'; // Redirection vers la page précédente
import 'welcome3.dart'; // Redirection vers la page suivante

class Welcome2Page extends StatefulWidget {
  const Welcome2Page({super.key});

  @override
  State<Welcome2Page> createState() => _Welcome2PageState();
}

class _Welcome2PageState extends State<Welcome2Page>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void navigateBack() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Welcome1Page()),
    );
  }

  void navigateNext() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Welcome3Page()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Flèche retour
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF159BBD),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: navigateBack,
                  ),
                ),
              ),
            ),

            // Image centrée avec effet zoom flottant
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, 5 * (_animation.value - 1)),
                      child: Transform.scale(
                        scale: _animation.value,
                        child: child,
                      ),
                    );
                  },
                  child: Image.asset(
                    'assets/welcome2.png',
                    height: 300,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // Titre
            const Text(
              'Access Over 10 Certified Facilities',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            // Sous-titre
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Text(
                'Get connected to certified hospitals and clinics near you for in-person or virtual consultations.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ),

            // Bouton Next
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: ElevatedButton(
                onPressed: navigateNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF159BBD),
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Next',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
