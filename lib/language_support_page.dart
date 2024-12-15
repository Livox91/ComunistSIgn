import 'package:flutter/material.dart';

class LanguageSupportPage extends StatefulWidget {
  @override
  _LanguageSupportPageState createState() => _LanguageSupportPageState();
}

class _LanguageSupportPageState extends State<LanguageSupportPage> {
  String _selectedLanguage = 'ASL'; // Default selected language

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Stack(
            children: [
              Container(
                height: 200,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.pink, Colors.pinkAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
              ),
              Positioned(
                top: 80,
                left: 20,
                child: Row(
                  children: const [
                    Icon(Icons.language, size: 40, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      'Language Support',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          // Instructions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: const Text(
              'Choose your preferred language:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Language Options with Radio Buttons
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildRadioOption('ASL', 'American Sign Language'),
                _buildRadioOption('BSL', 'British Sign Language'),
                _buildRadioOption('PSL', 'Pakistani Sign Language'),
                _buildRadioOption('Custom', 'Custom Language Pack'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Save Button
          Center(
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Your preferred language ($_selectedLanguage) has been saved!',
                    ),
                    backgroundColor: Colors.pink,
                  ),
                );
                Navigator.pop(context); // Navigate back to dashboard
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Method to Build Radio Button Options
  Widget _buildRadioOption(String value, String title) {
    return Card(
      color: Colors.pink[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            Radio<String>(
              value: value,
              groupValue: _selectedLanguage,
              activeColor: Colors.pink,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedLanguage = newValue!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
