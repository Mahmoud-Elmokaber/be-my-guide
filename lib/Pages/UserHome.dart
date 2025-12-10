import 'dart:async';
import 'package:app/Pages/settingPage.dart';
import 'package:app/AgoraLogic/agora_logic.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserHome extends StatefulWidget {
  const UserHome({Key? key}) : super(key: key);

  @override
  _UserHomeState createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterTts flutterTts = FlutterTts();

  AgoraLogic? _agoraLogic;
  Timer? _reminderTimer;

  String connectionStatus = "Disconnected";
  bool inCall = false;
  bool isMuted = false;
  bool isCameraOff = false;
  String? currentRequestId;
  String userName = '';
  String userEmail = '';
  String userType = '';
  List<Map<String, dynamic>> requests = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUserRequests();
    _startReminderTimer();
  }

  @override
  void dispose() {
    _reminderTimer?.cancel();
    _agoraLogic?.cleanup();
    super.dispose();
  }

  void _startReminderTimer() {
    _reminderTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (!inCall && mounted) {
        _speak("press on the middle of the screen to get assistance");
      }
    });
  }

  Future<void> _speak(String text) async {
    await flutterTts.stop();
    await flutterTts.speak(text);
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          userName = doc.data()?['firstName'] ?? 'User';
          userType = doc.data()?['userType'] ?? '';
        });
        await _speak("Welcome $userName!");
      }
    }
  }

  Future<void> _loadUserRequests() async {
    final user = _auth.currentUser;
    if (user != null) {
      final querySnapshot = await _firestore
          .collection('requests')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        requests = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'status': data['status'] ?? 'Unknown',
            'volunteerName': data['volunteerName'] ?? 'Unknown',
            'volunteerPhoto': data['volunteerPhotoUrl'],
            'contact': data['volunteerContact'] ?? '',
            'timestamp': data['createdAt']?.toDate() ?? DateTime.now(),
          };
        }).toList();
      });
    }
  }

  Future<void> requestAssistance() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      inCall = true;
      connectionStatus = "Connecting...";
    });
    _speak("Requesting visual assistance, connecting now");

    // Initialize Agora
    // TODO: Replace with your actual Agora App ID
    const String agoraAppId = 'ad016719e08149d3b8176049cbbe8024';
    final String channelId = user.uid;

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
      await _agoraLogic!.initialize();
      await _agoraLogic!.requestPermissions();
      await _agoraLogic!.setupLocalVideo();
      await _agoraLogic!.joinChannel();

      /// this is the permission issue
      // Create request in Firestore
      debugPrint("Creating request for user: ${user.uid}");
      final docRef = await _firestore.collection('requests').add({
        'userId': user.uid,
        'userName': userName,
        'userType': userType,
        'userPhoto': null, // TODO: Add user photo if available
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'channelId': channelId,
      });
      currentRequestId = docRef.id;

      debugPrint("Request created successfully");

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
      _firestore
          .collection('requests')
          .doc(currentRequestId)
          .update({
            'status': 'completed',
            'completedAt': FieldValue.serverTimestamp(),
          })
          .catchError((e) {
            debugPrint('Failed to update request status on call end: $e');
          });
    }
    _speak("Call ended");
  }

  void toggleMute() {
    setState(() {
      isMuted = !isMuted;
    });
    _agoraLogic?.toggleLocalAudio(isMuted);
    _speak(isMuted ? "Microphone muted" : "Microphone unmuted");
  }

  void toggleCamera() {
    setState(() {
      isCameraOff = !isCameraOff;
    });
    _agoraLogic?.toggleLocalVideo(isCameraOff);
    _speak(isCameraOff ? "Camera turned off" : "Camera turned on");
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userType');
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
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (!inCall) ...[
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
            ],

            // Video call controls
            Semantics(
              container: true,
              label: inCall
                  ? 'Video call in progress. Connection status: $connectionStatus'
                  : 'Video call controls',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (inCall)
                    Text(
                      connectionStatus,
                      style: TextStyle(
                        color: highlightColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  if (inCall) const SizedBox(height: 10),
                  if (inCall && _agoraLogic != null)
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _agoraLogic!.remoteVideoView(),
                      ),
                    ),
                  if (inCall && _agoraLogic != null) const SizedBox(height: 10),
                  if (inCall && _agoraLogic != null)
                    Container(
                      height: 100,
                      width: 140,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _agoraLogic!.localVideoView(),
                      ),
                    ),
                  if (inCall) const SizedBox(height: 10),
                  if (inCall)
                    Row(
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
                  if (!inCall)
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
                ],
              ),
            ),

            if (!inCall) ...[const SizedBox(height: 30)],
          ],
        ),
      ),
    );
  }
}
