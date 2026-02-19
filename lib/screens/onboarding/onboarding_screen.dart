import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

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

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Premium\nCampus Rides',
      subtitle: 'RELIABILITY',
      description:
          'Experience the safest and most reliable transportation within UNN. Verified student riders at your service.',
      lottieUrl: 'https://lottie.host/85934149-6f19-4820-9609-84707693cd65/P8JvXWpD2m.json',
      bgImageUrl: 'https://images.unsplash.com/photo-1541339907198-e08756ebafe3?q=80&w=2070&auto=format&fit=crop',
      color: const Color(0xFF004D40),
    ),
    OnboardingData(
      title: 'Seamless\nPayments',
      subtitle: 'CONVENIENCE',
      description:
          'Fast, secure, and cashless. Fund your wallet with Paystack and pay for rides with just a tap.',
      lottieUrl: 'https://lottie.host/649e7512-5b9c-486d-92a0-4ff6603a1104/N7Qe1E6kLz.json',
      bgImageUrl: 'https://images.unsplash.com/photo-1556742044-3c52d6e88c62?q=80&w=2070&auto=format&fit=crop',
      color: const Color(0xFF00695C),
    ),
    OnboardingData(
      title: 'Safety\nFirst',
      subtitle: 'PROTECTION',
      description:
          'Share your live location with friends and family. Your safety is our top priority during every journey.',
      lottieUrl: 'https://lottie.host/f460ce01-f513-4852-872f-5060b86b4f73/8SUnxR7T8J.json',
      bgImageUrl: 'https://images.unsplash.com/photo-1449965408869-eaa3f722e40d?q=80&w=2070&auto=format&fit=crop',
      color: const Color(0xFF00897B),
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
          // 1. Dynamic Background System
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(seconds: 1),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Container(
                key: ValueKey<int>(_currentPage),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      _pages[_currentPage].bgImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: _pages[_currentPage].color),
                    ),
                    // Intelligent Gradient Overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.2),
                            _pages[_currentPage].color.withValues(alpha: 0.8),
                            _pages[_currentPage].color,
                          ],
                          stops: const [0.0, 0.6, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Content Layer
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header
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
                            color: Colors.white.withValues(alpha: 0.7),
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
                      setState(() {
                        _currentPage = index;
                      });
                      _fadeController.reset();
                      _fadeController.forward();
                    },
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Spacer(flex: 1),
                            // Specialized Subtitle
                            FadeTransition(
                              opacity: _fadeController,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.1),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: _fadeController,
                                  curve: Curves.easeOut,
                                )),
                                child: Text(
                                  _pages[index].subtitle,
                                  style: GoogleFonts.inter(
                                    color: Colors.yellowAccent.withValues(alpha: 0.9),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 4,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Main Title
                            FadeTransition(
                              opacity: _fadeController,
                              child: Text(
                                _pages[index].title,
                                style: GoogleFonts.outfit(
                                  height: 1.1,
                                  fontSize: 48,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const Spacer(flex: 1),
                            // Animated Visual Element
                            Center(
                              child: Container(
                                height: 280,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 40,
                                      offset: const Offset(0, 20),
                                    ),
                                  ],
                                ),
                                child: Lottie.network(
                                  _pages[index].lottieUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const SizedBox.shrink(),
                                ),
                              ),
                            ),
                            const Spacer(flex: 1),
                            // Glass Content Card
                            ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Text(
                                    _pages[index].description,
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      color: Colors.white.withValues(alpha: 0.9),
                                      height: 1.6,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(flex: 2),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // 3. Futuristic Bottom Controls
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Elegant Page Indicator
                      Row(
                        children: List.generate(
                          _pages.length,
                          (index) => Container(
                            margin: const EdgeInsets.only(right: 6),
                            height: 4,
                            width: _currentPage == index ? 32 : 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? Colors.yellowAccent
                                  : Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      
                      // Geometric Action Button
                      GestureDetector(
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
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 64,
                          width: _currentPage == _pages.length - 1 ? 160 : 64,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _currentPage == _pages.length - 1
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

class OnboardingData {
  final String title;
  final String subtitle;
  final String description;
  final String lottieUrl;
  final String bgImageUrl;
  final Color color;

  OnboardingData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.lottieUrl,
    required this.bgImageUrl,
    required this.color,
  });
}
