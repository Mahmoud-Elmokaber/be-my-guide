import 'package:app/Pages/UserHome.dart';
import 'package:app/Pages/VolunteerHome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Components/CustomTextFormField.dart';
import '../Components/CustomIcon.dart';


class Login extends StatefulWidget {
  final String userType;
  const Login({super.key, required this.userType});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();

  final FocusNode emailFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final FlutterTts flutterTts = FlutterTts();

  bool isLoading = false;
  bool isLoadingWithGoogle = false;

  @override
  void initState() {
    super.initState();

    flutterTts.awaitSpeakCompletion(true);

    // جملة ترحيبية عند فتح الصفحة
    flutterTts.speak("Login page. Please enter your email and password");

    // Focus listeners لكل حقل
    emailFocus.addListener(() {
      if (emailFocus.hasFocus) flutterTts.speak("Email input field");
    });
    passwordFocus.addListener(() {
      if (passwordFocus.hasFocus) flutterTts.speak("Password input field");
    });
  }

  @override
  void dispose() {
    emailFocus.dispose();
    passwordFocus.dispose();
    flutterTts.stop();
    super.dispose();
  }

  // ---------- SIGN IN WITH GOOGLE ----------
  Future<void> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return;

    setState(() => isLoadingWithGoogle = true);
    flutterTts.speak("Signing in with Google");

    final GoogleSignInAuthentication? googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    final user = userCredential.user;
    final uid = user!.uid;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!doc.exists) {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        "firstName": googleUser.displayName?.split(' ').first ?? '',
        "lastName": googleUser.displayName?.split(' ').last ?? '',
        "email": googleUser.email,
        "userType": widget.userType,
        "createdAt": FieldValue.serverTimestamp(),
      });
    }

    setState(() => isLoadingWithGoogle = false);

    final prefs = await SharedPreferences.getInstance();
    final userType = prefs.getString('userType') ?? 'user';
Navigator.of(context).pushAndRemoveUntil(
  MaterialPageRoute(
    builder: (context) => userType == 'user' ? UserHome() : VolunteerHome(),
  ),
  (route) => false,
);
  }

  // ---------- SIGN IN WITH FACEBOOK ----------
  Future<void> signInWithFacebook() async {
    flutterTts.speak("Signing in with Facebook");
    final LoginResult loginResult = await FacebookAuth.instance.login(
      permissions: ['email', 'public_profile'],
    );

    final prefs = await SharedPreferences.getInstance();
    final userType = prefs.getString('userType') ?? 'user';

    if (loginResult.status == LoginStatus.success) {
      final userData = await FacebookAuth.instance.getUserData();
      final OAuthCredential facebookAuthCredential =
          FacebookAuthProvider.credential(loginResult.accessToken!.token);

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(facebookAuthCredential);
      final user = userCredential.user;

      if (user != null) {
        String uid = user.uid;
        String fullName = userData['name'] ?? '';
        List<String> names = fullName.split(' ');
        String firstName = names.isNotEmpty ? names[0] : '';
        String lastName = names.length > 1 ? names.sublist(1).join(' ') : '';
        String email = userData['email'] ?? '';

        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'userType': widget.userType,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      Navigator.of(context).pushReplacementNamed(
        userType == 'user' ? 'userHome' : 'volunteerHome',
      );
    } else {
      flutterTts.speak("Facebook login failed");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Facebook login failed: ${loginResult.message}')),
      );
    }
  }

  // ---------- RESET PASSWORD ----------
  Future<void> resetPassword() async {
    if (email.text.isEmpty) {
      flutterTts.speak("Please enter your email address");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your email address")),
      );
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.text);
      flutterTts.speak("Password reset email sent successfully");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      flutterTts.speak("Error sending password reset email");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  // ---------- LOGIN WITH EMAIL ----------
 Future<void> loginWithEmail() async {
  if (!formKey.currentState!.validate()) return;

  setState(() => isLoading = true);
  await flutterTts.speak("Logging in");

  try {
    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.text.trim(),
      password: password.text,
    );

    final user = credential.user;

    if (user == null) {
      throw FirebaseAuthException(code: 'no-user', message: 'User not found');
    }

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final userType = doc.data()?['userType'] ?? 'user';

    setState(() => isLoading = false);

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      userType == 'user' ? 'userHome' : 'volunteerHome',
      (route) => false,
    );
  } on FirebaseAuthException catch (e) {
    setState(() => isLoading = false);
    await flutterTts.speak(e.message ?? "Login failed");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.message ?? 'Login failed')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: "Login screen",
      child: Scaffold(
        appBar: AppBar(
          title: Semantics(
            label: "Go back",
            button: true,
            child: const Text("Back"),
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 70),
                children: [
                  Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Email field
                        Customtextformfield(
                          hintext: "Enter your email",
                          obscuretext: false,
                          myController: email,
                          focusNode: emailFocus,
                          flutterTts: flutterTts,
                          validator: (val) =>
                              val == null || val.isEmpty ? "Please enter your email" : null,
                        ),
                        const SizedBox(height: 20),

                        // Password field
                        Customtextformfield(
                          hintext: "Enter your password",
                          obscuretext: true,
                          myController: password,
                          focusNode: passwordFocus,
                          flutterTts: flutterTts,
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return "Please enter your password";
                            }
                            if (val.length < 6) {
                              return "Password must be at least 6 characters";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),

                        // Forget password
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: resetPassword,
                            child: const Text(
                              "Forget Password?",
                              style: TextStyle(
                                  color: Color.fromARGB(255, 165, 177, 182),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Login button
                        Center(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(minimumSize: const Size(300, 50)),
                            onPressed: loginWithEmail,
                            child: const Text('Login', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Social login
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Customicon(
                              myIcon: FontAwesomeIcons.facebook,
                              iconColor: Colors.blue.shade700,
                              onPressed: signInWithFacebook,
                            ),
                            const SizedBox(width: 30),
                            Customicon(
                              myIcon: FontAwesomeIcons.google,
                              iconColor: Colors.red,
                              onPressed: isLoadingWithGoogle ? null : signInWithGoogle,
                              isLoading: isLoadingWithGoogle,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
