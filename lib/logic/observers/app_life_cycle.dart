import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/repo/chat_repo.dart';

class AppLifeCycle extends WidgetsBindingObserver {
  final String userId;
  final ChatRepo chatrepo;

  AppLifeCycle({required this.userId, required this.chatrepo});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        chatrepo.updateOnlineStatus(userId, false);
        break;
      case AppLifecycleState.resumed:
        chatrepo.updateOnlineStatus(userId, true);
      default : 
        break ;
    }
  }
}
