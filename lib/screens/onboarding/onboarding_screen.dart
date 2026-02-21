import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/onboarding_model.dart';
import 'widgets/onboarding_background.dart';
import 'widgets/onboarding_page.dart';
import 'widgets/onboarding_step_indicator.dart';
import 'widgets/onboarding_action_button.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;

  const OnboardingScreen({super.key, required this.onFinish});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _fadeController;

  final List<OnboardingData> _pages = const [
    OnboardingData(
      title: 'Premium\nCampus Rides',
      subtitle: 'RELIABILITY',
      description:
          'Experience the safest and most reliable transportation within UNN. Verified student riders at your service.',
      lottieUrl: 'https://lottie.host/85934149-6f19-4820-9609-84707693cd65/P8JvXWpD2m.json',
      bgImageUrl: 'https://images.unsplash.com/photo-1541339907198-e08756ebafe3?q=80&w=2070&auto=format&fit=crop',
      color: Color(0xFF004D40),
    ),
    OnboardingData(
      title: 'Seamless\nPayments',
      subtitle: 'CONVENIENCE',
      description:
          'Fast, secure, and cashless. Fund your wallet with Paystack and pay for rides with just a tap.',
      lottieUrl: 'https://lottie.host/649e7512-5b9c-486d-92a0-4ff6603a1104/N7Qe1E6kLz.json',
      bgImageUrl: 'https://images.unsplash.com/photo-1556742044-3c52d6e88c62?q=80&w=2070&auto=format&fit=crop',
      color: Color(0xFF00695C),
    ),
    OnboardingData(
      title: 'Safety\nFirst',
      subtitle: 'PROTECTION',
      description:
          'Share your live location with friends and family. Your safety is our top priority during every journey.',
      lottieUrl: 'https://lottie.host/f460ce01-f513-4852-872f-5060b86b4f73/8SUnxR7T8J.json',
      bgImageUrl: 'https://images.unsplash.com/photo-1449965408869-eaa3f722e40d?q=80&w=2070&auto=format&fit=crop',
      color: Color(0xFF00897B),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(seconds: 1),
              transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
              child: OnboardingBackground(
                key: ValueKey<int>(_currentPage),
                data: _pages[_currentPage],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'LION RIDE',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      TextButton(
                        onPressed: widget.onFinish,
                        child: Text(
                          'SKIP',
                          style: GoogleFonts.inter(
                            color: Colors.white.withAlpha(179),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                      _fadeController.reset();
                      _fadeController.forward();
                    },
                    itemBuilder: (context, index) {
                      return OnboardingPage(
                        data: _pages[index],
                        fadeAnimation: _fadeController,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OnboardingStepIndicator(
                        count: _pages.length,
                        currentIndex: _currentPage,
                      ),
                      OnboardingActionButton(
                        isLastPage: _currentPage == _pages.length - 1,
                        onTap: () {
                          if (_currentPage == _pages.length - 1) {
                            widget.onFinish();
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeInOutExpo,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
