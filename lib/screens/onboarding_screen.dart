import 'package:flutter/material.dart';
import 'package:remote_mouse/models/onboarding_page_model.dart';
import 'package:remote_mouse/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPageModel> _pages = [
    OnboardingPageModel(
      title: 'Welcome to Remote Mouse',
      description:
          'Transform your phone into a wireless mouse for your computer',
      icon: Icons.mouse_rounded,
      features: [
        'Control your PC from anywhere',
        'No additional hardware needed',
        'Secure local network connection',
      ],
    ),
    OnboardingPageModel(
      title: 'Motion Control',
      description:
          'Use gyroscope-based motion tracking for precise cursor control',
      icon: Icons.rotate_90_degrees_ccw_rounded,
      features: [
        'Pan left/right to move horizontally',
        'Tilt forward/back to move vertically',
        'Smooth and responsive tracking',
      ],
    ),
    OnboardingPageModel(
      title: 'Full Mouse Features',
      description: 'Complete mouse functionality right at your fingertips',
      icon: Icons.touch_app_rounded,
      features: [
        'Left and right click buttons',
        'Vertical and horizontal scrolling',
        'Customizable sensitivity settings',
      ],
    ),
    OnboardingPageModel(
      title: 'Easy Setup',
      description: 'Get started in just a few simple steps',
      icon: Icons.qr_code_scanner_rounded,
      features: [
        'Install desktop app on your PC',
        'Scan QR code to connect',
        'Start controlling immediately',
      ],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton.icon(
                      onPressed: _previousPage,
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('Back'),
                    )
                  else
                    const SizedBox(width: 100),
                  if (_currentPage < _pages.length - 1)
                    TextButton(
                      onPressed: _completeOnboarding,
                      child: const Text('Skip'),
                    )
                  else
                    const SizedBox(width: 80),
                ],
              ),
            ),

            // Page View - Takes remaining space
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _OnboardingPage(
                    page: _pages[index],
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  );
                },
              ),
            ),

            // Page Indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 32 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // Next/Get Started Button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: FilledButton(
                onPressed: _nextPage,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentPage == _pages.length - 1
                          ? 'Get Started'
                          : 'Next',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _currentPage == _pages.length - 1
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                      color: colorScheme.onPrimary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final OnboardingPageModel page;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _OnboardingPage({
    required this.page,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    // Get screen height to calculate responsive sizing
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: isSmallScreen ? 8 : 16,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Add some top spacing
          SizedBox(height: isSmallScreen ? 16 : 24),

          // Icon Container - Responsive size
          Container(
            width: isSmallScreen ? 140 : 180,
            height: isSmallScreen ? 140 : 180,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                page.icon,
                size: isSmallScreen ? 70 : 90,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),

          SizedBox(height: isSmallScreen ? 24 : 40),

          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: (isSmallScreen
                    ? textTheme.headlineSmall
                    : textTheme.headlineMedium)
                ?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),

          SizedBox(height: isSmallScreen ? 12 : 16),

          // Description
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),

          SizedBox(height: isSmallScreen ? 24 : 32),

          // Features
          ...page.features.map(
            (feature) => Padding(
              padding: EdgeInsets.symmetric(
                vertical: isSmallScreen ? 6 : 8,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 20,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        feature,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom spacing
          SizedBox(height: isSmallScreen ? 16 : 24),
        ],
      ),
    );
  }
}