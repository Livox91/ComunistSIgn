import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isDarkMode = false;
  String signLanguage = 'ASL';
  String textLanguage = 'English';

  // List of supported languages
  final List<String> signLanguages = ['ASL', 'PSL', 'BSL'];
  final List<String> textLanguages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Chinese',
    'Hindi'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(color: isDarkMode ? Colors.pinkAccent : Colors.black),
        ),
        backgroundColor: isDarkMode ? Colors.black : Colors.pinkAccent,
        iconTheme: IconThemeData(color: isDarkMode ? Colors.pinkAccent : Colors.white),
      ),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          // Sign Language Selection
          _buildDropdownTile(
            title: 'Sign Language',
            value: signLanguage,
            options: signLanguages,
            onChanged: (value) {
              setState(() {
                signLanguage = value!;
              });
            },
          ),

          // Translated Text Language Selection
          _buildDropdownTile(
            title: 'Translated Text Language',
            value: textLanguage,
            options: textLanguages,
            onChanged: (value) {
              setState(() {
                textLanguage = value!;
              });
            },
          ),

          // Dark Mode Toggle
          SwitchListTile(
            title: Text(
              'Dark Mode',
              style: TextStyle(
                color: isDarkMode ? Colors.pinkAccent : Colors.black,
                fontSize: 18,
              ),
            ),
            activeColor: Colors.pinkAccent,
            value: isDarkMode,
            onChanged: (value) {
              setState(() {
                isDarkMode = value;
              });
            },
          ),

          // Report Bug Button
          ListTile(
            leading: Icon(Icons.bug_report, color: isDarkMode ? Colors.pinkAccent : Colors.black),
            title: Text(
              'Report a Bug',
              style: TextStyle(
                color: isDarkMode ? Colors.pinkAccent : Colors.black,
                fontSize: 18,
              ),
            ),
            onTap: () {
              _showBugReportDialog();
            },
          ),
        ],
      ),
    );
  }

  // Dropdown Tile
  Widget _buildDropdownTile({
    required String title,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: isDarkMode ? Colors.pinkAccent : Colors.black,
          fontSize: 18,
        ),
      ),
      trailing: DropdownButton<String>(
        value: value,
        dropdownColor: isDarkMode ? Colors.black : Colors.white,
        items: options.map((String option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(
              option,
              style: TextStyle(
                color: isDarkMode ? Colors.pinkAccent : Colors.black,
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  // Bug Report Dialog
  void _showBugReportDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          title: Text(
            'Report a Bug',
            style: TextStyle(
              color: isDarkMode ? Colors.pinkAccent : Colors.black,
            ),
          ),
          content: Text(
            'Please describe the bug and send it to our team!',
            style: TextStyle(
              color: isDarkMode ? Colors.pinkAccent : Colors.black,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Close', style: TextStyle(color: Colors.pinkAccent)),
            ),
          ],
        );
      },
    );
  }
}
