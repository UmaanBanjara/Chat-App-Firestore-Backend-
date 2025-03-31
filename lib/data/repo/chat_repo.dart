import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/data/models/chat_message_model.dart';
import 'package:flutter_application_1/data/models/chat_room_mode.dart';
import 'package:flutter_application_1/data/service/base_repo.dart';

class ChatRepo extends BaseRepository {
  CollectionReference get _chatRooms => firestore.collection("chatRooms");

  CollectionReference getChatRoomMessages(String chatRoomId) {
    return _chatRooms.doc(chatRoomId).collection("messages");
  }

  Future<ChatRoomModel> getOrcreateChatRoom(String currentUserId, String otherUserId) async {
    final users = [currentUserId, otherUserId]..sort();
    final roomId = users.join("_");

    final roomDoc = await _chatRooms.doc(roomId).get();

    if (roomDoc.exists) {
      return ChatRoomModel.fromFirestore(roomDoc);
    }

    // Corrected this line, fetching otherUserData correctly
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

  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    // Batch operation
    final batch = firestore.batch();

    // Get message sub-collection
    final messageRef = getChatRoomMessages(chatRoomId);
    final messageDoc = messageRef.doc();

    // Create chat message
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

    // Add message to sub-collection
    batch.set(messageDoc, message.toMap());

    // Update chat room with last message data
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

  // Fixed the Stream mapping error and adjusted the return type.
  Stream<List<ChatMessage>> getMessages(String chatRoomId, {DocumentSnapshot? lastDocument}) {
    var query = getChatRoomMessages(chatRoomId).orderBy('timestamp', descending: true).limit(20);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    return query.snapshots().map((snapshot) {
      // Corrected the mapping logic here
      return snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList();
    });
  }



Future<List<ChatMessage>> getMoreMessages(String chatRoomId, {required DocumentSnapshot lastDocument}) async{
    var query = getChatRoomMessages(chatRoomId).orderBy('timestamp', descending: true).startAfterDocument(lastDocument ).limit(20);

   
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList() ; 
    }








  Stream<List<ChatRoomModel>> getChatRooms (String userId ){
    return _chatRooms.where("participants " , 
    arrayContains: userId).orderBy("lastMessageTime" ,
     descending: true ).snapshots().map((snapshot)=>snapshot.docs.map((doc)=>ChatRoomModel.fromFirestore(doc)).toList());
  }

















  }











