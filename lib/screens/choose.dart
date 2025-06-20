import 'package:flutter/material.dart';
import 'package:homecare_app/main.dart';
import 'package:homecare_app/screens/login.dart';
import 'package:homecare_app/screens/patient_dashboard.dart';
import 'login2.dart';

class ChoosePage extends StatelessWidget {
  const ChoosePage({super.key});

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
        child: SafeArea(
        child: Stack(
          children: [
            // Bouton retour
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                ),
                width: 48,
                height: 48,
                child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF159BBD)),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfessionalWelcomeScreen()),
                      );
                    },
                ),
              ),
            ),

            // Titre + Conteneurs
            Positioned(
              top: 120,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'How would you like to continue?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 24,
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
                    const SizedBox(height: 40),

                  // Conteneur patient
                    Container(
                      width: 302,
                      height: 194,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const PatientDashboardPage()),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/patient1.png',
                            height: 100,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'As a Patient',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                                    color: Color(0xFF159BBD),
                            ),
                          ),
                        ],
                            ),
                          ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Conteneur clinic
                    Container(
                      width: 302,
                      height: 194,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const Login2Page()),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/doctor1.png',
                            height: 100,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'As a Health Center',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                                    color: Color(0xFF159BBD),
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
          ],
          ),
        ),
      ),
    );
  }
}
