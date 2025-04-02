import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/theme/app_theme.dart';
import 'package:flutter_application_1/data/repo/chat_repo.dart';
import 'package:flutter_application_1/data/service/service_locator.dart';
import 'package:flutter_application_1/firebase_options.dart';
import 'package:flutter_application_1/logic/bloc/auth_bloc_bloc.dart';
import 'package:flutter_application_1/logic/observers/app_life_cycle.dart';
import 'package:flutter_application_1/presentation/screens/auth/login_screen.dart';
import 'package:flutter_application_1/presentation/screens/home_screen.dart';
import 'package:flutter_application_1/router/app_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter bindings are initialized before running the app
  await setupServiceLocator(); // Initialize service locator for dependency injection
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Initialize Firebase with platform-specific settings
  );

  runApp(const ChatApp()); // Start the app
}

class ChatApp extends StatefulWidget {
  const ChatApp({super.key});

  @override
  State<ChatApp> createState() => _ChatAppState();
}

class _ChatAppState extends State<ChatApp> {
  late final AppLifeCycle _lifecycleObserver; // Lifecycle observer to track app states

  @override
  void initState() {
    super.initState();
    
    // Initialize observer with an empty user ID initially
    _lifecycleObserver = AppLifeCycle(userId: '', chatrepo: getIt<ChatRepo>());
    WidgetsBinding.instance.addObserver(_lifecycleObserver); // Add observer to track app lifecycle

    // Listen to authentication state changes using AuthBloc
    getIt<AuthBlocBloc>().stream.listen((state) {
      if (state is AuthBlocAuthenticated && state.user != null) {
        _lifecycleObserver = AppLifeCycle(userId: state.user!.uid, chatrepo: getIt<ChatRepo>());
      } 

      WidgetsBinding.instance.addObserver(_lifecycleObserver);
    });
  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver); // Remove observer to prevent memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBlocBloc>(
      create: (context) => AuthBlocBloc(), // Provide authentication BLoC to the widget tree
      child: GestureDetector(
        onTap : (){
          FocusManager.instance.primaryFocus?.unfocus();
        } ,
        child: MaterialApp(
          navigatorKey: getIt<AppRouter>().navigatorKey, // Set up navigation handling
          debugShowCheckedModeBanner: false, // Hide the debug banner
          title: 'Chat App', // Set application title
          theme: AppTheme.lightTheme, // Apply light theme
          
          // Listen to Firebase authentication state changes
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator()); // Show a loading spinner if still fetching auth state
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}')); // Show error if there was an issue with auth state retrieval
              } else if (snapshot.hasData) {
                return const HomeScreen(); // Navigate to home screen if user is logged in
              } else {
                return const LoginScreen(); // Show login screen if no user is logged in
              }
            },
          ),
        ),
      ),
    );
  }
}
