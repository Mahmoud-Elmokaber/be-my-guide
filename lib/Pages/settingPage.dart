import 'package:app/Pages/AccessibilitySettingsPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  final String userName;
  final String userEmail;
  final VoidCallback onLogout;

  const SettingsPage({
    Key? key,
    required this.userName,
    required this.userEmail,
    required this.onLogout,
  }) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool voicePromptsEnabled = true;
  bool vibrationAlertsEnabled = true;

  final FlutterTts flutterTts = FlutterTts();

  final Color darkBackground = const Color(0xFF121212);
  final Color cardColor = const Color(0xFF1F1F1F);
  final TextStyle headerTextStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.grey[100],
  );
  final TextStyle labelStyle = TextStyle(
    fontSize: 16,
    color: Colors.grey[300],
  );
  final TextStyle emailStyle = TextStyle(
    fontSize: 14,
    color: Colors.grey[400],
  );

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _speak(String text) async {
    await flutterTts.stop();
    await flutterTts.speak(text);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      voicePromptsEnabled = prefs.getBool('voicePromptsEnabled') ?? true;
      vibrationAlertsEnabled = prefs.getBool('vibrationAlertsEnabled') ?? true;
    });
  }

  Future<void> _saveVoicePromptsSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('voicePromptsEnabled', value);
  }

  Future<void> _saveVibrationAlertsSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibrationAlertsEnabled', value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkBackground,
        title: const Text('Settings'),
      ),
      backgroundColor: darkBackground,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Semantics(
            header: true,
            child: Text('Profile', style: headerTextStyle),
          ),
          const SizedBox(height: 12),
          Card(
            color: cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.blueAccent, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.userName,
                            style: labelStyle.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(widget.userEmail, style: emailStyle, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),

          Semantics(header: true, child: Text('Blind Assistance Settings', style: headerTextStyle)),
          const SizedBox(height: 12),

          Card(
            color: cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: SwitchListTile(
              secondary: const Icon(Icons.volume_up, color: Colors.blueAccent),
              title: const Text('Voice Prompts', style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                'Enable voice guidance and prompts during calls',
                style: TextStyle(color: Colors.white70),
              ),
              value: voicePromptsEnabled,
              onChanged: (val) {
                setState(() => voicePromptsEnabled = val);
                _saveVoicePromptsSetting(val);
                _speak("Voice Prompts ${val ? 'enabled' : 'disabled'}");
              },
            ),
          ),
          const SizedBox(height: 12),

          Card(
            color: cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: SwitchListTile(
              secondary: const Icon(Icons.vibration, color: Colors.blueAccent),
              title: const Text('Vibration Alerts', style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                'Enable vibration for incoming calls and notifications',
                style: TextStyle(color: Colors.white70),
              ),
              value: vibrationAlertsEnabled,
              onChanged: (val) {
                setState(() => vibrationAlertsEnabled = val);
                _saveVibrationAlertsSetting(val);
                _speak("Vibration Alerts ${val ? 'enabled' : 'disabled'}");
              },
            ),
          ),
          const SizedBox(height: 12),

          Card(
            color: cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.accessibility_new, color: Colors.blueAccent),
              title: const Text('Accessibility Options', style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                'Customize font size, contrast, and other accessibility features',
                style: TextStyle(color: Colors.white70),
              ),
              onTap: () {
                _speak("Opening Accessibility Options");
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => AccessibilitySettingsPage()));
              },
            ),
          ),
          const SizedBox(height: 30),

          Card(
            color: cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                _speak("Logging out");
                widget.onLogout();
              },
            ),
          ),
        ],
      ),
    );
  }
}
