import 'dart:async';
import 'package:app/Pages/settingPage.dart';
import 'package:app/AgoraLogic/agora_logic.dart';
import 'package:app/Services/UserService.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class UserHome extends StatefulWidget {
  const UserHome({Key? key}) : super(key: key);

  @override
  _UserHomeState createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  // Service to handle backend logic (Firestore, Auth)
  final UserService _userService = UserService();
  // Text-to-Speech instance for accessibility
  final FlutterTts flutterTts = FlutterTts();

  // Agora logic instance for video call handling
  AgoraLogic? _agoraLogic;
  // Timer for periodic voice reminders
  Timer? _reminderTimer;

  // Call state variables
  String connectionStatus = "Disconnected";
  bool inCall = false;
  bool isMuted = false;
  bool isCameraOff = false;

  // Current active request details
  String? currentRequestId;
  String userName = '';
  String userEmail = '';
  String userType = '';
  List<Map<String, dynamic>> requests = [];

  @override
  void initState() {
    super.initState();
    // Load user data and history when the widget initializes
    _loadUserData();
    _loadUserRequests();
    // Start the voice reminder timer
    _startReminderTimer();
  }

  @override
  void dispose() {
    // Cancel timer and clean up Agora resources when disposed
    _reminderTimer?.cancel();
    _agoraLogic?.cleanup();
    super.dispose();
  }

  /// Starts a periodic timer to remind the user how to request assistance
  void _startReminderTimer() {
    _reminderTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (!inCall && mounted) {
        _speak("tap on the middle of the screen to get assistance");
      }
    });
  }

  /// Helper function to speak text using TTS
  Future<void> _speak(String text) async {
    await flutterTts.stop();
    await flutterTts.speak(text);
  }

  /// Loads user data from the service
  Future<void> _loadUserData() async {
    try {
      final userData = await _userService.loadUserData();
      if (userData != null) {
        setState(() {
          userName = userData['firstName'] ?? 'User';
          userType = userData['userType'] ?? '';
        });
        await _speak("Welcome $userName!");
      }
    } catch (e) {
      debugPrint('Failed to load user data: $e');
    }
  }

  /// Loads the user's request history from the service
  Future<void> _loadUserRequests() async {
    try {
      final userRequests = await _userService.loadUserRequests();
      setState(() {
        requests = userRequests;
      });
    } catch (e) {
      debugPrint('Failed to load user requests: $e');
    }
  }

  /// Initiates a new assistance request
  Future<void> requestAssistance() async {
    final user = _userService.currentUser;
    if (user == null) return;

    setState(() {
      inCall = true;
      connectionStatus = "Connecting...";
    });
    _speak("Requesting visual assistance, connecting now");

    // Initialize Agora
    const String agoraAppId = 'ad016719e08149d3b8176049cbbe8024';
    final String channelId = user.uid; // Use user ID as channel ID

    _agoraLogic = AgoraLogic(
      appId: agoraAppId,
      channel: channelId,
      onRemoteUserJoined: (uid) {
        if (mounted) {
          setState(() {
            // Trigger rebuild to show remote video
          });
        }
      },
      onRemoteUserLeft: (uid) {
        if (mounted) {
          setState(() {
            // Trigger rebuild to hide remote video
          });
        }
      },
    );

    try {
      // Initialize Agora engine and join channel
      await _agoraLogic!.initialize();
      await _agoraLogic!.requestPermissions();
      await _agoraLogic!.setupLocalVideo();
      await _agoraLogic!.joinChannel();

      /// this is the permission issue
      // Create request in Firestore via service
      currentRequestId = await _userService.createRequest(
        userName: userName,
        userType: userType,
        channelId: channelId,
      );

      setState(() {
        connectionStatus = "Live";
      });
      _speak("Call is live");
    } catch (e) {
      debugPrint("Error initializing Agora or Firestore: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Connection failed: $e")));
      }
      setState(() {
        inCall = false;
        connectionStatus = "Failed";
      });
      _speak("Failed to connect call");
    }
  }

  /// Ends the current call and updates the request status
  void endCall() async {
    if (_agoraLogic != null) {
      await _agoraLogic!.cleanup();
      _agoraLogic = null;
    }
    setState(() {
      inCall = false;
      connectionStatus = "Disconnected";
      isMuted = false;
      isCameraOff = false;
    });
    if (currentRequestId != null) {
      // Mark request as completed in Firestore
      _userService.completeRequest(currentRequestId!).catchError((e) {
        debugPrint('Failed to update request status on call end: $e');
      });
    }
    _speak("Call ended");
  }

  /// Toggles microphone mute state
  void toggleMute() {
    setState(() {
      isMuted = !isMuted;
    });
    _agoraLogic?.toggleLocalAudio(isMuted);
    _speak(isMuted ? "Microphone muted" : "Microphone unmuted");
  }

  /// Toggles camera state
  void toggleCamera() {
    setState(() {
      isCameraOff = !isCameraOff;
    });
    _agoraLogic?.toggleLocalVideo(isCameraOff);
    _speak(isCameraOff ? "Camera turned off" : "Camera turned on");
  }

  /// Logs out the user
  void _logout() async {
    await _userService.logout();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil('splashPage', (route) => false);
  }

  Future<void> _openSettings() async {
    _speak("Opening settings");
    _reminderTimer?.cancel();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsPage(
          userName: userName,
          userEmail: userEmail,
          onLogout: _logout,
        ),
      ),
    );
    if (mounted) {
      _startReminderTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color darkBackground = const Color(0xFF121212);
    final Color appBarColor = const Color(0xFF1F1F1F);
    final Color highlightColor = Colors.blueAccent;
    final TextStyle headerTextStyle = TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Colors.grey[100],
    );
    final TextStyle subtitleTextStyle = TextStyle(
      fontSize: 16,
      color: Colors.grey[400],
    );

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: appBarColor,
        title: Semantics(
          header: true,
          child: const Text(
            "be my guide",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          Semantics(
            label: 'Profile settings',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _openSettings,
              tooltip: "Settings",
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: inCall
            ? Stack(
                children: [
                  if (_agoraLogic != null)
                    Positioned.fill(child: _agoraLogic!.remoteVideoView()),
                  if (_agoraLogic != null)
                    Positioned(
                      bottom: 120,
                      right: 20,
                      width: 120,
                      height: 160,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _agoraLogic!.localVideoView(),
                      ),
                    ),
                  Positioned(
                    top: 50,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        connectionStatus,
                        style: TextStyle(
                          color: highlightColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          shadows: const [
                            Shadow(
                              blurRadius: 4,
                              color: Colors.black,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 30,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Semantics(
                          label: isMuted
                              ? 'Unmute microphone'
                              : 'Mute microphone',
                          button: true,
                          child: IconButton(
                            icon: Icon(isMuted ? Icons.mic_off : Icons.mic),
                            color: highlightColor,
                            iconSize: 32,
                            onPressed: toggleMute,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Semantics(
                          label: isCameraOff
                              ? 'Turn camera on'
                              : 'Turn camera off',
                          button: true,
                          child: IconButton(
                            icon: Icon(
                              isCameraOff ? Icons.videocam_off : Icons.videocam,
                            ),
                            color: highlightColor,
                            iconSize: 32,
                            onPressed: toggleCamera,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Semantics(
                          label: 'End call',
                          button: true,
                          child: IconButton(
                            icon: const Icon(Icons.call_end),
                            color: Colors.redAccent,
                            iconSize: 32,
                            onPressed: endCall,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Semantics(
                          label: 'Switch camera',
                          button: true,
                          child: IconButton(
                            icon: const Icon(Icons.cameraswitch),
                            color: highlightColor,
                            iconSize: 32,
                            onPressed: () {
                              _agoraLogic?.switchCamera();
                              _speak("Switching camera");
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Semantics(
                    container: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Hello, $userName!", style: headerTextStyle),
                        const SizedBox(height: 4),
                        Text(
                          "You can request visual assistance below.",
                          style: subtitleTextStyle,
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(400),
                      backgroundColor: highlightColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: requestAssistance,
                    child: Column(
                      children: const [
                        Text(
                          "Request Visual Assistance",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Call a volunteer now",
                          style: TextStyle(fontSize: 14, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
      ),
    );
  }
}
