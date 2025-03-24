part of 'auth_bloc_bloc.dart';

abstract class AuthBlocState extends Equatable {
  const AuthBlocState();
  
  @override
  List<Object?> get props => [];
}

class AuthBlocInitial extends AuthBlocState {}

class AuthBlocLoading extends AuthBlocState {}

class AuthBlocAuthenticated extends AuthBlocState {
  final User? user; // Making user nullable to handle nullable User object

  const AuthBlocAuthenticated({this.user}); // Constructor can accept nullable user
  
  @override
  List<Object?> get props => [user]; // Compare user (nullable)
}

class AuthBlocUnAuthenticated extends AuthBlocState {}

class AuthBlocSignedOut extends AuthBlocState {}

class AuthBlocError extends AuthBlocState {
  final String message;

  const AuthBlocError({required this.message});

  @override
  List<Object?> get props => [message];
}
