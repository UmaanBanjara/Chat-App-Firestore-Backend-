import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'auth_bloc_event.dart';
part 'auth_bloc_state.dart';

class AuthBlocBloc extends Bloc<AuthBlocEvent, AuthBlocState> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  AuthBlocBloc() : super(AuthBlocInitial()) {
    on<LoginRequest>((event, emit) async {
      try {
        emit(AuthBlocLoading()); // Show loading state..
        
        // Attempt login with email and password
        UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
          email: event.email, 
          password: event.password,
        );

        // If login is successful, emit AuthBlocAuthenticated with user details
        emit(AuthBlocAuthenticated(user: userCredential.user)); // Pass user details to state
      } on FirebaseAuthException catch (e) {
        emit(AuthBlocError(message: e.message ?? "Failed to Login, TRY AGAIN"));
      }
    });

    on<SignupRequest>((event, emit) async {
      try {
        emit(AuthBlocLoading()); // Emit loading state during signup

        // Attempt to sign up the user with email and password
        UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: event.email,
          password: event.password,
        );

        // If signup is successful, emit AuthBlocAuthenticated with user details
        emit(AuthBlocAuthenticated(user: userCredential.user)); 
      } on FirebaseAuthException catch (e) {
        emit(AuthBlocError(message: e.message ?? "Failure, TRY AGAIN"));
      }
    });

    on<SignOutuser>((event, emit) async {
      try {
        emit(AuthBlocLoading()); // Emit loading state while signing out
        await _firebaseAuth.signOut(); // Firebase sign out

        // After sign-out, emit the signed-out state
        emit(AuthBlocSignedOut());
      } on FirebaseAuthException catch (e) {
        emit(AuthBlocError(message: e.message ?? "Failed to Sign Out, TRY AGAIN"));
      }
    });
  }
}
