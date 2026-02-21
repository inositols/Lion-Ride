import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingActionButton extends StatelessWidget {
  final bool isLastPage;
  final VoidCallback onTap;

  const OnboardingActionButton({
    super.key,
    required this.isLastPage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 64,
        width: isLastPage ? 160 : 64,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(51),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: isLastPage
              ? Text(
                  'GET STARTED',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF004D40),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
                )
              : const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFF004D40),
                  size: 20,
                ),
        ),
      ),
    );
  }
}
