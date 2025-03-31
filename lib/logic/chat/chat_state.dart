import 'package:equatable/equatable.dart';
import 'package:flutter_application_1/data/models/chat_message_model.dart';

enum ChatStatus {
  initial,
  loading,
  loaded,
  error,
}

class ChatState extends Equatable {
  
  final ChatStatus status;
  final String? error;
  final String? receiverId;
  final String? chatRoomId; // chatRoomId is optional
  final List<ChatMessage> messages ; 

  const ChatState({
    this.status = ChatStatus.initial,
    this.error,
    this.receiverId,
    this.chatRoomId, // No need to require chatRoomId
    this.messages = const []
  });

  @override
  List<Object?> get props => [status, error, receiverId, chatRoomId , messages ];

  // Updated copyWith method to handle optional chatRoomId
  ChatState copyWith({
    ChatStatus? status,
    String? error,
    String? receiverId,
    String? chatRoomId, // Make chatRoomId nullable
    List<ChatMessage>? messages  

  }) {
    return ChatState(
      status: status ?? this.status,
      error: error ?? this.error,
      receiverId: receiverId ?? this.receiverId,
      chatRoomId: chatRoomId ?? this.chatRoomId, // Use existing value if not provided
      messages : messages?? this.messages
    );
  }
}
