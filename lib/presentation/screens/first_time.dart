import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:mcprj/data/shared_preference.dart';
import 'package:mcprj/domain/user_model.dart';
import 'package:mcprj/presentation/blocs/first_time_bloc/first_time_bloc.dart';

class OnboardingFlow extends StatefulWidget {
  final String? welcomeAnimation;
  final String? nameAnimation;
  final String? themeAnimation;

  const OnboardingFlow({
    Key? key,
    this.welcomeAnimation = 'assets/welcome.json',
    this.nameAnimation = 'assets/name.json',
    this.themeAnimation = 'assets/theme.json',
  }) : super(key: key);

  @override
  _OnboardingFlowState createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final SharedPref sharedPref = SharedPref();
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final UserProfile user = UserProfile();
  bool _isDarkMode = false;
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x106C63FF),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x106C63FF),
              ),
            ),
          ),
          PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            children: [
              _buildWelcomeScreen(),
              _buildNameScreen(),
              _buildThemeScreen(),
            ],
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) => _buildDotIndicator(index)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Stack(
      children: [
        Center(
          child: Lottie.asset(
            widget.welcomeAnimation!,
            width: 300,
            height: 300,
          ),
        ),
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Text(
            "Swipe to get started",
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNameScreen() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            widget.nameAnimation!,
            width: 250,
            height: 250,
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'What should we call you?',
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0077B6),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Enter your name',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF0077B6),
                        width: 2,
                      ),
                    ),
                  ),
                  style: GoogleFonts.montserrat(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeScreen() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Text(
            'Choose Your Theme',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0077B6),
            ),
          ),
          Text(
            'Personalize your experience',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 40),
          Lottie.asset(
            widget.themeAnimation!,
            width: 200,
            height: 200,
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0077B6).withOpacity(0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildThemeOption(false),
                    _buildThemeOption(true),
                  ],
                ),
                const SizedBox(height: 40),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      onComplete(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0077B6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 20,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Continue',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(bool isDark) {
    final bool isSelected = _isDarkMode == isDark;
    return GestureDetector(
      onTap: () => setState(() => _isDarkMode = isDark),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(24),
        width: 140,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0077B6).withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0077B6) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0077B6) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? const Color(0xFF0077B6).withOpacity(0.3)
                        : Colors.grey.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                isDark ? Icons.dark_mode : Icons.light_mode,
                size: 32,
                color: isSelected ? Colors.white : const Color(0xFF0077B6),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isDark ? 'Dark Mode' : 'Light Mode',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: isSelected ? const Color(0xFF0077B6) : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isDark ? 'Easy on the eyes' : 'Classic look',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDotIndicator(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color:
            _currentPage == index ? const Color(0xFF0077B6) : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  void onComplete(context) {
    final FirstTimeSetupBloc firstTimeBloc =
        BlocProvider.of<FirstTimeSetupBloc>(context);
    user.name = _nameController.text;
    user.theme = _isDarkMode;
    sharedPref.saveUser(user);
    firstTimeBloc.add(SetupEvent.completeSetup);
  }
}
