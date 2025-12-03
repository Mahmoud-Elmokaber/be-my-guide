import 'package:app/Pages/settingPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VolunteerHome extends StatefulWidget {
  const VolunteerHome({Key? key}) : super(key: key);

  @override
  State<VolunteerHome> createState() => _VolunteerHomeState();
}

class _VolunteerHomeState extends State<VolunteerHome> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterTts flutterTts = FlutterTts();

  String userName = '';
  String userEmail = '';

  bool inCall = false;
  bool isMuted = false;
  bool isCameraOff = false;
  String connectionStatus = "Disconnected";

  String? currentRequestId;
  String? currentRequestUserName;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _speak(String text) async {
    await flutterTts.stop();
    await flutterTts.speak(text);
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            userName = doc.data()?['firstName'] ?? 'Volunteer';
            userEmail = doc.data()?['email'] ?? '';
          });
          await _speak("Welcome $userName!");
        }
      } catch (e) {
        debugPrint('Failed to load user data: $e');
      }
    }
  }

  Stream<QuerySnapshot> getRequestsStream() {
    return _firestore
        .collection('users')
        .where('userType', isEqualTo: 'user')
        .where('requestStatus', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  void _acceptRequest(Map<String, dynamic> request) {
    if (inCall) return;

    setState(() {
      inCall = true;
      connectionStatus = "Connecting...";
      currentRequestId = request['requestId'];
      currentRequestUserName = request['userName'];
    });
    _speak("Connecting with ${request['userName']}");

    _firestore.collection('users').doc(request['requestId']).update({
      'requestStatus': 'accepted',
      'volunteerId': _auth.currentUser?.uid,
      'volunteerName': userName,
      'acceptedAt': FieldValue.serverTimestamp(),
    }).catchError((e) {
      debugPrint('Failed to update request status: $e');
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        connectionStatus = "Live";
      });
      _speak("Call is live");
    });
  }

  void endCall() {
    if (currentRequestId != null) {
      _firestore.collection('users').doc(currentRequestId).update({
        'requestStatus': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      }).catchError((e) {
        debugPrint('Failed to update request status on call end: $e');
      });
    }

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

  void toggleMute() {
    setState(() {
      isMuted = !isMuted;
    });
    _speak(isMuted ? "Microphone muted" : "Microphone unmuted");
  }

  void toggleCamera() {
    setState(() {
      isCameraOff = !isCameraOff;
    });
    _speak(isCameraOff ? "Camera turned off" : "Camera turned on");
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userType');
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('splashPage', (route) => false);
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
    final String status = (req['requestStatus'] ?? 'pending').toString().toLowerCase();
    final bool isAcceptedOrCompleted = status == 'accepted' || status == 'completed';

    return Semantics(
      label: 'Request from ${req["userName"]}, status: $status',
      button: !isAcceptedOrCompleted && !inCall,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey[700],
          backgroundImage: req["userPhoto"] != null ? NetworkImage(req["userPhoto"]) : null,
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
          style: TextStyle(color: Colors.grey[100], fontWeight: FontWeight.w600),
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
        title: Semantics(header: true, child: const Text("SeeTogether")),
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
          stream: getRequestsStream(),
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
                'userName': data['firstName'] ?? 'Unknown',
                'userPhoto': data['photoUrl'],
                'contact': data['contact'] ?? '',
                'timestamp': data['createdAt']?.toDate() ?? DateTime.now(),
                'requestId': doc.id,
                'requestStatus': data['requestStatus'] ?? 'pending',
              };
            }).toList();

            return RefreshIndicator(
              onRefresh: () async {
                await Future.delayed(const Duration(seconds: 1));
              },
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (!inCall) ...[
                    Text("Hello, $userName!", style: headerTextStyle),
                    const SizedBox(height: 4),
                    Text("Users requesting assistance:", style: subtitleTextStyle),
                    const SizedBox(height: 20),
                  ],
                  if (!inCall)
                    requests.isEmpty
                        ? Text("No pending requests.", style: subtitleTextStyle)
                        : ListView.separated(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: requests.length,
                            separatorBuilder: (_, __) => const Divider(color: Colors.grey),
                            itemBuilder: (context, index) {
                              return _buildRequestTile(requests[index]);
                            },
                          ),
                  if (inCall) ...[
                    const SizedBox(height: 20),
                    Center(
                      child: Text(connectionStatus,
                          style: TextStyle(
                              color: highlightColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                          child: Text('${currentRequestUserName} Video',
                              style: TextStyle(color: Colors.grey[400]))),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 100,
                      width: 140,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                          child: Text('Your Self-View',
                              style: TextStyle(color: Colors.grey[400]))),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Semantics(
                          label: isMuted ? 'Unmute microphone' : 'Mute microphone',
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
                          label: isCameraOff ? 'Turn camera on' : 'Turn camera off',
                          button: true,
                          child: IconButton(
                            icon: Icon(isCameraOff ? Icons.videocam_off : Icons.videocam),
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
                            onPressed: () => _speak("Switching camera"),
                          ),
                        ),
                      ],
                    ),
                  ],
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