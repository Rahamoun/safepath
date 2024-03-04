import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase/reusable_widgets/reusable_widget.dart';
import 'package:firebase/screens/reset_password.dart';
import 'package:firebase/screens/signup_screen.dart';
import 'package:firebase/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:firebase/Views/map.dart';
import 'package:firebase/Views/suivi.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  TextEditingController _passwordTextController = TextEditingController();
  TextEditingController _emailTextController = TextEditingController();
  String?
      selectedUserType; // Variable pour stocker le type d'utilisateur sélectionné

  String? errorMessage; // Message d'erreur

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              hexStringToColor("CB2B93"),
              hexStringToColor("9546C4"),
              hexStringToColor("5E61F4")
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).size.height * 0.2,
              20,
              0,
            ),
            child: Column(
              children: <Widget>[
                logoWidget("assets/images/logo1.png"),
                const SizedBox(
                  height: 30,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Radio<String>(
                      value: 'malvoyant',
                      groupValue: selectedUserType,
                      onChanged: (String? value) {
                        setState(() {
                          selectedUserType = value;
                        });
                      },
                    ),
                    const Text('Malvoyant'),
                    Radio<String>(
                      value: 'accompagnant',
                      groupValue: selectedUserType,
                      onChanged: (String? value) {
                        setState(() {
                          selectedUserType = value;
                        });
                      },
                    ),
                    const Text('Accompagnant'),
                  ],
                ),
                errorMessage != null
                    ? Text(
                        errorMessage!,
                        style: TextStyle(color: Colors.red),
                      )
                    : SizedBox(),
                const SizedBox(
                  height: 20,
                ),
                reusableTextField(
                  "UserName",
                  Icons.person_outline,
                  false,
                  _emailTextController,
                ),
                const SizedBox(
                  height: 20,
                ),
                reusableTextField(
                  "Password",
                  Icons.lock_outline,
                  true,
                  _passwordTextController,
                ),
                const SizedBox(
                  height: 5,
                ),
                forgetPassword(context),
                ElevatedButton(
                  onPressed: () {
                    if (selectedUserType != null) {
                      FirebaseAuth.instance
                          .signInWithEmailAndPassword(
                        email: _emailTextController.text,
                        password: _passwordTextController.text,
                      )
                          .then((value) {
                        if (selectedUserType == 'malvoyant') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => MyHomePage()),
                          );
                        } else if (selectedUserType == 'accompagnant') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SuiviPage()),
                          );
                        }
                      }).catchError((error) {
                        setState(() {
                          errorMessage = "Invalid email or password";
                        });
                      });
                    } else {
                      setState(() {
                        errorMessage = "Please select user type";
                      });
                    }
                  },
                  child: Text("Sign In"),
                ),
                signUpOption(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget signUpOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Don't have account?",
          style: TextStyle(color: Colors.white70),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SignUpScreen()),
            );
          },
          child: const Text(
            " Sign Up",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        )
      ],
    );
  }

  Widget forgetPassword(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 35,
      alignment: Alignment.bottomRight,
      child: TextButton(
        child: const Text(
          "Forgot Password?",
          style: TextStyle(color: Colors.white70),
          textAlign: TextAlign.right,
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ResetPassword()),
        ),
      ),
    );
  }
}
