import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/common/custom_button.dart';
import 'package:flutter_application_1/core/common/custom_textfield.dart';
import 'package:flutter_application_1/data/service/service_locator.dart';
import 'package:flutter_application_1/logic/bloc/auth_bloc_bloc.dart';
import 'package:flutter_application_1/presentation/screens/auth/signup_screen.dart';
import 'package:flutter_application_1/presentation/screens/home_screen.dart';
import 'package:flutter_application_1/router/app_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formkey = GlobalKey<FormState>();
  final TextEditingController emailcontroller = TextEditingController();
  final TextEditingController passwordcontroller = TextEditingController();
  final _emailfocus = FocusNode();
  final _passfocus = FocusNode();

  bool _passvisible = false;

  @override
  void dispose() {
    emailcontroller.dispose();
    passwordcontroller.dispose();
    _emailfocus.dispose();
    _passfocus.dispose();
    super.dispose();
  }

  // Validate email address
  String? _validatemail(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter your email address ";
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address (e.g., example@email.com)';
    }
    return null;
  }

  // Validate password
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  // Handle the login request asynchronously
  Future<void> _handleLogin() async {
    if (_formkey.currentState?.validate() ?? false) {
      try {
        // Unfocus text fields before attempting login
        FocusScope.of(context).unfocus();

        // Start Firebase authentication
        final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailcontroller.text,
          password: passwordcontroller.text,
        );

        // Check if login is successful and navigate to HomeScreen
        if (userCredential.user != null) {
          // Login successful, navigate to home screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        }
      } catch (e) {
        // Handle any errors during the login process
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Login Failed: ${e.toString()}")));
        print("Login error: ${e.toString()}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<AuthBlocBloc>(), // Provide AuthBloc to the widget tree
      child: Scaffold(
        body: SafeArea(
          child: Form(
            key: _formkey,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 30),
                  Padding(
                    padding: EdgeInsets.only(left: 7),
                    child: Text(
                      "Welcome Back",
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding: EdgeInsets.only(left: 7),
                    child: Text(
                      "Sign in to continue",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                    ),
                  ),
                  SizedBox(height: 40),

                  // Email input field
                  CustomTextField(
                    controller: emailcontroller,
                    hintText: "Enter your email",
                    prefixIcon: Icon(Icons.email_outlined),
                    focusNode: _emailfocus,
                    validator: _validatemail,
                  ),
                  SizedBox(height: 20),

                  // Password input field
                  CustomTextField(
                    controller: passwordcontroller,
                    hintText: "Enter your password",
                    obscureText: !_passvisible,
                    prefixIcon: Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _passvisible = !_passvisible;
                        });
                      },
                      icon: Icon(_passvisible ? Icons.visibility_off : Icons.visibility),
                    ),
                    focusNode: _passfocus,
                    validator: _validatePassword,
                  ),
                  SizedBox(height: 20),

                  // Forgot password text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text("forgot password?", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  SizedBox(height: 40),

                  // BlocListener listens to changes in the AuthBloc state
                  BlocListener<AuthBlocBloc, AuthBlocState>(
                    listener: (context, state) {
                      // Handle error state
                      if (state is AuthBlocError) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
                      }

                      // On successful authentication, navigate to HomeScreen
                      if (state is AuthBlocAuthenticated) {
                        debugPrint("Authentication successful!");
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => HomeScreen()),
                        );
                      }
                    },
                    child: BlocBuilder<AuthBlocBloc, AuthBlocState>(
                      builder: (context, state) {
                        // Show loading indicator when the state is AuthBlocLoading
                        if (state is AuthBlocLoading) {
                          return Center(child: CircularProgressIndicator());
                        }

                        // Login button
                        return CustomButton(
                          onPressed: state is AuthBlocLoading ? null : _handleLogin,  // Disable button if loading
                          text: "Login",
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 20),

                  // Signup navigation text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                      ),
                      SizedBox(width: 3),
                      GestureDetector(
                        onTap: () {
                          // Navigate to the signup screen
                          getIt<AppRouter>().push(SignupScreen());
                        },
                        child: Text(
                          "Signup",
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
