import 'package:flutter/material.dart';
import 'forgot1.dart'; // Pour revenir à la page précédente
import 'confirmation2.dart'; // Pour aller à la prochaine étape

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ConfirmationPage(),
  ));
}

class ConfirmationPage extends StatelessWidget {
  const ConfirmationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Bouton retour vers forgot1.dart
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
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const Forgot1Page()),
                    );
                  },
                ),
              ),
            ),

            // Contenu principal
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 100, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Center(
                    child: Text(
                      'Check your email',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF159BBD),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Center(
                    child: SizedBox(
                      width: 169,
                      height: 2,
                      child: ColoredBox(color: Color(0xFF159BBD)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'We sent a reset link to josue@healthcare+.com',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Enter 5 digit code that mentioned in the email',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 5 boîtes de code
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(5, (index) {
                      return Container(
                        width: 56,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey),
                          color: Colors.white,
                        ),
                        child: const Text(
                          '',
                          style: TextStyle(fontSize: 20),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),

                  // Bouton Verify Code
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Confirmation2Page(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF159BBD),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Verify Code',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Texte "Resend email"
                  const Center(
                    child: Wrap(
                      children: [
                        Text(
                          "Haven’t got the email yet? ",
                          style: TextStyle(color: Colors.black54),
                        ),
                        Text(
                          "Resend email",
                          style: TextStyle(
                            color: Color(0xFF159BBD),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
