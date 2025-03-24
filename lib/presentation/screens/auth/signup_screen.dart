import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/common/custom_button.dart';
import 'package:flutter_application_1/core/common/custom_textfield.dart';
import 'package:flutter_application_1/data/repo/auth_repo.dart';
import 'package:flutter_application_1/data/service/service_locator.dart';
import 'package:flutter_application_1/presentation/screens/auth/login_screen.dart';
import 'package:flutter_application_1/router/app_router.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formkey = GlobalKey<FormState>();
  final TextEditingController emailcontroller = TextEditingController();
  final TextEditingController passwordcontroller = TextEditingController();
  final TextEditingController namecontroller = TextEditingController();
  final TextEditingController usernamecontroller = TextEditingController();
  final TextEditingController phonecontroller = TextEditingController();

  bool _ispassvisible = false;

  final _namefocus = FocusNode();
  final _emailfocus = FocusNode();
  final _passfocus = FocusNode();
  final _usernamefocus = FocusNode();
  final _phonefocus = FocusNode();

  @override
  void dispose() {
    emailcontroller.dispose();
    passwordcontroller.dispose();
    namecontroller.dispose();
    usernamecontroller.dispose();
    phonecontroller.dispose();
    _namefocus.dispose();
    _emailfocus.dispose();
    _passfocus.dispose();
    _usernamefocus.dispose();
    _phonefocus.dispose();
    super.dispose();
  }

  String? _validatename(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter your full name";
    }
    return null;
  }

  String? _validatemail(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter your email address";
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address (e.g., example@email.com)';
    }
    return null;
  }

  String? _validateusername(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter a username";
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    final phoneRegex = RegExp(r'^\+?[\d\s-]{10,}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number (e.g., +1234567890)';
    }
    return null;
  }

  Future<void> handleSignup() async {
    FocusScope.of(context).unfocus();
    if (_formkey.currentState?.validate() ?? false) {
      try {
        final authRepo = getIt<AuthRepository>();

        // Check if email exists
        bool emailExists = await authRepo.checkEmailExists(emailcontroller.text);
        bool phoneExists = await authRepo.checkPhoneExists(phonecontroller.text.trim());

        if (emailExists && phoneExists) {
          // If both email and phone number exist
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Both the email and phone number are already in use.')),
          );
          return;
        }

        if (emailExists) {
          // If only the email exists
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('This email is already in use.')),
          );
          return;
        }

        if (phoneExists) {
          // If only the phone number exists
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('This phone number is already in use.')),
          );
          return;
        }

        // If both checks pass, proceed with sign-up
        await authRepo.signUp(
          fullName: namecontroller.text,
          username: usernamecontroller.text,
          email: emailcontroller.text,
          phoneNumber: phonecontroller.text,
          password: passwordcontroller.text,
        );

        // Navigate to Login Screen after successful sign-up
        getIt<AppRouter>().pushReplacement(LoginScreen());
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } else {
      print("Form Validation Failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Form(
          key: _formkey,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 7),
                Text(
                  "Create Account",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  "Please Fill up the fields",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                ),
                SizedBox(height: 25),
                CustomTextField(
                  controller: namecontroller,
                  hintText: "Full Name",
                  prefixIcon: Icon(Icons.person_outline_outlined),
                  focusNode: _namefocus,
                  validator: _validatename,
                ),
                SizedBox(height: 25),
                CustomTextField(
                  controller: usernamecontroller,
                  hintText: "User Name",
                  prefixIcon: Icon(Icons.alternate_email_outlined),
                  focusNode: _usernamefocus,
                  validator: _validateusername,
                ),
                SizedBox(height: 25),
                CustomTextField(
                  controller: emailcontroller,
                  hintText: "Email",
                  prefixIcon: Icon(Icons.mail_lock_outlined),
                  focusNode: _emailfocus,
                  validator: _validatemail,
                ),
                SizedBox(height: 25),
                CustomTextField(
                  controller: phonecontroller,
                  hintText: "Phone Number",
                  prefixIcon: Icon(Icons.phone_android),
                  focusNode: _phonefocus,
                  validator: _validatePhone,
                ),
                SizedBox(height: 25),
                CustomTextField(
                  controller: passwordcontroller,
                  hintText: "Password",
                  prefixIcon: Icon(Icons.lock_outline),
                  obscureText: _ispassvisible,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _ispassvisible = !_ispassvisible;
                      });
                    },
                    icon: Icon(_ispassvisible ? Icons.visibility_off : Icons.visibility),
                  ),
                  focusNode: _passfocus,
                  validator: _validatePassword,
                ),
                SizedBox(height: 35),
                CustomButton(
                  onPressed: handleSignup,
                  text: "Create Account",
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                    ),
                    SizedBox(width: 3),
                    GestureDetector(
                      onTap: () {
                        getIt<AppRouter>().push(LoginScreen());
                      },
                      child: Text(
                        "Login",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
