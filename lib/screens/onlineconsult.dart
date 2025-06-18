import 'package:flutter/material.dart';
import 'aboutdoctor.dart'; // ✅ Assure-toi que ce fichier existe et contient une classe AboutDoctorPage
import '../widgets/bottom_navigation.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: OnlineConsultPage(),
  ));
}

class OnlineConsultPage extends StatelessWidget {
  const OnlineConsultPage({super.key});

  Widget buildDoctorCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AboutDoctorPage()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
        child: Container(
          width: 351,
          height: 89,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF4FF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const SizedBox(width: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/doctor2.png',
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Text(
                          'Dr Josue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.circle, size: 10, color: Colors.green),
                        SizedBox(width: 4),
                        Text(
                          'online',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Dentist',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (index) => const Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber,
                      )),
                    )
                  ],
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Align(
                  alignment: Alignment.topLeft,
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
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Online Consultation',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF159BBD),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: SizedBox(
                  width: 169,
                  height: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFF159BBD),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 356,
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF4FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Search',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                        ),
                      ),
                      Icon(Icons.search, color: Colors.black45),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'All Doctor',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Cartes interactives des docteurs
              buildDoctorCard(context),
              buildDoctorCard(context),
              buildDoctorCard(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigation(
          currentIndex: 1,
        context: context,
      ),
    );
  }
}
