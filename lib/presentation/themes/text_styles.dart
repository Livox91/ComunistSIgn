import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

class GreyMontserratw500f22 extends StatelessWidget {
  final String? text;

  const GreyMontserratw500f22({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text ?? "",
      style: GoogleFonts.montserrat(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade600,
      ),
    );
  }
}

class BlackMontserratf28wBold extends StatelessWidget {
  final String? text;
  const BlackMontserratf28wBold({super.key, this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text ?? "",
      style: GoogleFonts.montserrat(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
}

class BlueMontserratf36wBold extends StatelessWidget {
  final String? text;
  const BlueMontserratf36wBold({super.key, this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text ?? "",
      style: GoogleFonts.montserrat(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF0077B6),
      ),
    );
  }
}

class BlackMontserratf18wBold extends StatelessWidget {
  final String? text;
  const BlackMontserratf18wBold({super.key, this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text ?? "",
      style: GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF000000),
      ),
    );
  }
}

class BlackRobotof13 extends StatelessWidget {
  final String? text;
  const BlackRobotof13({super.key, this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text ?? "",
      style: GoogleFonts.roboto(
        fontSize: 13,
        color: const Color(0xFF000000),
      ),
    );
  }
}

class BlackMontserratf20wBold extends StatelessWidget {
  final String? text;
  const BlackMontserratf20wBold({super.key, this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text ?? "",
      style: GoogleFonts.montserrat(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
}

class WhiteMontserratf22wBold extends StatelessWidget {
  final String? text;
  const WhiteMontserratf22wBold({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text ?? "",
      style: GoogleFonts.montserrat(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}
