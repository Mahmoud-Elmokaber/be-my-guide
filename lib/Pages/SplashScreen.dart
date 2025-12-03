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

  @override
  void initState() {
    super.initState();

    // رسالة ترحيبية أول ما الصفحة تظهر
    _speak("Welcome to SeeTogether app splash screen");
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
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
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
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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
                label: "App name SeeTogether",
                child: Text(
                  "SeeTogether",
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
                        label: "Welcome to SeeTogether",
                        child: Text(
                          'Welcome to SeeTogether',
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

                      // زرار أول
                      buildButton(
                        title: "I need visual assistance",
                        subtitle: "Call a volunteer",
                        onTap: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('userType', 'user'); 
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => SignUp(userType: 'user')),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // زرار ثاني
                      buildButton(
                        title: "I'd like to volunteer",
                        subtitle: "Share your eyesight",
                        onTap: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('userType', 'volunteer'); 
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => SignUp(userType: 'volunteer')),
                          );
                        },
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
}
