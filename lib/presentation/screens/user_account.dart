import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mcprj/domain/user_model.dart';
import 'settings_page.dart';

class UserAccountPage extends StatefulWidget {
  @override
  _UserAccountPageState createState() => _UserAccountPageState();
}

class _UserAccountPageState extends State<UserAccountPage> {
  UserProfile userProfile = UserProfile(
    name: 'Alex Johnson',
    email: 'alex.johnson@email.com',
    phoneNumber: '+1 234 567 8900',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 60),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFB2D7F0), Color(0xFF90CAF9)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Color(0xFF0077B6),
                        child:
                            Icon(Icons.person, size: 60, color: Colors.white),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _showEditProfileDialog(),
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Color(0xFF0077B6),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child:
                                Icon(Icons.edit, size: 20, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          userProfile.name,
                          style: GoogleFonts.montserrat(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0077B6),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          userProfile.email,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        if (userProfile.phoneNumber != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              userProfile.phoneNumber!,
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
              child: Column(
                children: [
                  _buildMenuItem(
                    'Edit Profile',
                    Icons.edit,
                    onTap: () => _showEditProfileDialog(),
                  ),
                  SizedBox(height: 16),
                  _buildMenuItem(
                    'Settings',
                    Icons.settings,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SettingsPage()),
                      );
                    },
                  ),
                  SizedBox(height: 16),
                  _buildMenuItem(
                    'Help & Support',
                    Icons.help_outline,
                    onTap: () {
                      // Handle help & support
                    },
                  ),
                  SizedBox(height: 16),
                  _buildMenuItem(
                    'Log Out',
                    Icons.logout,
                    onTap: () {
                      _showLogoutDialog(context);
                    },
                    isDestructive: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    String title,
    IconData icon, {
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive
                ? Colors.red.withOpacity(0.1)
                : Color(0xFFB2D7F0).withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.red : Color(0xFF0077B6),
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDestructive ? Colors.red : Colors.black87,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isDestructive ? Colors.red : Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String name = userProfile.name;
        String email = userProfile.email;
        String phone = userProfile.phoneNumber ?? '';

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Edit Profile',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
              color: Color(0xFF0077B6),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Name',
                    icon: Icon(Icons.person, color: Color(0xFF0077B6)),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF0077B6)),
                    ),
                  ),
                  controller: TextEditingController(text: name),
                  onChanged: (value) => name = value,
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Email',
                    icon: Icon(Icons.email, color: Color(0xFF0077B6)),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF0077B6)),
                    ),
                  ),
                  controller: TextEditingController(text: email),
                  onChanged: (value) => email = value,
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Phone',
                    icon: Icon(Icons.phone, color: Color(0xFF0077B6)),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF0077B6)),
                    ),
                  ),
                  controller: TextEditingController(text: phone),
                  onChanged: (value) => phone = value,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0077B6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('Save'),
              onPressed: () {
                setState(() {
                  userProfile = UserProfile(
                    name: name,
                    email: email,
                    phoneNumber: phone,
                  );
                });
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Logout',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: GoogleFonts.montserrat(),
          ),
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                style: GoogleFonts.montserrat(),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Logout',
                style: GoogleFonts.montserrat(),
              ),
             onPressed: () {
  Navigator.pop(context);
  Navigator.pushNamedAndRemoveUntil(
    context,
    '/',
    (route) => false,
  );
},
            ),
          ],
        );
      },
    );
  }
}
