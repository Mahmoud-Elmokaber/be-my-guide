import 'package:app/Pages/settingPage.dart';
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

  String connectionStatus = "Disconnected";
  bool inCall = false;
  bool isMuted = false;
  bool isCameraOff = false;

  String userName = '';
  String userEmail = '';
  List<Map<String, dynamic>> requests = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUserRequests();
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

  void requestAssistance() {
    setState(() {
      inCall = true;
      connectionStatus = "Connecting...";
    });
    _speak("Requesting visual assistance, connecting now");

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        connectionStatus = "Live";
      });
      _speak("Call is live");
    });
  }

  void endCall() {
    setState(() {
      inCall = false;
      connectionStatus = "Disconnected";
      isMuted = false;
      isCameraOff = false;
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
    _speak("Opening settings");
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
          child: const Text("SeeTogether", style: TextStyle(fontWeight: FontWeight.bold)),
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
                    Text("You can request visual assistance below.", style: subtitleTextStyle),
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
                  if (inCall) Text(connectionStatus, style: TextStyle(color: highlightColor, fontWeight: FontWeight.bold, fontSize: 18)),
                  if (inCall) const SizedBox(height: 10),
                  if (inCall)
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(child: Text('Volunteer Video', style: TextStyle(color: Colors.grey[400]))),
                    ),
                  if (inCall) const SizedBox(height: 10),
                  if (inCall)
                    Container(
                      height: 100,
                      width: 140,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(child: Text('Your Self-View', style: TextStyle(color: Colors.grey[400]))),
                    ),
                  if (inCall) const SizedBox(height: 10),
                  if (inCall)
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
                  if (!inCall)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(60),
                        backgroundColor: highlightColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: requestAssistance,
                      child: Column(
                        children: const [
                          Text("Request Visual Assistance", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,color: Colors.white)),
                          SizedBox(height: 4),
                          Text("Call a volunteer now", style: TextStyle(fontSize: 14 ,color: Colors.white)),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            if (!inCall) ...[
              const SizedBox(height: 30),
              Semantics(
                container: true,
                label: 'Your active and past assistance requests',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Your Requests", style: headerTextStyle),
                    const SizedBox(height: 12),
                    if (requests.isEmpty)
                      Text("No requests yet.", style: subtitleTextStyle)
                    else
                      ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: requests.length,
                        separatorBuilder: (_, __) => const Divider(color: Colors.grey),
                        itemBuilder: (context, index) {
                          final req = requests[index];
                          return Semantics(
                            label: 'Request with volunteer ${req["volunteerName"]}, status: ${req["status"]}',
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.grey[700],
                                backgroundImage: req["volunteerPhoto"] != null ? NetworkImage(req["volunteerPhoto"]) : null,
                                child: req["volunteerPhoto"] == null
                                    ? Text(req["volunteerName"].toString().substring(0, 1).toUpperCase(), style: TextStyle(color: Colors.grey[300], fontWeight: FontWeight.bold))
                                    : null,
                              ),
                              title: Text(req["volunteerName"], style: TextStyle(color: Colors.grey[100], fontWeight: FontWeight.w600)),
                              subtitle: Text("Status: ${req["status"]}", style: TextStyle(color: Colors.grey[400])),
                              trailing: Text(_formatTimestamp(req["timestamp"]), style: TextStyle(color: Colors.grey[400])),
                              onTap: () => _speak("Request with volunteer ${req["volunteerName"]}, status ${req["status"]}"),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ],
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
