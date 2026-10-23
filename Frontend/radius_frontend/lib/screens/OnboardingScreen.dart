import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:radius_frontend/screens/LoginScreen.dart';

class OnboardingScreen extends StatelessWidget {
  final bool isTutorial;

  const OnboardingScreen({super.key, this.isTutorial = false});

  static const PageDecoration _pageDecoration = PageDecoration(
    titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
    bodyTextStyle: TextStyle(fontSize: 18, color: Colors.white),
    pageColor: Colors.blueAccent,
    imagePadding: EdgeInsets.all(24),
  );

  Future<void> _completeOnboarding(BuildContext context) async {
    if (isTutorial) {
      Navigator.pop(context);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wrapping in a Scaffold allows us to inject an AppBar with a close button
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
          : null, // No close button during the very first app launch setup
      body: SafeArea(
        child: IntroductionScreen(
          pages: [
            PageViewModel(
              title: "Check In to See Who's Nearby",
              body: "You start every session hidden. Tap the SCAN button and confirm to check in. While you're checked in, you'll see nearby people who have checked in too, each with a compatibility score based on your TraitStack.",
              image: Image.asset('assets/images/scan.png'),
              decoration: _pageDecoration,
            ),
            PageViewModel(
              title: "Build Your TraitStack",
              body: "Your TraitStack is a dynamic system you can customize to your liking by ranking your interests in order of importance. The Innocuous Algorithm uses this to compute a compatibility score for people near you and sorts them accordingly.",
              image: Image.asset('assets/images/traitstack.png'),
              decoration: _pageDecoration,
            ),
            PageViewModel(
              title: "Express Yourself",
              body: "Radius gives you a customizable profile page. Visit radius-create.com to design your profile with your own style and story, so others know a little about you before you meet.",
              image: Image.asset('assets/images/profile.png'),
              decoration: _pageDecoration,
            ),
            PageViewModel(
              title: "Send a Meetup Request",
              body: "If you find someone interesting, send them a meetup request. If they accept, you can start chatting and arrange to meet in person the same day. The app will suggest nearby public places to meet, and you both confirm the spot.",
              image: Image.asset('assets/images/meetup.png'),
              decoration: _pageDecoration,
            ),
            PageViewModel(
              title: "Your Safety Matters",
              body: "Radius has a built-in emergency system. If you ever feel unsafe during a meetup, press the emergency button to instantly alert your trusted contacts with your location. You can also report or block anyone at any time.",
              image: Image.asset('assets/images/emergency.png'),
              decoration: _pageDecoration,
            ),
            PageViewModel(
              title: "You're Always in Control",
              body: "Your location is shared only when you check in, and every check-in ends automatically after 30 minutes. Tap Stop Sharing to hide right away. If you close the app, you disappear from the map too. Other people's locations are never shown during a meetup.",
              image: const Icon(
                Icons.location_off,
                size: 120,
                color: Colors.white,
              ),
              decoration: _pageDecoration,
            ),
            PageViewModel(
              title: "Meet in Real Life",
              body: "Radius is about real connections. Get off the app and go meet someone nearby today.",
              image: Image.asset('assets/images/meetirl.png'),
              decoration: _pageDecoration,
            ),
          ],
          onDone: () => _completeOnboarding(context),
          onSkip: () => _completeOnboarding(context),
          showSkipButton: true,
          skip: const Text("Skip", style: TextStyle(color: Colors.white)),
          next: const Icon(Icons.arrow_forward, color: Colors.white),
          done: Text(
            isTutorial ? "Done" : "Get Started",
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          dotsDecorator: const DotsDecorator(
            activeColor: Colors.white,
          ),
        ),
      ),
    );
  }
}