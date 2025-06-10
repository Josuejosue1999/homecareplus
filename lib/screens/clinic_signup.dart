import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ClinicSignupPage extends StatefulWidget {
  const ClinicSignupPage({super.key});

  @override
  State<ClinicSignupPage> createState() => _ClinicSignupPageState();
}

class _ClinicSignupPageState extends State<ClinicSignupPage> {
  final _formKey = GlobalKey<FormState>();
  File? _clinicImage;

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _clinicImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF159BBD),
        elevation: 0,
        title: const Text('Clinic Registration'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFF159BBD).withOpacity(0.2),
                  backgroundImage:
                      _clinicImage != null ? FileImage(_clinicImage!) : null,
                  child: _clinicImage == null
                      ? const Icon(Icons.add_a_photo, size: 30, color: Color(0xFF159BBD))
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField(label: 'Clinic Name'),
              _buildTextField(label: 'Email'),
              _buildTextField(label: 'Phone Number'),
              _buildTextField(label: 'Address'),
              _buildTextField(label: 'Password', obscure: true),
              _buildTextField(label: 'About', maxLines: 4),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Future action: Send data to Firebase or backend
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Clinic registered")),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF159BBD),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    bool obscure = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        obscureText: obscure,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF159BBD)),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }
}
