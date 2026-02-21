import 'package:flutter/material.dart';
import '../models/onboarding_model.dart';

class OnboardingBackground extends StatelessWidget {
  final OnboardingData data;

  const OnboardingBackground({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          data.bgImageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              Container(color: data.color),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withAlpha(51),
                data.color.withAlpha(204),
                data.color,
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}
