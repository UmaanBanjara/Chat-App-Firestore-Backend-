  import 'package:flutter/material.dart';
  import 'package:flutter_application_1/data/repo/auth_repo.dart';
  import 'package:flutter_application_1/data/repo/chat_repo.dart';
  import 'package:flutter_application_1/data/repo/contact_repo.dart';
  import 'package:flutter_application_1/data/service/service_locator.dart';
  import 'package:flutter_application_1/logic/bloc/auth_bloc_bloc.dart';
  import 'package:flutter_application_1/presentation/chat/chat_message_screen.dart';
  import 'package:flutter_application_1/presentation/screens/auth/login_screen.dart';
  import 'package:flutter_application_1/presentation/widgets/chat_list_tile.dart';
  import 'package:flutter_application_1/router/app_router.dart';
  import 'package:get_it/get_it.dart';
  import 'package:flutter_bloc/flutter_bloc.dart';

  class HomeScreen extends StatefulWidget {
    const HomeScreen({super.key});

    @override
    State<HomeScreen> createState() => _HomeScreenState();
  }

  class _HomeScreenState extends State<HomeScreen> {
    late final ContactRepository _contactRepository;
    late final ChatRepo  _chatRepo ;  
    late final String   _currentUserId ;

    @override
    void initState() {
      super.initState();
      _contactRepository = getIt<ContactRepository>();
      _chatRepo = getIt<ChatRepo>();
      _currentUserId = getIt<AuthRepository>().currentUser?.uid??"";


    }

    void _showContactsList(BuildContext context) {
      showModalBottomSheet(
        context: context,
        builder: (context) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  "Contacts",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _contactRepository.getRegisteredContacts(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        print("Loading contacts...");
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        print("Error: ${snapshot.error}");
                        return Center(child: Text("Error: ${snapshot.error}"));
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        print("No contacts found");
                        return const Center(child: Text("No contacts found"));
                      }

                      final contacts = snapshot.data!;
                      print("Fetched Contacts: $contacts");

                      return ListView.builder(
                        itemCount: contacts.length,
                        itemBuilder: (context, index) {
                          final contact = contacts[index];
                          print('Contact: $contact');
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.1),
                              foregroundImage: contact['photo'] != null
                                  ? MemoryImage(contact['photo'])
                                  : null,
                              child: Text(contact["name"]?[0]?.toUpperCase() ?? ""),
                            ),
                            title: Text(contact["name"] ?? "No name"),
                            subtitle: Text(contact["phoneNumber"] ?? "No phone number"),
                            onTap: () {
                              getIt<AppRouter>().push(ChatMessageScreen(receiverId: contact['id'], receiverName: contact['name']));
                              // Navigate to chat screen with contact ID
                              /* GetIt.I<AppRouter>().push(
                                ChatScreen(contactId: contact['id']),
                              ); */
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Contacts"),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                context.read<AuthBlocBloc>().add(SignOutuser());
                GetIt.I<AppRouter>().pushAndRemoveUntil(const LoginScreen());
              },
            )
          ],
        ),
        body : StreamBuilder(stream: _chatRepo.getChatRooms(_currentUserId), builder: (context , snapshot){
          if(snapshot.hasError){
            print(snapshot.error) ; 
            return Center(
              child: Text(
                "error : ${snapshot.error}" 
              ),

            ) ;
            
            
          }

          if(!snapshot.hasData){
            return Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data! ; 
          if(chats.isEmpty){
            return Center(
              child : Text("No recent chats ")
            ) ; 
          }
          return ListView.builder(itemCount: chats.length, itemBuilder: (context , index){
            final chat = chats[index] ; 
            return ChatListTile(chat: chat, currentUserId: _currentUserId, onTap: (){
              final otherUserId = chat.participants.firstWhere((id)=> id!=_currentUserId) ;
              final otherUserName = chat.participantsName![otherUserId] ?? "Unknown" ;
              getIt<AppRouter>().push(ChatMessageScreen(receiverId: otherUserId, receiverName: otherUserName));
            });
          });
        }),
          
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showContactsList(context),
          child: const Icon(
            Icons.chat,
            color: Colors.white,
          ),
        ),
      );
    }
  }
