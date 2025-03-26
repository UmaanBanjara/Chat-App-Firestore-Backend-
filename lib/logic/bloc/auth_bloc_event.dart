    part of 'auth_bloc_bloc.dart';

    abstract class AuthBlocEvent extends Equatable {
      const AuthBlocEvent();

      @override
      List<Object> get props => [];
    }

    class LoginRequest extends AuthBlocEvent {
      final String email; 
      final String password;

      LoginRequest({required this.email, required this.password});

      @override 
      List<Object> get props => [email, password];
    }

    class SignupRequest extends AuthBlocEvent {
      final String email; 
      final String password; 
      final String fullName;

      @override 
      SignupRequest({required this.email, required this.password, required this.fullName});

      List<Object> get props => [email, password, fullName];
    }

    class LogoutRequest extends AuthBlocEvent {}

    class SignOutuser extends AuthBlocEvent {}
