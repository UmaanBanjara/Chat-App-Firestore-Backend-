import 'package:flutter/material.dart';

class ChatMessageScreen extends StatefulWidget {
  final String receiverId ; 
  final String receiverName ; 

  const ChatMessageScreen({super.key, required this.receiverId, required this.receiverName});

  @override
  State<ChatMessageScreen> createState() => _ChatMessageScreenState();
}

class _ChatMessageScreenState extends State<ChatMessageScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
    );
  }
}