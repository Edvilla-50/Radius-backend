import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:radius_frontend/screens/LoginScreen.dart';

class OnboardingScreen extends StatelessWidget {
  final bool isTutorial;

  const OnboardingScreen({super.key, this.isTutorial = false});

  static const _pages = <_OnboardingContent>[
    _OnboardingContent(
      "Check In to See Who's Nearby",
      "You start every session hidden. Tap the SCAN button and confirm to check in. While you're checked in, you'll see nearby people who have checked in too, each with a compatibility score based on your TraitStack.",
      'assets/images/scan.png',
    ),
    _OnboardingContent(
      'Build Your TraitStack',
      'Your TraitStack is a dynamic system you can customize to your liking by ranking your interests in order of importance. The Innocuous Algorithm uses this to compute a compatibility score for people near you and sorts them accordingly.',
      'assets/images/traitstack.png',
    ),
    _OnboardingContent(
      'Express Yourself',
      'Radius gives you a customizable profile page. Visit radius-create.com to design your profile with your own style and story, so others know a little about you before you meet.',
      'assets/images/profile.png',
    ),
    _OnboardingContent(
      'Send a Meetup Request',
      'If you find someone interesting, send them a meetup request. If they accept, you can start chatting and arrange to meet in person the same day. The app will suggest nearby public places to meet, and you both confirm the spot.',
      'assets/images/meetup.png',
    ),
    _OnboardingContent(
      'Your Safety Matters',
      'Radius has a built-in emergency system. If you ever feel unsafe during a meetup, press the emergency button to instantly alert your trusted contacts with your location. You can also report or block anyone at any time.',
      'assets/images/emergency.png',
    ),
    _OnboardingContent(
      "You're Always in Control",
      "Your location is shared only when you check in, and every check-in ends automatically after 30 minutes. Tap Stop Sharing to hide right away. If you close the app, you disappear from the map too. Other people's locations are never shown during a meetup.",
      null,
    ),
    _OnboardingContent(
      'Meet in Real Life',
      'Radius is about real connections. Get off the app and go meet someone nearby today.',
      'assets/images/meetirl.png',
    ),
  ];

  Future<void> _completeOnboarding(BuildContext context) async {
    if (isTutorial) {
      Navigator.pop(context);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  Widget _illustration(_OnboardingContent page) {
    if (page.asset == null) {
      return const Icon(Icons.location_off, size: 112, color: Colors.white);
    }
    return Image.asset(page.asset!, fit: BoxFit.contain);
  }

  Widget _widePage(_OnboardingContent page) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _illustration(page),
                ),
              ),
              const SizedBox(width: 28),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        page.title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        page.body,
                        style: const TextStyle(
                          fontSize: 18,
                          height: 1.5,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PageViewModel _buildPage(_OnboardingContent page, bool wide) {
    if (wide) {
      return PageViewModel(
        titleWidget: const SizedBox.shrink(),
        bodyWidget: _widePage(page),
        decoration: const PageDecoration(
          pageColor: Colors.blueAccent,
          fullScreen: true,
          contentMargin: EdgeInsets.zero,
          imagePadding: EdgeInsets.zero,
          bodyPadding: EdgeInsets.zero,
        ),
      );
    }
    return PageViewModel(
      title: page.title,
      body: page.body,
      image: _illustration(page),
      decoration: const PageDecoration(
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        bodyTextStyle: TextStyle(fontSize: 18, color: Colors.white),
        pageColor: Colors.blueAccent,
        imagePadding: EdgeInsets.all(24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent,
      appBar: isTutorial
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            )
          : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // A width-based fallback also works on tablets and desktop windows.
            // A narrower folded viewport keeps the original vertical pages.
            final wide =
                constraints.maxWidth >= 720 && constraints.maxHeight >= 360;
            return IntroductionScreen(
              key: ValueKey(wide),
              pages: _pages.map((page) => _buildPage(page, wide)).toList(),
              onDone: () => _completeOnboarding(context),
              onSkip: () => _completeOnboarding(context),
              showSkipButton: true,
              skip: const Text('Skip', style: TextStyle(color: Colors.white)),
              next: const Icon(Icons.arrow_forward, color: Colors.white),
              done: Text(
                isTutorial ? 'Done' : 'Get Started',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              dotsDecorator: const DotsDecorator(activeColor: Colors.white),
            );
          },
        ),
      ),
    );
  }
}

class _OnboardingContent {
  final String title;
  final String body;
  final String? asset;

  const _OnboardingContent(this.title, this.body, this.asset);
}
