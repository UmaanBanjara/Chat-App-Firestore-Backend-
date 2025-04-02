import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/repo/auth_repo.dart';
import 'package:flutter_application_1/data/repo/chat_repo.dart';
import 'package:flutter_application_1/data/repo/contact_repo.dart';
import 'package:flutter_application_1/firebase_options.dart';
import 'package:flutter_application_1/logic/bloc/auth_bloc_bloc.dart';
import 'package:flutter_application_1/logic/chat/chat_cubit.dart';
import 'package:flutter_application_1/router/app_router.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  getIt.registerLazySingleton(() => AppRouter());
  getIt.registerLazySingleton<FirebaseFirestore>(
      () => FirebaseFirestore.instance);
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getIt.registerLazySingleton(() => AuthRepository());
  getIt.registerLazySingleton(() => ContactRepository());
  getIt.registerLazySingleton(() => AuthBlocBloc());
  getIt.registerFactory(() => ChatCubit(chatRepository: ChatRepo()  , currentUserId: getIt<FirebaseAuth>().currentUser!.uid)) ; 
  getIt.registerLazySingleton(() => ChatRepo());  
}