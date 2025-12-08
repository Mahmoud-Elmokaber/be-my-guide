import 'package:app/Auth/SignUp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FlutterTts flutterTts = FlutterTts();
  String? selectedRole; // 'user' or 'volunteer'

  @override
  void initState() {
    super.initState();

    // رسالة ترحيبية أول ما الصفحة تظهر
    _speak("Welcome to be my guide app splash screen");
  }

  // دالة لتشغيل الـ TTS
  Future<void> _speak(String text) async {
    await flutterTts.stop(); // وقف أي TTS شغال
    await flutterTts.speak(text);
  }

  Widget buildButton({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: "$title, $subtitle",
      hint: "Double tap to activate",
      child: ElevatedButton(
        onPressed: () async {
          // اقرأ النص باستخدام TTS قبل تنفيذ الأكشن
          await _speak("$title, $subtitle");
          onTap();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 10, 83, 144),
          minimumSize: const Size(300, 100),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 18, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRoleButton({
    required String title,
    required String subtitle,
    required String userType,
    required Color backgroundColor,
  }) {
    return Semantics(
      button: true,
      label: "$title, $subtitle",
      hint: "Double tap to activate",
      child: ElevatedButton(
        onPressed: () async {
          await _speak("$title, $subtitle");
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userType', userType);
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SignUp(userType: userType),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          minimumSize: const Size(280, 90),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showUserRoleDialog() async {
    await _speak("Select your role. Blind or Deaf");
    setState(() => selectedRole = 'user');
  }

  Future<void> _showVolunteerRoleDialog() async {
    await _speak(
      "Select your volunteer role. General volunteer or Sign language expert",
    );
    setState(() => selectedRole = 'volunteer');
  }

  void _goBack() {
    setState(() => selectedRole = null);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: "Splash screen with options to get visual assistance or volunteer",
      child: Scaffold(
        backgroundColor: Colors.grey.shade900,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 26),

              // App Title مع Semantics
              Semantics(
                header: true,
                label: "App name be my guide",
                child: Text(
                  "be my guide",
                  style: const TextStyle(
                    fontSize: 26,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo image مع Semantics
                      Semantics(
                        label: 'App logo',
                        image: true,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 120,
                            height: 120,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // Welcome header
                      Semantics(
                        header: true,
                        label: "Welcome to be my guide",
                        child: Text(
                          'Welcome to be my guide',
                          style: const TextStyle(
                            fontSize: 30,
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Subtitle
                      Semantics(
                        label: "Helping you see the world better",
                        child: Text(
                          'Helping you see the world better',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 40),

                      if (selectedRole == null) ...[
                        // Button for users needing assistance
                        buildButton(
                          title: "I need assistance",
                          subtitle: "Call a volunteer",
                          onTap: _showUserRoleDialog,
                        ),

                        const SizedBox(height: 20),

                        // Button for volunteers
                        buildButton(
                          title: "I'd like to volunteer",
                          subtitle: "Help others",
                          onTap: _showVolunteerRoleDialog,
                        ),
                      ] else if (selectedRole == 'user') ...[
                        // User role selection
                        Semantics(
                          header: true,
                          label: "Select your role",
                          child: Text(
                            'What is your primary need?',
                            style: const TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 30),

                        buildRoleButton(
                          title: "I am Blind",
                          subtitle: "Need visual assistance",
                          userType: 'blind',
                          backgroundColor: const Color.fromARGB(
                            255,
                            13,
                            110,
                            180,
                          ),
                        ),

                        const SizedBox(height: 16),

                        buildRoleButton(
                          title: "I am Deaf",
                          subtitle: "Need hearing assistance",
                          userType: 'deaf',
                          backgroundColor: const Color.fromARGB(
                            255,
                            13,
                            110,
                            180,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Back button
                        TextButton(
                          onPressed: () async {
                            await _speak("Going back");
                            _goBack();
                          },
                          child: const Text(
                            '← Back',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ] else if (selectedRole == 'volunteer') ...[
                        // Volunteer role selection
                        Semantics(
                          header: true,
                          label: "Select your volunteer role",
                          child: Text(
                            'What type of volunteer are you?',
                            style: const TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 30),

                        buildRoleButton(
                          title: "General Volunteer",
                          subtitle: "Help blind and deaf users",
                          userType: 'volunteer',
                          backgroundColor: const Color.fromARGB(
                            255,
                            13,
                            110,
                            180,
                          ),
                        ),

                        const SizedBox(height: 16),

                        buildRoleButton(
                          title: "Sign Language Expert",
                          subtitle: "Assist deaf users",
                          userType: 'sign_language_expert',
                          backgroundColor: const Color.fromARGB(
                            255,
                            13,
                            110,
                            180,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Back button
                        TextButton(
                          onPressed: () async {
                            await _speak("Going back");
                            _goBack();
                          },
                          child: const Text(
                            '← Back',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
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
}
