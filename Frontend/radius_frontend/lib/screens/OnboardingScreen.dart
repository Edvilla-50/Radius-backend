import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:radius_frontend/screens/LoginScreen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _completeOnboarding(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      pages: [
        PageViewModel(
          title: "See Who's Nearby",
          body: "Discover real people nearby who share your interests by pressing the scan button. Each person will have a score that indicates compatibility, determined by your TraitStack.",
          image: Image.asset('assets/images/scan.png'),
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
        ),
        PageViewModel(
          title: "Build Your TraitStack",
          body: "Your TraitStack is a dynamic system you can customize to your liking by ranking your interests in order of importance. The Innocuous Algorithm uses this to compute a compatibility score for people near you and sorts them accordingly.",
          image: Image.asset('assets/images/traitstack.png'),
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
        ),
        PageViewModel(
          title: "Express Yourself",
          body: "Radius gives you a fully customizable HTML profile page. Visit radius-create.com to design your profile — add your personality, style, and story so others know exactly who they're meeting before they show up.",
          image: Image.asset('assets/images/profile.png'),
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
        ),
        PageViewModel(
          title: "Send a Meetup Request",
          body: "If you find someone interesting, send them a meetup request. If they accept, you can start chatting and arrange to meet in person the same day. The app will suggest nearby locations to meet up at.",
          image: Image.asset('assets/images/meetup.png'),
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
        ),
        PageViewModel(
          title: "Your Safety Matters",
          body: "Radius has a built-in emergency system. If you ever feel unsafe during a meetup, press the emergency button to instantly alert your trusted contacts with your live location.",
          image: Image.asset('assets/images/emergency.png'),
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
        ),
        PageViewModel(
          title: "Meet in Real Life",
          body: "Radius is about real connections. Get off the app and go meet someone nearby today.",
          image: Image.asset('assets/images/meetirl.png'),
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
        ),
      ],
      onDone: () => _completeOnboarding(context),
      onSkip: () => _completeOnboarding(context),
      showSkipButton: true,
      skip: const Text("Skip", style: TextStyle(color: Colors.white)),
      next: const Icon(Icons.arrow_forward, color: Colors.white),
      done: const Text(
        "Get Started",
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      dotsDecorator: DotsDecorator(
        activeColor: Colors.white,
      ),
    );
  }
}