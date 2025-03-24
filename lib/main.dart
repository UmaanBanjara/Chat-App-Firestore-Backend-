import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/theme/app_theme.dart';
import 'package:flutter_application_1/data/service/service_locator.dart';
import 'package:flutter_application_1/firebase_options.dart';
import 'package:flutter_application_1/logic/bloc/auth_bloc_bloc.dart';
import 'package:flutter_application_1/presentation/screens/auth/login_screen.dart';
import 'package:flutter_application_1/presentation/screens/home_screen.dart';
import 'package:flutter_application_1/router/app_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  // Ensure that Firebase is initialized before running the app
  WidgetsFlutterBinding.ensureInitialized();
  await setupServiceLocator(); // Initialize service locator
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Firebase initialization with platform-specific settings
  );
  
  // Run the app after Firebase initialization
  runApp(ChatApp());
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBlocBloc>(
      create: (context) => AuthBlocBloc(), // Provide the AuthBloc to the widget tree
      child: MaterialApp(
        navigatorKey: getIt<AppRouter>().navigatorKey, // Set up the app router for navigation
        debugShowCheckedModeBanner: false, // Disable the debug banner
        title: 'Chat App', // Set the title for the app
        theme: AppTheme.lightTheme, // Apply the light theme for the app

        // StreamBuilder listens to Firebase authentication state
        // It checks if the user is logged in or not and routes accordingly
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(), // Listen to auth state changes (user login/logout)
          builder: (context, snapshot) {
            // Check if Firebase auth state is still loading
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator()); // Show loading spinner while checking auth state
            }
            
            // Check if there is an error while checking auth state
            else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}')); // Show error message if any error occurs
            }

            // If user is logged in (auth state is available), navigate to HomeScreen
            else if (snapshot.hasData) {
              return HomeScreen(); // Navigate to home screen if user is logged in
            } 
            
            // If no user is logged in, show the LoginScreen
            else {
              return LoginScreen(); // Show the login screen if user is not logged in
            }
          },
        ),
      ),
    );
  }
}
