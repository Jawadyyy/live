import 'package:flutter/material.dart';
import 'package:live/screens/auth/auth_ui.dart';

/// Shared, polished onboarding page used by the intro carousel
/// (Match / Connect). Keeps the layout, brand ring and controls in one place.
class OnboardingPage extends StatelessWidget {
  final String image;
  final IconData fallbackIcon;
  final String title;
  final Widget description;
  final int currentPage;
  final int totalPages;
  final String nextLabel;
  final VoidCallback onNext;
  final VoidCallback? onSkip;

  const OnboardingPage({
    super.key,
    required this.image,
    required this.fallbackIcon,
    required this.title,
    required this.description,
    required this.currentPage,
    required this.onNext,
    this.totalPages = 2,
    this.nextLabel = 'Next',
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 375;
    final isLarge = size.width > 600;
    final imageSize = isLarge ? 260.0 : (isSmall ? 190.0 : 230.0);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Soft brand glow anchored to the hero
          Align(
            alignment: const Alignment(0, -0.35),
            child: Container(
              width: size.width * 0.9,
              height: size.width * 0.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [primary.withOpacity(0.16), primary.withOpacity(0)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          isSmall ? 20 : 26,
                          14,
                          isSmall ? 20 : 26,
                          isSmall ? 20 : 28,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _topBar(context, primary),
                            const Spacer(flex: 2),
                            Center(child: _hero(context, primary, imageSize)),
                            const Spacer(flex: 2),
                            _title(theme),
                            SizedBox(height: isSmall ? 12 : 16),
                            description,
                            SizedBox(height: isSmall ? 26 : 34),
                            _dots(primary),
                            SizedBox(height: isSmall ? 18 : 24),
                            _nextButton(primary),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar(BuildContext context, Color primary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.forum_rounded, color: primary, size: 26),
            const SizedBox(width: 8),
            Text(
              'L I V E',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: primary,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        if (onSkip != null)
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              foregroundColor:
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text(
              'Skip',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  Widget _hero(BuildContext context, Color primary, double imageSize) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer soft glow
        Container(
          width: imageSize + 44,
          height: imageSize + 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.3),
                blurRadius: 50,
                spreadRadius: 20,
              ),
            ],
          ),
        ),
        // Image with inner glow
        Container(
          width: imageSize,
          height: imageSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.2),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              image,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(
                fallbackIcon,
                size: imageSize * 0.4,
                color: primary.withOpacity(0.7),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _title(ThemeData theme) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [
          theme.textTheme.displayLarge?.color ?? theme.colorScheme.onSurface,
          theme.primaryColor,
        ],
      ).createShader(bounds),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 34,
          fontWeight: FontWeight.w900,
          height: 1.15,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _dots(Color primary) {
    return Row(
      children: List.generate(totalPages, (i) {
        final active = i == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(right: 6),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? primary : primary.withOpacity(0.25),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _nextButton(Color primary) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onNext,
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            gradient: kButtonGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.4),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                nextLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
