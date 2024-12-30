import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'settings_page.dart';
import 'translate_sign_to_text.dart';
import 'emotion_detection.dart';
import 'search_page.dart';
import 'user_account.dart';
import 'text_to_sign.dart';
import 'under_construction .dart';

class MainDashboard extends StatefulWidget {
  @override
  _MainDashboardState createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  final String userName = 'Alex Johnson';
  int _selectedIndex = 0;

  // Main content of the dashboard
  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello again,',
                  style: GoogleFonts.montserrat(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  userName,
                  style: GoogleFonts.montserrat(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'CommuniSign',
                  style: GoogleFonts.montserrat(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0077B6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Horizontally Scrollable Feature Cards
          SizedBox(
            height: 260,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 20),
              children: [
                _buildFeatureCard(
                  context,
                  title: 'Translation',
                  description: 'Translate signs to text or speech.',
                  icon: Icons.g_translate,
                  color: Color(0xFFB2D7F0),
                  destination: TranslateSignToTextScreen(),
                ),
                _buildFeatureCard(
                  context,
                  title: 'Text to Sign',
                  description: 'Convert text into sign animations.',
                  icon: Icons.text_fields,
                  color: Color(0xFFB2D7F0),
                  destination: TextToSignScreen(),
                ),
                _buildFeatureCard(
                  context,
                  title: 'Emotion Detection',
                  description: 'Identify sign emotions.',
                  icon: Icons.face,
                  color: Color(0xFFB2D7F0),
                  destination: EmotionDetectionScreen(),
                ),
              ],
            ),
          ),
          SizedBox(height: 30),

          // Upcoming Features Section
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              'Upcoming Features',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          SizedBox(height: 15),

          _buildUpcomingFeatureCard(
            title: 'Learn Sign Language',
            description: 'Master ASL with step-by-step lessons.',
            icon: Icons.school,
            color: Color(0xFFB2D7F0),
          ),
          _buildUpcomingFeatureCard(
            title: 'Sign Language Games',
            description: 'Fun games to reinforce learning.',
            icon: Icons.videogame_asset,
            color: Color(0xFFB2D7F0),
          ),
          _buildUpcomingFeatureCard(
            title: 'Community Forum',
            description: 'Engage with others learning sign language.',
            icon: Icons.forum,
            color: Color(0xFFB2D7F0),
          ),
          _buildUpcomingFeatureCard(
            title: 'Sign Challenges',
            description: 'Take part in daily signing challenges.',
            icon: Icons.emoji_events,
            color: Color(0xFFB2D7F0),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      endDrawer: _buildDrawer(context),
      appBar: _selectedIndex == 0 ? AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF0077B6)),
      ) : null,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboardContent(),
          SearchPage(),
          UserAccountPage(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          backgroundColor: Color(0xFFFFFFFF),
          elevation: 0,
          selectedItemColor: Color(0xFF0077B6),
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.w500,
          ),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled, size: 28),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search, size: 28),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 28),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  // Feature Card Widget
  Widget _buildFeatureCard(
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
              backgroundColor: Color(0xFF0077B6),
              child: Icon(icon, color: color, size: 28),
            ),
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF000000),
              ),
            ),
            Text(
              description,
              style: GoogleFonts.roboto(
                fontSize: 13,
                color: Color(0xFF000000),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Drawer Widget
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        color: Color(0xFFB2D7F0),
        child: Column(
          children: [
            SizedBox(height: 50),
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 50, color: Color(0xFF0077B6)),
            ),
            SizedBox(height: 20),
            Text(
              userName,
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Divider(color: Colors.white70, thickness: 1, indent: 20, endIndent: 20),
            ListTile(
              leading: Icon(Icons.settings, color: Colors.white),
              title: Text(
                'Settings',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.help, color: Colors.white),
              title: Text('Help',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.white),
              title: Text('Logout',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }

  // Upcoming Features Card
  Widget _buildUpcomingFeatureCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: GestureDetector(  // Add this
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
            Icon(icon, color: Color(0xFF0077B6), size: 40),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF000000),
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    description,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Color(0xFF000000),
                    ),
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