import 'package:flutter/material.dart';
import 'facilities.dart';
import 'choose.dart';
import 'hospital_details.dart';

class PatientDashboardPage extends StatelessWidget {
  const PatientDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Back Button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF159BBD),
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF159BBD)),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const ChoosePage()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Patient Dashboard',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Premium Healthcare Network',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF159BBD),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Professional Healthcare Services',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Search Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search for facilities...',
                          border: InputBorder.none,
                          icon: const Icon(Icons.search, color: Color(0xFF159BBD)),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.filter_list, color: Color(0xFF159BBD)),
                            onPressed: () {},
                          ),
                        ),
                        onSubmitted: (value) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const FacilitiesPage()),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF159BBD).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Color(0xFF159BBD),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Nearby Hospitals',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF159BBD),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Hospital Images with Titles
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Container(
                                    height: 120,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      image: const DecorationImage(
                                        image: AssetImage('assets/hospital.PNG'),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.1),
                                          spreadRadius: 1,
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        const Text(
                                          'Mayo Clinic',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF159BBD),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Emergency • ICU • Surgery • Lab • Pharmacy',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.location_on,
                                              size: 10,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 2),
                                            const Text(
                                              '200 First St SW, Rochester, MN 55905',
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF159BBD),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => HospitalDetailsPage(
                                                    hospitalName: 'Mayo Clinic',
                                                    hospitalImage: 'assets/hospital.PNG',
                                                    address: '200 First St SW, Rochester, MN 55905',
                                                    facilities: ['Emergency Care', 'Surgery', 'ICU', 'Laboratory'],
                                                    rating: 4.5,
                                                    reviewCount: 128,
                                                    reviews: [
                                                      {
                                                        'name': 'John Smith',
                                                        'rating': '4.5',
                                                        'date': '2 days ago',
                                                        'comment': 'Excellent service and professional staff. The facilities are modern and well-maintained.',
                                                      },
                                                      {
                                                        'name': 'Sarah Johnson',
                                                        'rating': '5.0',
                                                        'date': '1 week ago',
                                                        'comment': 'The doctors were very attentive and the care was exceptional. Highly recommended!',
                                                      },
                                                      {
                                                        'name': 'Michael Brown',
                                                        'rating': '4.0',
                                                        'date': '2 weeks ago',
                                                        'comment': 'Good experience overall. The staff was friendly and the wait times were reasonable.',
                                                      },
                                                      {
                                                        'name': 'Emily Davis',
                                                        'rating': '4.8',
                                                        'date': '3 weeks ago',
                                                        'comment': 'Very impressed with the level of care and attention to detail. The facilities are top-notch.',
                                                      },
                                                      {
                                                        'name': 'David Wilson',
                                                        'rating': '4.2',
                                                        'date': '1 month ago',
                                                        'comment': 'Professional staff and clean facilities. The doctors took time to explain everything clearly.',
                                                      },
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                            child: const Text(
                                              'View More',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                children: [
                                  Container(
                                    height: 120,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      image: const DecorationImage(
                                        image: AssetImage('assets/hospital2.PNG'),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.1),
                                          spreadRadius: 1,
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        const Text(
                                          'Specialized Clinic',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF159BBD),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Cardiology • Neurology • Orthopedics • ENT • Dental',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.location_on,
                                              size: 10,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 2),
                                            const Text(
                                              '456 Health Avenue',
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF159BBD),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => HospitalDetailsPage(
                                                    hospitalName: 'Specialized Clinic',
                                                    hospitalImage: 'assets/hospital2.PNG',
                                                    address: '456 Health Street, Medical District',
                                                    facilities: ['Specialized Care', 'Diagnostics', 'Rehabilitation', 'Pharmacy'],
                                                    rating: 4.8,
                                                    reviewCount: 95,
                                                    reviews: [
                                                      {
                                                        'name': 'Lisa Anderson',
                                                        'rating': '4.8',
                                                        'date': '3 days ago',
                                                        'comment': 'The specialized care here is outstanding. The doctors are experts in their fields.',
                                                      },
                                                      {
                                                        'name': 'Robert Taylor',
                                                        'rating': '5.0',
                                                        'date': '1 week ago',
                                                        'comment': 'Excellent diagnostic services and follow-up care. Very satisfied with the treatment.',
                                                      },
                                                      {
                                                        'name': 'Jennifer White',
                                                        'rating': '4.7',
                                                        'date': '2 weeks ago',
                                                        'comment': 'The rehabilitation program was very effective. The therapists are highly skilled.',
                                                      },
                                                      {
                                                        'name': 'Thomas Martin',
                                                        'rating': '4.9',
                                                        'date': '3 weeks ago',
                                                        'comment': 'Great experience with the pharmacy services. Medications were always available on time.',
                                                      },
                                                      {
                                                        'name': 'Patricia Garcia',
                                                        'rating': '4.6',
                                                        'date': '1 month ago',
                                                        'comment': 'The specialized treatments here are world-class. Very professional staff.',
                                                      },
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                            child: const Text(
                                              'View More',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
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
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Container(
                                    height: 120,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      image: const DecorationImage(
                                        image: AssetImage('assets/hospital.PNG'),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.1),
                                          spreadRadius: 1,
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        const Text(
                                          'Medical Center',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF159BBD),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'X-Ray • MRI • CT Scan • Ultrasound • Blood Bank',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.location_on,
                                              size: 10,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 2),
                                            const Text(
                                              '789 Health Boulevard',
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF159BBD),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => HospitalDetailsPage(
                                                    hospitalName: 'Medical Center',
                                                    hospitalImage: 'assets/hospital.PNG',
                                                    address: '789 Health Boulevard, Medical District',
                                                    facilities: ['General Medicine', 'Pediatrics', 'Gynecology', 'Dermatology'],
                                                    rating: 4.7,
                                                    reviewCount: 156,
                                                    reviews: [
                                                      {
                                                        'name': 'James Wilson',
                                                        'rating': '4.7',
                                                        'date': '2 days ago',
                                                        'comment': 'Excellent medical center with a wide range of services. The staff is very professional.',
                                                      },
                                                      {
                                                        'name': 'Emma Thompson',
                                                        'rating': '4.8',
                                                        'date': '1 week ago',
                                                        'comment': 'Great pediatric care. The doctors are very patient with children.',
                                                      },
                                                      {
                                                        'name': 'Daniel Lee',
                                                        'rating': '4.6',
                                                        'date': '2 weeks ago',
                                                        'comment': 'The gynecology department is excellent. Very caring and professional staff.',
                                                      },
                                                      {
                                                        'name': 'Sophia Chen',
                                                        'rating': '4.9',
                                                        'date': '3 weeks ago',
                                                        'comment': 'The dermatology services are top-notch. Very satisfied with the treatment.',
                                                      },
                                                      {
                                                        'name': 'William Brown',
                                                        'rating': '4.5',
                                                        'date': '1 month ago',
                                                        'comment': 'Good general medicine services. The doctors take time to listen to patients.',
                                                      },
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                            child: const Text(
                                              'View More',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                children: [
                                  Container(
                                    height: 120,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      image: const DecorationImage(
                                        image: AssetImage('assets/hospital2.PNG'),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.1),
                                          spreadRadius: 1,
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        const Text(
                                          'Health Clinic',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF159BBD),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Physiotherapy • Occupational • Speech • Sports • Rehab',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.location_on,
                                              size: 10,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 2),
                                            const Text(
                                              '321 Wellness Street',
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF159BBD),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => HospitalDetailsPage(
                                                    hospitalName: 'Health Clinic',
                                                    hospitalImage: 'assets/hospital2.PNG',
                                                    address: '321 Wellness Street, Health District',
                                                    facilities: ['Family Medicine', 'Dental Care', 'Optometry', 'Physical Therapy'],
                                                    rating: 4.6,
                                                    reviewCount: 142,
                                                    reviews: [
                                                      {
                                                        'name': 'Olivia Martinez',
                                                        'rating': '4.6',
                                                        'date': '3 days ago',
                                                        'comment': 'Great family medicine services. The doctors are very thorough.',
                                                      },
                                                      {
                                                        'name': 'Ethan Johnson',
                                                        'rating': '4.7',
                                                        'date': '1 week ago',
                                                        'comment': 'Excellent dental care. The staff is very gentle and professional.',
                                                      },
                                                      {
                                                        'name': 'Ava Davis',
                                                        'rating': '4.5',
                                                        'date': '2 weeks ago',
                                                        'comment': 'The optometry services are very good. Very accurate prescriptions.',
                                                      },
                                                      {
                                                        'name': 'Noah Wilson',
                                                        'rating': '4.8',
                                                        'date': '3 weeks ago',
                                                        'comment': 'Great physical therapy program. The therapists are very knowledgeable.',
                                                      },
                                                      {
                                                        'name': 'Isabella Taylor',
                                                        'rating': '4.4',
                                                        'date': '1 month ago',
                                                        'comment': 'Good overall experience. The clinic is well-organized and clean.',
                                                      },
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                            child: const Text(
                                              'View More',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
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
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Container(
                                    height: 120,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      image: const DecorationImage(
                                        image: AssetImage('assets/hospital.PNG'),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.1),
                                          spreadRadius: 1,
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        const Text(
                                          'Community Hospital',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF159BBD),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Maternity • Pediatrics • Vaccination • Family • Women',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.location_on,
                                              size: 10,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 2),
                                            const Text(
                                              '654 Community Drive',
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF159BBD),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => HospitalDetailsPage(
                                                    hospitalName: 'Community Hospital',
                                                    hospitalImage: 'assets/hospital.PNG',
                                                    address: '654 Community Drive, Health Village',
                                                    facilities: ['Emergency Care', 'General Surgery', 'Maternity', 'Geriatrics'],
                                                    rating: 4.4,
                                                    reviewCount: 98,
                                                    reviews: [
                                                      {
                                                        'name': 'Lucas Anderson',
                                                        'rating': '4.4',
                                                        'date': '2 days ago',
                                                        'comment': 'Good emergency care services. Quick response and professional staff.',
                                                      },
                                                      {
                                                        'name': 'Mia Thompson',
                                                        'rating': '4.5',
                                                        'date': '1 week ago',
                                                        'comment': 'Excellent maternity care. The staff is very supportive.',
                                                      },
                                                      {
                                                        'name': 'Benjamin White',
                                                        'rating': '4.3',
                                                        'date': '2 weeks ago',
                                                        'comment': 'The general surgery department is very good. Professional surgeons.',
                                                      },
                                                      {
                                                        'name': 'Charlotte Lee',
                                                        'rating': '4.6',
                                                        'date': '3 weeks ago',
                                                        'comment': 'Great geriatric care. The staff is very patient and caring.',
                                                      },
                                                      {
                                                        'name': 'Henry Garcia',
                                                        'rating': '4.2',
                                                        'date': '1 month ago',
                                                        'comment': 'Good community hospital. Accessible and affordable care.',
                                                      },
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                            child: const Text(
                                              'View More',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                children: [
                                  Container(
                                    height: 120,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      image: const DecorationImage(
                                        image: AssetImage('assets/hospital2.PNG'),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.1),
                                          spreadRadius: 1,
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        const Text(
                                          'Urgent Care',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF159BBD),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Trauma • First Aid • Minor Surgery • Wound • Burn',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.location_on,
                                              size: 10,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 2),
                                            const Text(
                                              '987 Emergency Lane',
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF159BBD),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => HospitalDetailsPage(
                                                    hospitalName: 'Urgent Care',
                                                    hospitalImage: 'assets/hospital2.PNG',
                                                    address: '987 Emergency Lane, Medical Plaza',
                                                    facilities: ['24/7 Emergency', 'Minor Surgery', 'X-Ray', 'Laboratory'],
                                                    rating: 4.3,
                                                    reviewCount: 87,
                                                    reviews: [
                                                      {
                                                        'name': 'Amelia Clark',
                                                        'rating': '4.3',
                                                        'date': '1 day ago',
                                                        'comment': 'Quick service for urgent care. The staff is efficient.',
                                                      },
                                                      {
                                                        'name': 'Sebastian Wright',
                                                        'rating': '4.4',
                                                        'date': '3 days ago',
                                                        'comment': 'Good minor surgery services. Clean and well-equipped facility.',
                                                      },
                                                      {
                                                        'name': 'Victoria Hall',
                                                        'rating': '4.2',
                                                        'date': '1 week ago',
                                                        'comment': 'Efficient X-ray services. Quick results and professional staff.',
                                                      },
                                                      {
                                                        'name': 'Jack Robinson',
                                                        'rating': '4.5',
                                                        'date': '2 weeks ago',
                                                        'comment': 'Excellent laboratory services. Accurate and quick results.',
                                                      },
                                                      {
                                                        'name': 'Grace Lewis',
                                                        'rating': '4.1',
                                                        'date': '3 weeks ago',
                                                        'comment': 'Good emergency care. The staff handles urgent cases well.',
                                                      },
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                            child: const Text(
                                              'View More',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
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
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Container(
                                    height: 120,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      image: const DecorationImage(
                                        image: AssetImage('assets/hospital.PNG'),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.1),
                                          spreadRadius: 1,
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        const Text(
                                          'Children Hospital',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF159BBD),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Pediatric • Neonatal • Child Development • Vaccination',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.location_on,
                                              size: 10,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 2),
                                            const Text(
                                              '147 Kids Care Avenue',
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF159BBD),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => HospitalDetailsPage(
                                                    hospitalName: 'Children Hospital',
                                                    hospitalImage: 'assets/hospital.PNG',
                                                    address: '147 Kids Care Avenue, Pediatric District',
                                                    facilities: ['Pediatric Care', 'Child Surgery', 'Vaccination', 'Child Psychology'],
                                                    rating: 4.9,
                                                    reviewCount: 203,
                                                    reviews: [
                                                      {
                                                        'name': 'Lily Parker',
                                                        'rating': '4.9',
                                                        'date': '2 days ago',
                                                        'comment': 'Excellent pediatric care. The doctors are amazing with children.',
                                                      },
                                                      {
                                                        'name': 'Oliver Scott',
                                                        'rating': '5.0',
                                                        'date': '1 week ago',
                                                        'comment': 'The child surgery department is outstanding. Very skilled surgeons.',
                                                      },
                                                      {
                                                        'name': 'Chloe Green',
                                                        'rating': '4.8',
                                                        'date': '2 weeks ago',
                                                        'comment': 'Great vaccination services. The staff makes children feel comfortable.',
                                                      },
                                                      {
                                                        'name': 'Leo Turner',
                                                        'rating': '4.9',
                                                        'date': '3 weeks ago',
                                                        'comment': 'Excellent child psychology services. Very understanding therapists.',
                                                      },
                                                      {
                                                        'name': 'Zoe Phillips',
                                                        'rating': '4.7',
                                                        'date': '1 month ago',
                                                        'comment': 'Wonderful children hospital. The environment is very child-friendly.',
                                                      },
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                            child: const Text(
                                              'View More',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                children: [
                                  Container(
                                    height: 120,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      image: const DecorationImage(
                                        image: AssetImage('assets/hospital2.PNG'),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.1),
                                          spreadRadius: 1,
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        const Text(
                                          'Women Hospital',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF159BBD),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Gynecology • Obstetrics • Fertility • Breast • Women',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.location_on,
                                              size: 10,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 2),
                                            const Text(
                                              '258 Women Health Road',
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF159BBD),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => HospitalDetailsPage(
                                                    hospitalName: 'Women Hospital',
                                                    hospitalImage: 'assets/hospital2.PNG',
                                                    address: '258 Women Health Road, Medical Center',
                                                    facilities: ['Obstetrics', 'Gynecology', 'Breast Care', 'Fertility'],
                                                    rating: 4.8,
                                                    reviewCount: 178,
                                                    reviews: [
                                                      {
                                                        'name': 'Hannah Baker',
                                                        'rating': '4.8',
                                                        'date': '2 days ago',
                                                        'comment': 'Excellent obstetrics care. The staff is very supportive during pregnancy.',
                                                      },
                                                      {
                                                        'name': 'Ryan Cooper',
                                                        'rating': '4.9',
                                                        'date': '1 week ago',
                                                        'comment': 'Great gynecology services. The doctors are very professional.',
                                                      },
                                                      {
                                                        'name': 'Nora Evans',
                                                        'rating': '4.7',
                                                        'date': '2 weeks ago',
                                                        'comment': 'Excellent breast care services. Very thorough and caring staff.',
                                                      },
                                                      {
                                                        'name': 'Caleb Foster',
                                                        'rating': '4.8',
                                                        'date': '3 weeks ago',
                                                        'comment': 'Great fertility services. The doctors are very knowledgeable.',
                                                      },
                                                      {
                                                        'name': 'Ruby Hughes',
                                                        'rating': '4.6',
                                                        'date': '1 month ago',
                                                        'comment': 'Wonderful women hospital. The environment is very comfortable.',
                                                      },
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                            child: const Text(
                                              'View More',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
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
                          ],
                        ),
                      ],
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