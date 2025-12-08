import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Pages/SplashScreen.dart';
import '../Pages/VolunteerHome.dart';
import '../Pages/UserHome.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  String? _userType;

  @override
  void initState() {
    super.initState();
    _checkUser();
  }

  Future<void> _checkUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data();
          _userType = data?['userType'] as String?;
        }
      } catch (e) {
        // Handle error if needed
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
      );
    }

    if (_auth.currentUser == null) {
      return const SplashScreen();
    }

    // Handle all user types
    if (_userType == 'blind' || _userType == 'deaf') {
      // Both deaf and blind users go to UserHome
      return const UserHome();
    } else if (_userType == 'volunteer' ||
        _userType == 'sign_language_expert') {
      // Both general volunteers and sign language experts go to VolunteerHome
      return const VolunteerHome();
    } else {
      return const SplashScreen();
    }
  }
}
