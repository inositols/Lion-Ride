import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RoleSelectorButton extends StatelessWidget {
  final String role;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onSelect;

  const RoleSelectorButton({
    super.key,
    required this.role,
    required this.icon,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withAlpha(25), // 0.1 * 255
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withAlpha(51), // 0.2 * 255
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF004D40) : Colors.white,
            ),
            const SizedBox(height: 4),
            Text(
              role.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF004D40) : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
