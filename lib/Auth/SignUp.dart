import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Components/CustomTextFormField.dart';
import 'login.dart';

class SignUp extends StatefulWidget {
  final String userType;
  const SignUp({super.key, required this.userType});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController firstName = TextEditingController();
  final TextEditingController lastName = TextEditingController();

  final FocusNode firstNameFocus = FocusNode();
  final FocusNode lastNameFocus = FocusNode();
  final FocusNode emailFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();

  final FlutterTts flutterTts = FlutterTts();

  GlobalKey<FormState> formKey = GlobalKey();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    flutterTts.awaitSpeakCompletion(true);

    // جملة ترحيبية عند فتح الصفحة
    flutterTts.speak("Welcome to Sign Up page. Please enter your information.");

    // Focus listeners لكل حقل
    firstNameFocus.addListener(() {
      if (firstNameFocus.hasFocus) flutterTts.speak("First Name input field");
    });
    lastNameFocus.addListener(() {
      if (lastNameFocus.hasFocus) flutterTts.speak("Last Name input field");
    });
    emailFocus.addListener(() {
      if (emailFocus.hasFocus) flutterTts.speak("Email input field");
    });
    passwordFocus.addListener(() {
      if (passwordFocus.hasFocus) flutterTts.speak("Password input field");
    });
  }

  @override
  void dispose() {
    firstNameFocus.dispose();
    lastNameFocus.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              children: [
                const SizedBox(height: 40),
                Semantics(
                  header: true,
                  label: "Create a new account",
                  child: const Text(
                    "Get started",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                Semantics(
                  label: "Enter your personal information",
                  child: const Text(
                    "Enter Your Personal Information",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 20),
                Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // First Name
                      const Text(
                        "First name",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Customtextformfield(
                        hintext: "Enter your first name",
                        obscuretext: false,
                        myController: firstName,
                        focusNode: firstNameFocus,
                        flutterTts: flutterTts,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            flutterTts.speak("Please enter your first name");
                            return "Please enter your first name";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Last Name
                      const Text(
                        "Last name",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Customtextformfield(
                        hintext: "Enter your last name",
                        obscuretext: false,
                        myController: lastName,
                        focusNode: lastNameFocus,
                        flutterTts: flutterTts,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            flutterTts.speak("Please enter your last name");
                            return "Please enter your last name";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Email
                      const Text(
                        "Email",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Customtextformfield(
                        hintext: "Enter your email",
                        obscuretext: false,
                        myController: email,
                        focusNode: emailFocus,
                        flutterTts: flutterTts,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            flutterTts.speak("Please enter your email");
                            return "Please enter your email";
                          }
                          if (!val.contains('@')) {
                            flutterTts.speak("Please enter a valid email");
                            return "Please enter a valid email";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Password
                      const Text(
                        "Password",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Customtextformfield(
                        hintext: "Enter your password",
                        obscuretext: true,
                        myController: password,
                        focusNode: passwordFocus,
                        flutterTts: flutterTts,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            flutterTts.speak("Please enter your password");
                            return "Please enter your password";
                          }
                          if (val.length < 6) {
                            flutterTts.speak(
                                "Password must be at least 6 characters");
                            return "Password must be at least 6 characters";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),

                      // Sign Up Button
                      Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              minimumSize: const Size(200, 50)),
                          onPressed: () async {
                            // تحقق من صحة الفورم
                            if (!formKey.currentState!.validate()) {
                              return; // الرسائل الصوتية قرأها الـ validator
                            }

                            await flutterTts.stop();
                            flutterTts.speak("Creating your account");

                            setState(() => isLoading = true);

                            try {
                              await FirebaseAuth.instance
                                  .createUserWithEmailAndPassword(
                                      email: email.text,
                                      password: password.text);

                              String uid =
                                  FirebaseAuth.instance.currentUser!.uid;

                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(uid)
                                  .set({
                                "firstName": firstName.text,
                                "lastName": lastName.text,
                                "email": email.text,
                                "userType": widget.userType,
                                
                                "createdAt": FieldValue.serverTimestamp(),
                              });

                              setState(() => isLoading = false);

                              if (widget.userType == 'user') {
                                Navigator.of(context)
                                    .pushReplacementNamed('userHome');
                              } else {
                                Navigator.of(context)
                                    .pushReplacementNamed('volunteerHome');
                              }
                            } on FirebaseAuthException catch (e) {
                              setState(() => isLoading = false);
                              flutterTts.speak(e.message ?? "Error occurred");
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        e.message ?? "Error occurred")),
                              );
                            }
                          },
                          child: const Text(
                            "Next",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Go to Login
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Have an account?",
                            style: TextStyle(
                                color: Color.fromARGB(255, 165, 177, 182),
                                fontSize: 16),
                          ),
                          const SizedBox(width: 5),
                          InkWell(
                            onTap: () async {
                              await flutterTts.stop();
                              flutterTts.speak("Going to login screen");
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      Login(userType: widget.userType),
                                ),
                              );
                            },
                            child: const Text(
                              "Login",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
