import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/data/models/chat_message_model.dart';
import 'package:flutter_application_1/data/models/chat_room_mode.dart';
import 'package:flutter_application_1/data/models/user_model.dart';
import 'package:flutter_application_1/data/service/base_repo.dart';

class ChatRepo extends BaseRepository {
  CollectionReference get _chatRooms => firestore.collection("chatRooms");

  CollectionReference getChatRoomMessages(String chatRoomId) {
    return _chatRooms.doc(chatRoomId).collection("messages");
  }

  // Create or get an existing chat room
  Future<ChatRoomModel> getOrcreateChatRoom(String currentUserId, String otherUserId) async {
    final users = [currentUserId, otherUserId]..sort();
    final roomId = users.join("_");

    final roomDoc = await _chatRooms.doc(roomId).get();

    if (roomDoc.exists) {
      return ChatRoomModel.fromFirestore(roomDoc);
    }

    final currentUserData = (await firestore.collection("users").doc(currentUserId).get()).data() as Map<String, dynamic>;
    final otherUserData = (await firestore.collection("users").doc(otherUserId).get()).data() as Map<String, dynamic>;

    final participantsName = {
      currentUserId: currentUserData['fullName']?.toString() ?? "",
      otherUserId: otherUserData['fullName']?.toString() ?? "",
    };

    final newRoom = ChatRoomModel(
      id: roomId,
      participants: users,
      participantsName: participantsName,
      lastReadTime: {
        currentUserId: Timestamp.now(),
        otherUserId: Timestamp.now(),
      },
    );

    await _chatRooms.doc(roomId).set(newRoom.toMap());
    return newRoom;
  }

  // Send a message in the chat room
  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    final batch = firestore.batch();

    final messageRef = getChatRoomMessages(chatRoomId);
    final messageDoc = messageRef.doc();

    final message = ChatMessage(
      id: messageDoc.id,
      chatRoomId: chatRoomId,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      type: type,
      timestamp: Timestamp.now(),
      readBy: [senderId],
    );

    batch.set(messageDoc, message.toMap());

    batch.update(
      _chatRooms.doc(chatRoomId),
      {
        "lastMessage": content,
        "lastMessageSenderId": senderId,
        "lastMessageTime": message.timestamp,
      },
    );

    await batch.commit();
  }

  // Get messages for a chat room
  Stream<List<ChatMessage>> getMessages(String chatRoomId, {DocumentSnapshot? lastDocument}) {
    var query = getChatRoomMessages(chatRoomId).orderBy('timestamp', descending: true).limit(20);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList();
    });
  }

  // Get more messages in the chat room
  Future<List<ChatMessage>> getMoreMessages(String chatRoomId, {required DocumentSnapshot lastDocument}) async {
    var query = getChatRoomMessages(chatRoomId).orderBy('timestamp', descending: true).startAfterDocument(lastDocument).limit(20);

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList();
  }

  // Get all chat rooms for a user
  Stream<List<ChatRoomModel>> getChatRooms(String userId) {
    return _chatRooms.where("participants", arrayContains: userId)
        .orderBy("lastMessageTime", descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ChatRoomModel.fromFirestore(doc)).toList());
  }

  // Get unread message count for a chat room
  Stream<int> getUnreadCount(String chatRoomId, String userId) {
    return getChatRoomMessages(chatRoomId)
        .where("receiverId", isEqualTo: userId)
        .where('status', isEqualTo: MessageStatus.sent.toString())
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark all messages as read for a user in a chat room
  Future<void> markMessagesAsRead(String chatRoomId, String userId) async {
    try {
      final batch = firestore.batch();

      final unreadMessages = await getChatRoomMessages(chatRoomId)
          .where("receiverId", isEqualTo: userId)
          .where('status', isEqualTo: MessageStatus.sent.toString())
          .get();

      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([userId]),
          'status': MessageStatus.read.toString(),
        });
      }

      await batch.commit();
      print("Marked all messages as read for $userId");
    } catch (e) {
      print("Error marking messages as read: $e");
    }
  }

  // Get the online status of a user
  Stream<Map<String, dynamic>> getUserOnlineStatus(String userId) {
    return firestore.collection("users").doc(userId).snapshots().map((snapshot) {
      final data = snapshot.data();
      return {
        'isOnline': data?['isOnline'] ?? false,
        'lastSeen': data?['lastSeen'],
      };
    });
  }

  // Get the typing status in a chat room
  Stream<Map<String, dynamic>> getTypingStatus(String chatRoomId) {
    return _chatRooms.doc(chatRoomId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return {
          'isTyping': false,
          'typingUserId': null,
        };
      }

      final data = snapshot.data() as Map<String, dynamic>;
      return {
        "isTyping": data['isTyping'] ?? false,
        "typingUserId": data['typingUserId'],
      };
    });
  }
Future<void> updateOnlineStatus (String userId , bool isOnline)async{
  await firestore.collection("users").doc(userId).update({
    'isOnline' : isOnline , 
    'lastseen' : Timestamp.now()
  });

}


Future<void> updateTypingStatus(String chatRoomId , String userId , bool isTyping)async{
  try{
    final doc = await _chatRooms.doc(chatRoomId).get();
    if(!doc.exists){
      print("chatroom doesn't exits");
      return ; 

    }

    await _chatRooms.doc(chatRoomId).update({
      'isTyping' : isTyping , 
      'typingUserId' : isTyping?userId : null , 

  });
  }catch(e){
    print("error updating typing status");
  }
}

Future<void> blockUser(String currentUserId, String blockedUserId)async{
  final userRef = firestore.collection("users").doc(currentUserId);
  await userRef.update({
    'blockedUsers' : FieldValue.arrayUnion([blockedUserId]),
  });
}


Future<void> unblockUser(String currentUserId, String blockedUserId)async{
  final userRef = firestore.collection("users").doc(currentUserId);
  await userRef.update({
    'blockedUsers' : FieldValue.arrayRemove([blockedUserId]),
  });
}

Stream<bool> isUserBloked(String currentUserId , String otherUserId){
  return firestore.collection("users").doc(currentUserId).snapshots().map((doc){
    final userData = UserModel.fromFirestore(doc);
    return userData.blockedUsers.contains(otherUserId);

  });
}



Stream<bool> amIBloked(String currentUserId , String otherUserId){
  return firestore.collection("users").doc(otherUserId).snapshots().map((doc){
    final userData = UserModel.fromFirestore(doc);
    return userData.blockedUsers.contains(currentUserId);

  });
}

}
