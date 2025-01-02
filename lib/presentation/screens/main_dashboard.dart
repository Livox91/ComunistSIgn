import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mcprj/data/shared_preference.dart';
import 'package:mcprj/domain/user_model.dart';
import 'package:mcprj/presentation/themes/text_styles.dart';
import 'translate_sign_to_text.dart';
import 'emotion_detection.dart';
import 'search_page.dart';
import 'user_account.dart';
import '../../text_to_sign.dart';
import 'package:mcprj/presentation/builders/build_feature_cards.dart';

// Header Section Widget
class HeaderSection extends StatefulWidget {
  HeaderSection({super.key});

  @override
  State<HeaderSection> createState() => _HeaderSectionState();
}

class _HeaderSectionState extends State<HeaderSection> {
  final SharedPref sharedPref = SharedPref();
  late UserProfile? user = UserProfile(name: "");
  @override
  void initState() {
    setuserProfile();
    super.initState();
  }

  void setuserProfile() async {
    user = await sharedPref.getUser();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GreyMontserratw500f22(text: 'Hello again,'),
          const SizedBox(height: 5),
          BlackMontserratf28wBold(text: user?.name ?? ""),
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
class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeaderSection(),
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
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      endDrawer: buildDrawer(context),
      appBar: _selectedIndex == 0
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Color(0xFF0077B6)),
            )
          : null,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const DashboardContent(),
          SearchPage(),
          UserAccountPage(),
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
          backgroundColor: const Color(0xFFFFFFFF),
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

  // Drawer Widget
}
