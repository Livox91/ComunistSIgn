import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mcprj/presentation/screens/settings_page.dart';
import 'package:mcprj/presentation/screens/under_construction.dart';
import 'package:mcprj/presentation/themes/text_styles.dart';

Widget buildFeatureCard(
  BuildContext context, {
  required String title,
  required String description,
  required IconData icon,
  required Color color,
  required Widget destination,
}) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => destination),
      );
    },
    child: Container(
      width: 240,
      margin: const EdgeInsets.only(right: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF0077B6),
            child: Icon(icon, color: color, size: 28),
          ),
          BlackMontserratf18wBold(text: title),
          BlackRobotof13(text: description),
        ],
      ),
    ),
  );
}

Widget buildUpcomingFeatureCard(
  BuildContext context, {
  required String title,
  required String description,
  required IconData icon,
  required Color color,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    child: GestureDetector(
      // Add this
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UnderConstructionPage(
              featureTitle: title,
            ),
          ),
        );
      },
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: const Color(0xFF0077B6),
              size: 40,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BlackMontserratf18wBold(text: title),
                  const SizedBox(height: 5),
                  BlackRobotof13(text: description),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget buildDrawer(BuildContext context) {
  return Drawer(
    child: Container(
      color: const Color(0xFFB2D7F0),
      child: Column(
        children: [
          const SizedBox(height: 50),
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 50, color: Color(0xFF0077B6)),
          ),
          const SizedBox(height: 20),
          const WhiteMontserratf22wBold(text: "userName"),
          const SizedBox(height: 10),
          const Divider(
              color: Colors.white70, thickness: 1, indent: 20, endIndent: 20),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.white),
            title: const Text(
              'Settings',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
          const ListTile(
            leading: Icon(Icons.help, color: Colors.white),
            title: Text('Help',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w500)),
          ),
          const ListTile(
            leading: Icon(Icons.logout, color: Colors.white),
            title: Text('Logout',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    ),
  );
}

Widget buildControlButton({
  required VoidCallback? onPressed,
  required IconData icon,
  required String label,
  required Color color,
}) {
  return ElevatedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon),
    label: Text(
      label,
      style: GoogleFonts.montserrat(
        fontWeight: FontWeight.bold,
      ),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: onPressed == null ? Colors.grey : color,
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  );
}
