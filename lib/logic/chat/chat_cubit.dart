import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/data/repo/chat_repo.dart';
import 'package:flutter_application_1/logic/chat/chat_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepo _chatRepository;
  final String currentUserId;
  bool _isInChat = false;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _onlineStatusSubscription;
  StreamSubscription? _typingSubscription;
  Timer? typingTimer;
  StreamSubscription? _blocksubscription ; 
  StreamSubscription? _amiblocksubscription ; 


  // Constructor to initialize the ChatCubit with the repository and current user ID
  ChatCubit({
    required ChatRepo chatRepository,
    required this.currentUserId,
  })  : _chatRepository = chatRepository,
        super(ChatState(
          status: ChatStatus.initial,
          receiverId: currentUserId,
          chatRoomId: '',
        ));

  // Method to enter a chat room
  void enterChat(String receiverId) async {
    _isInChat = true;
    emit(state.copyWith(status: ChatStatus.loading));

    try {
      final chatRoom =
          await _chatRepository.getOrcreateChatRoom(currentUserId, receiverId);

      // Emit updated state with the created chat room and receiver ID
      emit(state.copyWith(
        status: ChatStatus.loaded,
        chatRoomId: chatRoom.id,
        receiverId: receiverId,
      ));

      // Subscribe to messages, online status, and typing status
      _subscribeToMessages(chatRoom.id);
      _subscribeToOnlineStatus(receiverId);
      _subscribeToTypingStatus(chatRoom.id);
      _subscribeToBlockStatus(receiverId);
    } catch (e) {
      // Emit error state if chat room creation fails
      emit(state.copyWith(
        status: ChatStatus.error,
        error: "Failed to create chat room: ${e.toString()}",
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
      emit(state.copyWith(error: "Failed to send message: $e"));
    }
  }

  // Subscribe to new messages in the chat room
  void _subscribeToMessages(String chatRoomId) {
    _messageSubscription?.cancel();

    _messageSubscription =
        _chatRepository.getMessages(chatRoomId).listen((messages) {
      if (_isInChat) {
        _markMessagesAsRead(chatRoomId);
      }
      emit(state.copyWith(messages: messages, error: null));
    }, onError: (error) {
      emit(state.copyWith(
          error: "Failed to load messages", status: ChatStatus.error));
    });
  }

  // Mark messages as read after they are received
  Future<void> _markMessagesAsRead(String chatRoomId) async {
    try {
      await _chatRepository.markMessagesAsRead(chatRoomId, currentUserId);
    } catch (e) {
      print("Error marking messages as read: $e");
    }
  }

  // Method to leave the chat
  Future<void> leaveChat() async {
    _isInChat = false;
  }

  // Subscribe to the online status of the receiver
  void _subscribeToOnlineStatus(String userId) {
    _onlineStatusSubscription?.cancel();
    _onlineStatusSubscription =
        _chatRepository.getUserOnlineStatus(userId).listen((status) {
      final isOnline = status["isOnline"] as bool;
      final lastSeen = status["lastSeen"] as Timestamp;

      emit(state.copyWith(isreceiverOnline: isOnline, receiverlaseseen: lastSeen));
    }, onError: (error) {
      print("Error getting online status: $error");
    });
  }

  // Subscribe to the typing status in the chat room
  void _subscribeToTypingStatus(String chatRoomId) {
    _typingSubscription?.cancel();
    _typingSubscription =
        _chatRepository.getTypingStatus(chatRoomId).listen((status) {
      final isTyping = status["isTyping"] as bool;
      final typingUserId = status["typingUserId"] as String;

      emit(state.copyWith(
          isreceiverTyping: isTyping && typingUserId != currentUserId));
    }, onError: (error) {
      print("Error getting typing status: $error");
    });
  }

  // Start typing in the chat room
  void startTyping() {
    if (state.chatRoomId == null) return;

    typingTimer?.cancel();
    _updateTypingStatus(true);
    typingTimer = Timer(Duration(seconds: 3), () {
      _updateTypingStatus(false);
    });
  }

  // Update the typing status of the user in the chat room
  Future<void> _updateTypingStatus(bool isTyping) async {
    if (state.chatRoomId == null) return;

    try {
      await _chatRepository.updateTypingStatus(
          state.chatRoomId!, currentUserId, isTyping);
    } catch (e) {
      print("Error updating typing status: $e");
    }
  }

  // Block a user
  Future<void> blockUser(String userId) async {
    try {
      await _chatRepository.blockUser(currentUserId, userId);
    } catch (e) {
      emit(state.copyWith(error: "Failed to block user: $e"));
    }
  }

  // Unblock a user (Fixed)
  Future<void> unblockUser(String userId) async {
    try {
      // Call the repository method to unblock the user
      await _chatRepository.unblockUser(currentUserId, userId);

      // Optionally, update the state after unblocking (if needed)
      emit(state.copyWith(status: ChatStatus.loaded));
    } catch (e) {
      // Emit an error state if the unblock action fails
      emit(state.copyWith(error: "Failed to unblock user: $e"));
    }
  }

  // Cleanup all subscriptions and timers when the cubit is closed
  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _onlineStatusSubscription?.cancel();
    _typingSubscription?.cancel();
    typingTimer?.cancel();
    return super.close();
  }




void _subscribeToBlockStatus(String otherUserId) {
    _blocksubscription?.cancel();
    _blocksubscription =
        _chatRepository.isUserBloked(currentUserId , otherUserId).listen((isBlocked) {


      emit(state.copyWith(
          isuserblocked: isBlocked  )) ; 

  _amiblocksubscription?.cancel() ;
  _amiblocksubscription = _chatRepository.amIBloked(currentUserId, otherUserId).listen((isBlocked){
    emit(state.copyWith(amiblocked: isBlocked));
  });
    }, onError: (error) {
      print("Error getting typing status: $error");
    });
  }







Future<void> loadmoremessages()async{

  if(state.status != ChatStatus.loaded || state.messages.isEmpty || !state.hasmoremessages || state.isloadingmore)return ; 

  try{
    emit(state.copyWith(isloadingmore: true));
    final lastmessage = state.messages.last;
    final lastDoc = await _chatRepository.getChatRoomMessages(state.chatRoomId!).doc(lastmessage.id).get();

    final moremessages = await _chatRepository.getMoreMessages(state.chatRoomId!, lastDocument: lastDoc) ; 
    if(moremessages.isEmpty){
      emit(state.copyWith(hasmoremessages: false , isloadingmore: false , )) ; 
      return ; 
    }

    emit(state.copyWith(
      messages: [...state.messages , ...moremessages] , 
      hasmoremessages: moremessages.length>=20 , 
      isloadingmore: false ,
    ) , 
    );
  }catch(e){
    emit(state.copyWith(error: "Failed to load more messages " , isloadingmore: false)) ; 

  }
}











}
