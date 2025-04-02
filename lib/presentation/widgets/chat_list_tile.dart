import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/models/chat_room_mode.dart';
import 'package:flutter_application_1/data/repo/chat_repo.dart';
import 'package:flutter_application_1/data/service/service_locator.dart';

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
    if (chat.participants.isEmpty) {
      return "Unknown"; // Return "Unknown" if no participants
    }

    final otherUserId = chat.participants.firstWhere(
      (id) => id != currentUserId, 
      orElse: () => "", 
    );

    if (otherUserId.isEmpty) {
      return "Unknown"; // Return "Unknown" if no valid other user ID
    }

    return chat.participantsName?[otherUserId] ?? "Unknown"; 
  }

  @override
  Widget build(BuildContext context) {
    final otherUserName = _getOtherUserName();
    final avatarLetter = otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : '?';

    return ListTile(
      onTap: onTap, 
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
        child: Text(avatarLetter), // Display the first letter or '?' if empty
      ),
      title: Text(
        otherUserName, 
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              chat.lastMessage ?? "", 
              maxLines: 1, 
              overflow: TextOverflow.ellipsis, 
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
      trailing: StreamBuilder<int>(stream: getIt<ChatRepo>().getUnreadCount(chat.id , currentUserId), builder: (context , snapshot){
        if(!snapshot.hasData || snapshot.data == 0){
          return const SizedBox() ; 
        }
        return Container(
          padding : EdgeInsets.all(8) , 
          decoration: BoxDecoration(
            color : Theme.of(context).primaryColor , 
            shape : BoxShape.circle , 

          ),
          child :  Text(
            snapshot.data.toString() , 
            style : TextStyle(color : Colors.white)
          )
         );
      })
    );
  }
}
