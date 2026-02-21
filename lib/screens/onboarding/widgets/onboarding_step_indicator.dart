import 'package:flutter/material.dart';

class OnboardingStepIndicator extends StatelessWidget {
  final int count;
  final int currentIndex;

  const OnboardingStepIndicator({
    super.key,
    required this.count,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        count,
        (index) => Container(
          margin: const EdgeInsets.only(right: 6),
          height: 4,
          width: currentIndex == index ? 32 : 8,
          decoration: BoxDecoration(
            color: currentIndex == index
                ? Colors.yellowAccent
                : Colors.white.withAlpha(77),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
