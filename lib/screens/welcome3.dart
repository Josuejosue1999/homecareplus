import 'package:flutter/material.dart';
import 'choose.dart';
import 'welcome2.dart'; // Pour revenir à la page précédente

class Welcome3Page extends StatefulWidget {
  const Welcome3Page({super.key});

  @override
  State<Welcome3Page> createState() => _Welcome3PageState();
}

class _Welcome3PageState extends State<Welcome3Page>
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
      MaterialPageRoute(builder: (context) => const Welcome2Page()),
    );
  }

  void navigateToChoose() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ChoosePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
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
                    'assets/welcome3.png',
                    height: 300,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const Text(
              'Easy appointment booking',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Text(
                'Book with confidence - Easy to use - Quick operation',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: ElevatedButton(
                onPressed: navigateToChoose,
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
