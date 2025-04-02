import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/models/chat_message_model.dart';
import 'package:flutter_application_1/data/service/service_locator.dart';
import 'package:flutter_application_1/logic/chat/chat_cubit.dart';
import 'package:flutter_application_1/logic/chat/chat_state.dart';
import 'package:flutter_application_1/presentation/widgets/loading_dots.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ChatMessageScreen extends StatefulWidget {
  final String receiverId; // Receiver's ID for the chat
  final String receiverName; // Receiver's name for display

  const ChatMessageScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatMessageScreen> createState() => _ChatMessageScreenState();
}

class _ChatMessageScreenState extends State<ChatMessageScreen> {
  final TextEditingController messageController = TextEditingController(); // Controller for the message input
  late final ChatCubit chatCubit; // The ChatCubit to manage chat logic

  bool isComposing = false; // Flag to track if the user is typing
  final scrollController = ScrollController(); // Controller for the scrollable chat list
  bool showemoji = false; // Flag to show or hide emoji keyboard

  List<ChatMessage> previousMessages = []; // Store previous messages for comparison

  @override
  void initState() {
    super.initState();
    chatCubit = getIt<ChatCubit>(); // Initialize the ChatCubit
    chatCubit.enterChat(widget.receiverId); // Enter the chat for the specific receiver
    messageController.addListener(onTextChanged); // Listen for changes in message input
    scrollController.addListener(onScroll); // Listen for scroll events
  }

  // Handles infinite scrolling for loading more messages
  void onScroll() {
    if (scrollController.position.pixels <= 200) {
      chatCubit.loadmoremessages(); // Load more messages when near top
    }
  }

  // Sends the message when the user hits send
  Future<void> handleSendMessage() async {
    final messageText = messageController.text.trim(); // Get message text
    if (messageText.isEmpty) return; // Do not send if empty
    messageController.clear(); // Clear the message input
    setState(() {}); // Update the state
    await chatCubit.sendMessage(
      content: messageText,
      receiverId: widget.receiverId,
    ); // Send the message using the ChatCubit
  }

  // Tracks when the text input changes (user typing)
  void onTextChanged() {
    final composing = messageController.text.isNotEmpty; // Check if the message input is not empty
    if (composing != isComposing) {
      setState(() {
        isComposing = composing; // Update the typing status
      });
    }

    if (composing) {
      chatCubit.startTyping(); // Notify that the user is typing
    }
  }

  // Scroll to the bottom of the chat
  void scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.minScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Handles new messages
  void hasNewMessages(List<ChatMessage> messages) {
    if (messages.length != previousMessages.length) {
      scrollToBottom(); // Scroll to bottom if new messages are added
      previousMessages = List.from(messages); // Update the message list
    }
  }

  @override
  void dispose() {
    messageController.dispose(); // Dispose the controller when done
    chatCubit.leaveChat(); // Leave the chat
    scrollController.dispose(); // Dispose the scroll controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Text(widget.receiverName.isNotEmpty ? widget.receiverName[0].toUpperCase() : 'N'),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.receiverName.isNotEmpty ? widget.receiverName : 'Unknown'),
                BlocBuilder<ChatCubit, ChatState>(
                  bloc: chatCubit,
                  builder: (context, state) {
                    if (state.isreceiverTyping) {
                      return const LoadingDots(); // Show loading dots when receiver is typing
                    }
                    if (state.isreceiverOnline) {
                      return Text("Online", style: TextStyle(color: Colors.green)); // Show online status
                    }
                    if (state.receiverlaseseen != null) {
                      final lastSeen = state.receiverlaseseen!.toDate();
                      return Text(
                        "Last seen: ${lastSeen.hour % 12 == 0 ? 12 : lastSeen.hour % 12}:${lastSeen.minute.toString().padLeft(2, '0')} ${lastSeen.hour >= 12 ? 'PM' : 'AM'}",
                      ); // Display last seen timestamp
                    }
                    return SizedBox(); // Fallback if no status available
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      body: BlocConsumer<ChatCubit, ChatState>(
        listener: (context, state) {
          hasNewMessages(state.messages); // Update messages if there are new ones
        },
        bloc: chatCubit,
        builder: (context, state) {
          if (state.status == ChatStatus.loading) {
            return const Center(child: CircularProgressIndicator()); // Show loading indicator while loading
          }
          if (state.status == ChatStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.error ?? "Something went wrong"), // Show error message
                  ElevatedButton(
                    onPressed: () => chatCubit.enterChat(widget.receiverId),
                    child: const Text("Retry"), // Retry loading chat
                  ),
                ],
              ),
            );
          }
          if (state.messages.isEmpty) {
            return const Center(child: Text("No messages yet")); // Show message if no chat history
          }
          return Column(
            children: [
              if (state.amiblocked)
                Container(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    "You have been blocked by ${widget.receiverName}",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  reverse: true, // Start listview from the bottom
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    final message = state.messages[index];
                    final isMe = message.senderId == chatCubit.currentUserId; // Check if it's the current user's message
                    return MessageBubble(
                      message: message,
                      isMe: isMe,
                    );
                  },
                ),
              ),
              if (!state.amiblocked && !state.isuserblocked)
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            showemoji = !showemoji; // Toggle emoji keyboard visibility
                            if (showemoji) {
                              FocusScope.of(context).unfocus(); // Hide keyboard when emoji button is pressed
                            }
                          });
                        },
                        icon: const Icon(Icons.emoji_emotions), // Emoji button
                      ),
                      Expanded(
                        child: TextField(
                          controller: messageController, // Message input field
                          decoration: InputDecoration(
                            hintText: "Type a message", // Placeholder text
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: isComposing ? handleSendMessage : null, // Disable send button if nothing is typed
                        icon: Icon(Icons.send), // Send button
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// MessageBubble widget displays individual message content
class MessageBubble extends StatelessWidget {
  final ChatMessage message; // The message data
  final bool isMe; // Check if the message is from the current user

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft, // Align based on who sent it
      child: Container(
        margin: EdgeInsets.only(
          left: isMe ? 64 : 8, // Adjust margin based on sender
          right: isMe ? 8 : 64,
          bottom: 4,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Padding inside the message bubble
        decoration: BoxDecoration(
            color: isMe
                ? Theme.of(context).primaryColor // My messages
                : Theme.of(context).primaryColor.withOpacity(0.1), // Other's messages
            borderRadius: BorderRadius.circular(16), // Rounded corners for bubbles
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start, // Align text based on sender
          children: [
            Text(
              message.content, // Message content
              style: TextStyle(color: isMe ? Colors.white : Colors.black), // Text color based on sender
            ),
            Row(
              mainAxisSize: MainAxisSize.min, // Minimize row size
              children: [
                Text(
                  DateFormat('h:mm a').format(message.timestamp.toDate()), // Display message time
                  style: TextStyle(color: isMe ? Colors.white : Colors.black),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4), // Space between time and status
                  Icon(
                    Icons.done_all, // Sent/read checkmark
                    size: 14,
                    color: message.status == MessageStatus.read ? Colors.red : Colors.white70, // Checkmark color
                  )
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }
}
