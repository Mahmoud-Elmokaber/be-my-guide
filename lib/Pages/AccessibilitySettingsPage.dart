import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AccessibilitySettingsPage extends StatefulWidget {
  const AccessibilitySettingsPage({Key? key}) : super(key: key);

  @override
  State<AccessibilitySettingsPage> createState() => _AccessibilitySettingsPageState();
}

class _AccessibilitySettingsPageState extends State<AccessibilitySettingsPage> {
  final FlutterTts flutterTts = FlutterTts();

  Future<void> _speak(String text) async {
    await flutterTts.stop();
    await flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    final Color darkBackground = const Color(0xFF121212);
    final TextStyle headerTextStyle = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: Colors.grey[100],
    );
    final TextStyle optionTextStyle = TextStyle(
      fontSize: 18,
      color: Colors.grey[300],
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkBackground,
        title: const Text('Accessibility Options'),
      ),
      backgroundColor: darkBackground,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Accessibility Options', style: headerTextStyle),
          const SizedBox(height: 20),

          ListTile(
            title: Text('Font Size', style: optionTextStyle),
            subtitle: const Text(
              'Adjust the font size throughout the app',
              style: TextStyle(color: Colors.white70),
            ),
            onTap: () {
              _speak("Adjust Font Size");
              // TODO: Implement font size adjustment UI
            },
          ),
          const Divider(color: Colors.grey),

          ListTile(
            title: Text('High Contrast Mode', style: optionTextStyle),
            subtitle: const Text(
              'Toggle high contrast colors for better visibility',
              style: TextStyle(color: Colors.white70),
            ),
            onTap: () {
              _speak("Toggle High Contrast Mode");
              // TODO: Implement high contrast toggle
            },
          ),
          const Divider(color: Colors.grey),

          ListTile(
            title: Text('Screen Reader Support', style: optionTextStyle),
            subtitle: const Text(
              'Enable support for screen readers and voice assistance',
              style: TextStyle(color: Colors.white70),
            ),
            onTap: () {
              _speak("Enable Screen Reader Support");
              // TODO: Implement screen reader support settings
            },
          ),
          const Divider(color: Colors.grey),

        
        ],
      ),
    );
  }
}
