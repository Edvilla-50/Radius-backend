import 'package:flutter/material.dart';
import 'package:radius_frontend/screens/registrationScreen.dart';
import 'screens/HomeScreen.dart';
import 'screens/LoginScreen.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Radius',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes:{
        '/login': (context) => LoginScreen(),
        '/register': (_) => const RegistrationScreen(),
        '/home': (context) => const HomeScreen(),
      } 
    );
  }
}