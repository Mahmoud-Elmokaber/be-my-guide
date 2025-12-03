import 'package:app/Auth/AuthWrapper.dart';
import 'package:app/Auth/Login.dart';
import 'package:app/Auth/SignUp.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'Pages/SplashScreen.dart';
import 'Pages/VolunteerHome.dart';
import 'Pages/UserHome.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.grey.shade900,
        primaryColor: const Color.fromARGB(255, 10, 83, 144),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: Colors.white,
          contentTextStyle: TextStyle(
            color: Colors.grey.shade900,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          behavior: SnackBarBehavior.floating,
          elevation: 5,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey.shade900,
          foregroundColor: const Color.fromARGB(255, 207, 227, 235),
          iconTheme: const IconThemeData(color: Color.fromARGB(255, 207, 227, 235)),
          titleTextStyle: const TextStyle(
            color: Color.fromARGB(255, 207, 227, 235),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 10, 83, 144),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            minimumSize: const Size(300, 100),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade800,
          hintStyle: const TextStyle(color: Colors.white70),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),

      // Use a wrapper widget as home to decide navigation based on auth state
      home: const AuthWrapper(),

      routes: {
        "volunteerHome": (context) => const VolunteerHome(),
        "userHome": (context) => const UserHome(),
        "splashPage": (context) => const SplashScreen(),
        "login": (context) => const Login(userType: ''),
        "signup": (context) => const SignUp(userType: ''),
      },
    );
  }
}