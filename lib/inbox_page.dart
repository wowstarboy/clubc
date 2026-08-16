import 'package:flutter/material.dart';
import 'package:jamiiclub/new_message_page.dart'; // IMPORT THE NEW PAGE
import 'package:jamiiclub/services/chat_service.dart';
import 'package:jamiiclub/models/chat_models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jamiiclub/models/user_model.dart'; // Add this import
import 'package:jamiiclub/pages/chat_page.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Inbox', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_square, size: 26),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NewMessagePage()),
              );
            },
          ),
        ],
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            // --- SEARCH BAR ---
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search in Inbox',
                prefixIcon: Icon(Icons.search, color: Theme.of(context).textTheme.bodySmall?.color),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[850] : Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
            const SizedBox(height: 20),

            // --- MESSAGE LIST (REAL DATA) ---
            Expanded(
              child: StreamBuilder<List<ChatModel>>(
                stream: _chatService.getChats(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No messages yet.'));
                  }

                  final chats = snapshot.data!;

                  return ListView.builder(
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      final otherUserId = chat.participants.firstWhere(
                          (uid) => uid != _auth.currentUser?.uid,
                          orElse: () => '');

                      if (otherUserId.isEmpty) {
                        return const SizedBox.shrink(); // Skip if no other user
                      }

                      return FutureBuilder<UserModel?>(
                        future: _getUserData(otherUserId),
                        builder: (context, userSnapshot) {
                          if (userSnapshot.connectionState == ConnectionState.waiting) {
                             return const SizedBox.shrink();
                          }
                          if (!userSnapshot.hasData || userSnapshot.data == null) {
                            return const SizedBox.shrink();
                          }

                          final user = userSnapshot.data!;
                          
                          // Filter logic
                          if (_searchQuery.isNotEmpty && !user.username.toLowerCase().contains(_searchQuery)) {
                              return const SizedBox.shrink(); // Hide if it doesn't match search query
                          }

                          final time = _formatTimestamp(chat.lastMessageTimestamp);

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatPage(user: user),
                                ),
                              );
                            },
                            child: _ChatListItem(
                              username: user.username,
                              profileImageUrl: user.profilePhotoUrl,
                              lastMessage: chat.lastMessage,
                              time: time,
                              isUnread: true, // This needs to be determined logically
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<UserModel?> _getUserData(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromSnap(doc);
      }
    } catch (e) {
      // Handle error
    }
    return null;
  }
  
  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final messageTime = timestamp.toDate();
    final difference = now.difference(messageTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
}

// --- WIDGET REFACTORED TO BE A STATELESSWIDGET AND SELF-CONTAINED ---
class _ChatListItem extends StatelessWidget {
  final String username;
  final String? profileImageUrl;
  final String lastMessage;
  final String time;
  final bool isUnread;

  const _ChatListItem({
    required this.username,
    this.profileImageUrl,
    required this.lastMessage,
    required this.time,
    required this.isUnread,
  });

  @override
  Widget build(BuildContext context) {
    // ALL COLORS ARE NOW DERIVED FROM THE THEME INSIDE THE WIDGET
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;
    final subtextColor = Theme.of(context).textTheme.bodySmall?.color;
    final placeholderColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: placeholderColor,
            backgroundImage: profileImageUrl != null && profileImageUrl!.isNotEmpty
              ? NetworkImage(profileImageUrl!)
              : null,
             child: profileImageUrl == null || profileImageUrl!.isEmpty
              ? const Icon(Icons.person, color: Colors.grey)
              : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: TextStyle(
                    fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lastMessage,
                  style: TextStyle(
                    color: isUnread ? textColor.withOpacity(0.9) : subtextColor,
                    fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: TextStyle(
                  color: subtextColor,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              if (isUnread)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
