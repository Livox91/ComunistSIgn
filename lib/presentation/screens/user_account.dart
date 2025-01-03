import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mcprj/data/shared_preference.dart';
import 'package:mcprj/domain/user_model.dart';
import 'package:mcprj/presentation/blocs/auth_bloc/user_auth_bloc.dart';
import 'settings_page.dart';

class UserAccountPage extends StatefulWidget {
  late UserProfile? userProfile;
  UserAccountPage({Key? key, UserProfile? this.userProfile}) : super(key: key);

  @override
  _UserAccountPageState createState() => _UserAccountPageState();
}

class _UserAccountPageState extends State<UserAccountPage> {
  SharedPref sharedpref = SharedPref();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                          widget.userProfile?.name ?? "",
                          style: GoogleFonts.montserrat(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0077B6),
                          ),
                        ),
                        SizedBox(height: 4),
                        // Text(
                        //   userProfile.email,
                        //   style: GoogleFonts.montserrat(
                        //     fontSize: 14,
                        //     color: Colors.black87,
                        //   ),
                        // ),
                        // if (userProfile.phoneNumber != null)
                        //   Padding(
                        //     padding: const EdgeInsets.only(top: 4),
                        //     child: Text(
                        //       userProfile.phoneNumber!,
                        //       style: GoogleFonts.montserrat(
                        //         fontSize: 14,
                        //         color: Colors.black54,
                        //       ),
                        //     ),
                        //   ),
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
                      _showBugReportDialog();
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
        color: Color(0xFFB2D7F0),
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
        String name = widget.userProfile?.name ?? "";

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
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    icon: Icon(Icons.person, color: Color(0xFF0077B6)),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF0077B6)),
                    ),
                  ),
                  controller: TextEditingController(text: name),
                  onChanged: (value) => name = value,
                ),
                const SizedBox(height: 16),
                // TextField(
                //   decoration: InputDecoration(
                //     labelText: 'Email',
                //     icon: Icon(Icons.email, color: Color(0xFF0077B6)),
                //     focusedBorder: UnderlineInputBorder(
                //       borderSide: BorderSide(color: Color(0xFF0077B6)),
                //     ),
                //   ),
                //   controller: TextEditingController(text: email),
                //   onChanged: (value) => email = value,
                // ),
                // SizedBox(height: 16),
                // TextField(
                //   decoration: InputDecoration(
                //     labelText: 'Phone',
                //     icon: Icon(Icons.phone, color: Color(0xFF0077B6)),
                //     focusedBorder: UnderlineInputBorder(
                //       borderSide: BorderSide(color: Color(0xFF0077B6)),
                //     ),
                //   ),
                //   controller: TextEditingController(text: phone),
                //   onChanged: (value) => phone = value,
                // ),
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
                  widget.userProfile = UserProfile(
                    name: name,
                  );
                });
                setUserData();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void setUserData() async {
    await sharedpref.removeUser();
    await sharedpref.saveUser(widget.userProfile!);
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

  void _showLogoutDialog(BuildContext context) {
    final authBloc = BlocProvider.of<UserAuthBloc>(context);
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
                authBloc.add(AuthSignOutRequested());
                sharedpref.removeUser();
                sharedpref.setFirstTimeUsertoTrue();
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/Login',
                  (route) => false,
                );
                print('Logged out');
              },
            ),
          ],
        );
      },
    );
  }
}
