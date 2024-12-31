import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
      backgroundColor: Color(0xFFFFFFFF),
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0077B6),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF0077B6)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Preferences',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 20),

              // Settings Cards
              _buildSettingsCard(
                title: 'Language Settings',
                children: [
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
                  Divider(color: Colors.grey.shade200),
                  _buildDropdownTile(
                    title: 'Text Language',
                    value: textLanguage,
                    options: textLanguages,
                    onChanged: (value) {
                      setState(() {
                        textLanguage = value!;
                      });
                    },
                  ),
                ],
              ),

              SizedBox(height: 20),

              _buildSettingsCard(
                title: 'App Settings',
                children: [
                  _buildSwitchTile(
                    title: 'Dark Mode',
                    value: isDarkMode,
                    onChanged: (value) {
                      setState(() {
                        isDarkMode = value;
                      });
                    },
                  ),
                ],
              ),

              SizedBox(height: 20),

              _buildSettingsCard(
                title: 'Support',
                children: [
                  _buildActionTile(
                    title: 'Report a Bug',
                    icon: Icons.bug_report,
                    onTap: () => _showBugReportDialog(),
                  ),
                  Divider(color: Colors.grey.shade200),
                  _buildActionTile(
                    title: 'Help Center',
                    icon: Icons.help_outline,
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFB2D7F0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Color(0xFFB2D7F0).withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButton<String>(
              value: value,
              underline: SizedBox(),
              icon: Icon(Icons.arrow_drop_down, color: Color(0xFF0077B6)),
              items: options.map((String option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(
                    option,
                    style: GoogleFonts.roboto(color: Colors.black87),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Color(0xFF0077B6),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            Icon(icon, color: Color(0xFF0077B6)),
            SizedBox(width: 15),
            Text(
              title,
              style: GoogleFonts.roboto(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBugReportDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Report a Bug',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
              color: Color(0xFF0077B6),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Please describe the bug you encountered:',
                style: GoogleFonts.roboto(color: Colors.black87),
              ),
              SizedBox(height: 15),
              TextField(
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Type your description here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Color(0xFF0077B6)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Submit',
                style: TextStyle(color: Color(0xFF0077B6)),
              ),
            ),
          ],
        );
      },
    );
  }
}
