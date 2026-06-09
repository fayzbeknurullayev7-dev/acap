import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';

class _OnboardPage {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _OnboardPage({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });
}

const _pages = [
  _OnboardPage(
    icon: Icons.smart_toy_rounded,
    iconColor: AppColors.primary,
    title: 'AI Agents at Your Service',
    subtitle:
        '10 specialized AI agents — Planner, Coder, Reviewer, Debugger and more — collaborate to build your project end-to-end.',
  ),
  _OnboardPage(
    icon: Icons.code_rounded,
    iconColor: AppColors.secondary,
    title: 'Full IDE on Mobile',
    subtitle:
        'Syntax highlighting, AI autocomplete, terminal, Git, and one-click deployment — everything you need, right on your phone.',
  ),
  _OnboardPage(
    icon: Icons.rocket_launch_rounded,
    iconColor: AppColors.tertiary,
    title: 'Ship From Anywhere',
    subtitle:
        'Deploy to Railway, Render, or Docker with a single tap. Monitor logs and manage environments on the go.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _current = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_current < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: const Text('Skip'),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _current = i),
                itemCount: _pages.length,
                itemBuilder: (context, i) => _PageContent(page: _pages[i]),
              ),
            ),

            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width:  i == _current ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _current
                        ? AppColors.primary
                        : AppColors.outline,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // CTA Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton(
                onPressed: _next,
                child: Text(
                  _current == _pages.length - 1 ? 'Get Started' : 'Next',
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  final _OnboardPage page;
  const _PageContent({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: page.iconColor.withOpacity(0.3),
              ),
            ),
            child: Icon(page.icon, size: 60, color: page.iconColor),
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(begin: const Offset(0.7, 0.7)),

          const SizedBox(height: 40),

          Text(
            page.title,
            style: AppTypography.headlineMedium,
            textAlign: TextAlign.center,
          )
              .animate(delay: 100.ms)
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.2, end: 0),

          const SizedBox(height: 16),

          Text(
            page.subtitle,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          )
              .animate(delay: 200.ms)
              .fadeIn(duration: 400.ms),
        ],
      ),
    );
  }
}
