import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/models/chat_room_mode.dart';

class ChatListTile extends StatelessWidget {
  final ChatRoomModel chat; 
  final String currentUserId; 
  final VoidCallback onTap;

  const ChatListTile({
    super.key, 
    required this.chat, 
    required this.currentUserId, 
    required this.onTap
  });

  String _getOtherUserName() {
    // Fixing the space issue and using the correct variable name
    final otherUserId = chat.participants.firstWhere((id) => id != currentUserId);
    return chat.participantsName![otherUserId] ?? "Unknown";
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
        child: Text(_getOtherUserName()[0].toUpperCase()),
      ),
      title : Text(
        _getOtherUserName(),
        style : const TextStyle(
          fontWeight: FontWeight.bold 
        )
      ) , 
      subtitle : Expanded(child: Text(chat.lastMessage ?? "" , maxLines: 1 , overflow: TextOverflow.ellipsis, style : TextStyle(color : Colors.grey))),
      trailing : Container(
        decoration : BoxDecoration(
          color : Theme.of(context).primaryColor , 
          shape : BoxShape.circle ,
        ) , 
        child : Text("3"),
      )
    );
  }
}
