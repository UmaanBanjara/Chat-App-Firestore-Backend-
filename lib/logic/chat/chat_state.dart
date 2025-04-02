import 'package:cloud_firestore/cloud_firestore.dart';
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
  final String? chatRoomId;
  final List<ChatMessage> messages;
  final bool isreceiverTyping;
  final bool isreceiverOnline;
  final Timestamp? receiverlaseseen;
  final bool hasmoremessages;
  final bool isloadingmore;
  final bool isuserblocked;
  final bool amiblocked;

  const ChatState({
    this.status = ChatStatus.initial,
    this.error,
    this.receiverId,
    this.chatRoomId,
    this.messages = const [],
    this.isreceiverTyping = false,
    this.isreceiverOnline = false,
    this.receiverlaseseen,
    this.hasmoremessages = true,
    this.isloadingmore = false,
    this.isuserblocked = false,
    this.amiblocked = false,
  });

  @override
  List<Object?> get props => [
        status,
        error,
        receiverId,
        chatRoomId,
        messages,
        isreceiverTyping,
        isreceiverOnline,
        receiverlaseseen,
        hasmoremessages,
        isloadingmore,
        isuserblocked,
        amiblocked,
      ];

  // Updated copyWith method to handle optional fields properly
  ChatState copyWith({
    ChatStatus? status,
    String? error,
    String? receiverId,
    String? chatRoomId,
    List<ChatMessage>? messages,
    bool? isreceiverTyping,
    bool? isreceiverOnline,
    Timestamp? receiverlaseseen,
    bool? hasmoremessages,
    bool? isloadingmore,
    bool? isuserblocked,
    bool? amiblocked,
  }) {
    return ChatState(
      status: status ?? this.status,
      error: error ?? this.error,
      receiverId: receiverId ?? this.receiverId,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      messages: messages ?? this.messages,
      isreceiverTyping: isreceiverTyping ?? this.isreceiverTyping,
      isreceiverOnline: isreceiverOnline ?? this.isreceiverOnline,
      receiverlaseseen: receiverlaseseen ?? this.receiverlaseseen,
      hasmoremessages: hasmoremessages ?? this.hasmoremessages,
      isloadingmore: isloadingmore ?? this.isloadingmore,
      isuserblocked: isuserblocked ?? this.isuserblocked,
      amiblocked: amiblocked ?? this.amiblocked,
    );
  }
}
