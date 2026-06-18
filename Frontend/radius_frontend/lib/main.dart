import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

// SCREEN IMPORTS
import 'package:radius_frontend/screens/registrationScreen.dart';
import 'screens/HomeScreen.dart';
import 'screens/LoginScreen.dart';
import 'screens/SuggestionsScreen.dart';
import 'screens/MeetupMapScreen.dart';
import 'screens/EmergencyScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt("userId");
  final initialRoute = userId != null ? '/home' : '/login';

  runApp(MyApp(initialRoute: initialRoute, loggedInUserId: userId));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  final int? loggedInUserId;

  const MyApp({
    super.key, 
    required this.initialRoute, 
    this.loggedInUserId,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Radius',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (_) => const RegistrationScreen(),
        // FIXED: Invokes your parameterless HomeScreen wrapper layout 
        '/home': (context) => const HomeScreen(),
        // SUGGESTIONS ROUTE
        '/suggestions': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return SuggestionsScreen(
            matchId: args['matchId'],
            otherUserId: args['otherUserId'],
          );
        },
        // FIXED: Maps your exact properties including tracking coordinates and address details 
        '/map': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return MeetupMapScreen(
            userId: args['userId'],
            otherUserId: args['otherUserId'],
            matchId: args['matchId'],
            placeName: args['placeName'] ?? 'Meetup Location',
            placeAddress: args['placeAddress'] ?? 'Calculating coordinates...',
            placeLat: args['placeLat'],
            placeLon: args['placeLon'],
          );
        },
        // EMERGENCY ROUTE
        '/emergency': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final finalUserId = args?['userId'] ?? loggedInUserId;
          if (finalUserId == null) {
            return const LoginScreen();
          }
          return EmergencyScreen(userId: finalUserId);
        },
      },
    );
  }
}