import 'dart:async';
import 'package:flutter_application_1/data/repo/chat_repo.dart';
import 'package:flutter_application_1/logic/chat/chat_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepo _chatRepository;
  final String currentUserId;
  StreamSubscription? _messageSubscription;

  // Constructor
  ChatCubit({
    required ChatRepo chatRepository,
    required this.currentUserId,
  })  : _chatRepository = chatRepository,
        super(ChatState(
          status: ChatStatus.initial,  // Initialize status as 'initial'
          receiverId: currentUserId,   // Set receiverId to currentUserId initially
          chatRoomId: '',              // Initialize chatRoomId as empty string or null
        ));

  // Method to enter a chat room
  void enterChat(String receiverId) async {
    emit(state.copyWith(status: ChatStatus.loading)); // Emit loading state without chatRoomId

    try {
      final chatRoom = await _chatRepository.getOrcreateChatRoom(currentUserId, receiverId);

      // Emit loaded state with chatRoomId and receiverId
      emit(state.copyWith(
        status: ChatStatus.loaded,  // Change status to loaded
        chatRoomId: chatRoom.id,    // Set chatRoomId to the ID of the chatRoom
        receiverId: receiverId,    // Set receiverId to the passed receiverId
      ));

      // After loading the chat room, subscribe to its messages
      _subscribeToMessages(chatRoom.id);
    } catch (e) {
      // Emit error state with a meaningful error message
      emit(state.copyWith(
        status: ChatStatus.error,
        error: "Failed to create chat room: ${e.toString()}", // More informative error message
      ));
    }
  }

  // Method to send a message
  Future<void> sendMessage({
    required String content,
    required String receiverId,
  }) async {
    if (state.chatRoomId == null || state.chatRoomId!.isEmpty) return;

    try {
      await _chatRepository.sendMessage(
        chatRoomId: state.chatRoomId!,
        senderId: currentUserId,
        receiverId: receiverId,
        content: content,
      );
    } catch (e) {
      emit(state.copyWith(error: "Failed to send message $e"));
    }
  }

  // Method to subscribe to new messages in the chat room
  void _subscribeToMessages(String chatRoomId) {
    // Cancel any previous subscription
    _messageSubscription?.cancel();

    // Subscribe to new messages from the chat room
    _messageSubscription = _chatRepository.getMessages(chatRoomId).listen((messages) {
      // Emit new messages in the state
      emit(state.copyWith(messages: messages, error: null));
    } , onError: (error){
      emit(state.copyWith(error: "Failed to load messages " , status: ChatStatus.error));
    });
  }

  // Method to clean up the subscription when no longer needed
  @override
  Future<void> close() {
    _messageSubscription?.cancel(); // Cancel the subscription when the Cubit is closed
    return super.close();
  }
}
