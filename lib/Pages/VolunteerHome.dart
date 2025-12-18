import 'package:app/Pages/settingPage.dart';
import 'package:app/AgoraLogic/agora_logic.dart';
import 'package:app/Services/VolunteerService.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VolunteerHome extends StatefulWidget {
  const VolunteerHome({Key? key}) : super(key: key);

  @override
  State<VolunteerHome> createState() => _VolunteerHomeState();
}

class _VolunteerHomeState extends State<VolunteerHome> {
  // Service to handle backend logic (Firestore, Auth, Notifications)
  final VolunteerService _volunteerService = VolunteerService();
  // Text-to-Speech instance for accessibility
  final FlutterTts flutterTts = FlutterTts();

  // Agora logic instance for video call handling
  AgoraLogic? _agoraLogic;

  // User profile data
  String userName = '';
  String userEmail = '';
  String userType = '';

  // Call state variables
  bool inCall = false;
  bool isMuted = false;
  bool isCameraOff = false;
  String connectionStatus = "Disconnected";

  // Current active request details
  String? currentRequestId;
  String? currentRequestUserName;

  @override
  void initState() {
    super.initState();
    // Load user data when the widget initializes
    _loadUserData();
  }

  @override
  void dispose() {
    // Clean up Agora resources when the widget is disposed
    _agoraLogic?.cleanup();
    super.dispose();
  }

  /// Helper function to speak text using TTS
  Future<void> _speak(String text) async {
    await flutterTts.stop();
    await flutterTts.speak(text);
  }

  /// Loads user data from the service and sets up notifications
  Future<void> _loadUserData() async {
    try {
      final userData = await _volunteerService.loadUserData();
      if (userData != null) {
        setState(() {
          userName = userData['firstName'] ?? 'Volunteer';
          userEmail = userData['email'] ?? '';
          userType = userData['userType'] ?? '';
        });
        // Setup notifications based on the user's role
        await _volunteerService.setupNotifications(userType);
        await _speak("Welcome $userName!");
      }
    } catch (e) {
      debugPrint('Failed to load user data: $e');
    }
  }

  /// Handles accepting a request from the list
  Future<void> _acceptRequest(Map<String, dynamic> request) async {
    if (inCall) return; // Prevent accepting multiple calls

    setState(() {
      inCall = true;
      connectionStatus = "Connecting...";
      currentRequestId = request['requestId'];
      currentRequestUserName = request['userName'];
    });
    _speak("Connecting with ${request['userName']}");

    // Initialize Agora
    // TODO: Replace with your actual Agora App ID
    const String agoraAppId = 'ad016719e08149d3b8176049cbbe8024';
    _agoraLogic = AgoraLogic(
      appId: agoraAppId,
      channel: request['channelId'], // Join the channel specific to the request
      onRemoteUserJoined: (uid) {
        if (mounted) {
          setState(() {
            // Trigger rebuild to show remote video when user joins
          });
        }
      },
      onRemoteUserLeft: (uid) {
        if (mounted) {
          setState(() {
            // Trigger rebuild to hide remote video when user leaves
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

      // Update Firestore status to 'accepted' via service
      await _volunteerService.acceptRequestInFirestore(
        request['requestId'],
        userName,
      );

      setState(() {
        connectionStatus = "Live";
      });
      _speak("Call is live");
    } catch (e) {
      debugPrint("Error initializing Agora or updating Firestore: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Connection failed: $e")));
      }
      // Cleanup if partial failure
      await _agoraLogic?.cleanup();
      _agoraLogic = null;

      setState(() {
        inCall = false;
        connectionStatus = "Failed";
        currentRequestId = null;
        currentRequestUserName = null;
      });
      _speak("Failed to connect call");
    }
  }

  /// Ends the current call and updates the request status
  void endCall() async {
    if (currentRequestId != null) {
      // Mark request as completed in Firestore
      _volunteerService
          .completeRequestInFirestore(currentRequestId!)
          .catchError((e) {
            debugPrint('Failed to update request status on call end: $e');
          });
    }

    // Clean up Agora resources
    if (_agoraLogic != null) {
      await _agoraLogic!.cleanup();
      _agoraLogic = null;
    }

    // Reset UI state
    setState(() {
      inCall = false;
      connectionStatus = "Disconnected";
      isMuted = false;
      isCameraOff = false;
      currentRequestId = null;
      currentRequestUserName = null;
    });
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
    await _volunteerService.logout();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil('splashPage', (route) => false);
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsPage(
          userName: userName,
          userEmail: userEmail,
          onLogout: _logout,
        ),
      ),
    );
  }

  Widget _buildRequestTile(Map<String, dynamic> req) {
    final String status = (req['requestStatus'] ?? 'pending')
        .toString()
        .toLowerCase();
    final bool isAcceptedOrCompleted =
        status == 'accepted' || status == 'completed';

    return Semantics(
      label: 'Request from ${req["userName"]}, status: $status',
      button: !isAcceptedOrCompleted && !inCall,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey[700],
          backgroundImage: req["userPhoto"] != null
              ? NetworkImage(req["userPhoto"])
              : null,
          child: req["userPhoto"] == null
              ? Text(
                  req["userName"].toString().substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          req["userName"],
          style: TextStyle(
            color: Colors.grey[100],
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          status == 'pending'
              ? "Tap to start video call"
              : status == 'accepted'
              ? "Request accepted"
              : "Request completed",
          style: TextStyle(color: Colors.grey[400]),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatTimestamp(req["timestamp"]),
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            if (status == 'pending')
              Icon(Icons.circle, color: Colors.greenAccent, size: 12)
            else if (status == 'accepted')
              Icon(Icons.call, color: Colors.orangeAccent, size: 16)
            else
              Icon(Icons.check, color: Colors.grey, size: 16),
          ],
        ),
        enabled: !isAcceptedOrCompleted && !inCall,
        onTap: () {
          if (!isAcceptedOrCompleted && !inCall) _acceptRequest(req);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color darkBackground = const Color(0xFF121212);
    final Color appBarColor = const Color(0xFF1F1F1F);
    final Color highlightColor = Colors.greenAccent;
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
        title: Semantics(header: true, child: const Text("be my guide")),
        actions: [
          Semantics(
            label: 'Profile settings',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                _speak("Opening Settings");
                _openSettings();
              },
              tooltip: "Settings",
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: _volunteerService.getRequestsStream(userType),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              debugPrint('Firestore stream error: ${snapshot.error}');
              return Center(
                child: Text(
                  'Error loading requests: ${snapshot.error}',
                  style: subtitleTextStyle,
                  textAlign: TextAlign.center,
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? [];
            final requests = docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {
                'userName': data['userName'] ?? 'Unknown',
                'userPhoto': data['userPhoto'],
                'contact': data['contact'] ?? '',
                'timestamp': data['createdAt']?.toDate() ?? DateTime.now(),
                'requestId': doc.id,
                'requestStatus': data['status'] ?? 'pending',
                'channelId': data['channelId'] ?? 'test_channel',
              };
            }).toList();

            if (inCall) {
              return Stack(
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
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                await Future.delayed(const Duration(seconds: 1));
              },
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text("Hello, $userName!", style: headerTextStyle),
                  const SizedBox(height: 4),
                  Text(
                    "Users requesting assistance:",
                    style: subtitleTextStyle,
                  ),
                  const SizedBox(height: 20),
                  requests.isEmpty
                      ? Text("No pending requests.", style: subtitleTextStyle)
                      : ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: requests.length,
                          separatorBuilder: (_, __) =>
                              const Divider(color: Colors.grey),
                          itemBuilder: (context, index) {
                            return _buildRequestTile(requests[index]);
                          },
                        ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hr ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}
