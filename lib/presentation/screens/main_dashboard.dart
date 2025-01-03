import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mcprj/data/shared_preference.dart';
import 'package:mcprj/domain/user_model.dart';
import 'package:mcprj/presentation/blocs/auth_bloc/user_auth_bloc.dart';
import 'package:mcprj/presentation/blocs/theme_bloc/theme_cubit.dart';
import 'package:mcprj/presentation/screens/settings_page.dart';
import 'package:mcprj/presentation/themes/text_styles.dart';
import 'translate_sign_to_text.dart';
import 'emotion_detection.dart';
import 'search_page.dart';
import 'user_account.dart';
import '../../text_to_sign.dart';
import 'package:mcprj/presentation/builders/build_feature_cards.dart';

// Header Section Widget
class HeaderSection extends StatelessWidget {
  final UserProfile? user;
  const HeaderSection({super.key, UserProfile? this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GreyMontserratw500f22(text: 'Hello again,'),
          const SizedBox(height: 5),
          BlackMontserratf28wBold(text: user?.name),
          const SizedBox(height: 5),
          const BlueMontserratf36wBold(text: 'CommuniSign'),
        ],
      ),
    );
  }
}

// Horizontal Scrollable Feature Cards
class HorizontalFeatureCards extends StatelessWidget {
  const HorizontalFeatureCards({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20),
        children: [
          buildFeatureCard(
            context,
            title: 'Translation',
            description: 'Translate signs to text or speech.',
            icon: Icons.g_translate,
            color: Color(0xFFB2D7F0),
            destination: TranslateSignToTextScreen(),
          ),
          buildFeatureCard(
            context,
            title: 'Text to Sign',
            description: 'Convert text into sign animations.',
            icon: Icons.text_fields,
            color: Color(0xFFB2D7F0),
            destination: TextToSignScreen(),
          ),
          buildFeatureCard(
            context,
            title: 'Emotion Detection',
            description: 'Identify sign emotions.',
            icon: Icons.face,
            color: Color(0xFFB2D7F0),
            destination: EmotionDetectionScreen(),
          ),
        ],
      ),
    );
  }
}

// Dashboard Content
class DashboardContent extends StatefulWidget {
  final UserProfile? user;

  const DashboardContent({super.key, UserProfile? this.user});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeaderSection(user: widget.user),
          const SizedBox(height: 20),
          const HorizontalFeatureCards(),
          const SizedBox(height: 30),

          // Upcoming Features Section
          const Padding(
            padding: EdgeInsets.only(left: 20),
            child: BlackMontserratf20wBold(text: 'Upcoming Features'),
          ),
          const SizedBox(height: 15),

          buildUpcomingFeatureCard(
            context,
            title: 'Learn Sign Language',
            description: 'Master ASL with step-by-step lessons.',
            icon: Icons.school,
            color: const Color(0xFFB2D7F0),
          ),
          buildUpcomingFeatureCard(
            context,
            title: 'Sign Language Games',
            description: 'Fun games to reinforce learning.',
            icon: Icons.videogame_asset,
            color: const Color(0xFFB2D7F0),
          ),
          buildUpcomingFeatureCard(
            context,
            title: 'Community Forum',
            description: 'Engage with others learning sign language.',
            icon: Icons.forum,
            color: const Color(0xFFB2D7F0),
          ),
          buildUpcomingFeatureCard(
            context,
            title: 'Sign Challenges',
            description: 'Take part in daily signing challenges.',
            icon: Icons.emoji_events,
            color: const Color(0xFFB2D7F0),
          ),
        ],
      ),
    );
  }
}

class MainDashboard extends StatefulWidget {
  @override
  _MainDashboardState createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  final SharedPref sharedPref = SharedPref();
  late UserProfile? user = UserProfile(name: "");
  Color? colortheme;
  @override
  void initState() {
    setuserProfile();

    super.initState();
  }

  void setuserProfile() async {
    user = await sharedPref.getUser();
  }

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // final themeCubit = context.read<ThemeCubit>();
    return Scaffold(
      endDrawer: buildDrawer(context),
      appBar: _selectedIndex == 0
          ? AppBar(
              elevation: 0,
              iconTheme: const IconThemeData(color: Color(0xFF0077B6)),
            )
          : null,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          DashboardContent(user: user),
          SearchPage(),
          UserAccountPage(userProfile: user),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
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
          elevation: 0,
          selectedItemColor: const Color(0xFF0077B6),
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
            WhiteMontserratf22wBold(text: user?.name),
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
            ListTile(
              leading: Icon(Icons.help, color: Colors.white),
              title: Text('Help',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w500)),
              onTap: () {
                _buildMenuItem(
                  'Help & Support',
                  Icons.help_outline,
                  onTap: () {
                    // Handle help & support
                  },
                );
              },
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

  // Drawer Widget
}
