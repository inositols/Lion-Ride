import 'package:flutter/material.dart';

class OnboardingData {
  final String title;
  final String subtitle;
  final String description;
  final String lottieUrl;
  final String bgImageUrl;
  final Color color;

  const OnboardingData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.lottieUrl,
    required this.bgImageUrl,
    required this.color,
  });
}
