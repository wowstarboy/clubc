import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jamiiclub/models/chat_models.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get or create a chat room and return its ID
  Future<String> getOrCreateChatRoom(String otherUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception("User not logged in");
    }
    
    final currentUserId = currentUser.uid;
    
    // Create a consistent chat ID regardless of who initiates the chat
    List<String> participants = [currentUserId, otherUserId];
    participants.sort(); // Sort the UIDs to ensure consistency
    String chatId = participants.join('_');

    // Check if the chat room already exists
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();

    if (!chatDoc.exists) {
      // Create a new chat room if it doesn't exist
      await _firestore.collection('chats').doc(chatId).set({
        'chatId': chatId,
        'participants': participants,
        'lastMessage': '',
        'lastMessageTimestamp': Timestamp.now(),
      });
    }

    return chatId;
  }

  // Get all chats for current user
  Stream<List<ChatModel>> getChats() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUser.uid)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatModel.fromSnap(doc)).toList();
    });
  }

  // Get message stream
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MessageModel.fromSnap(doc)).toList();
    });
  }

  // Send a message
  Future<void> sendMessage(String chatId, String content) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return; // Not logged in

    final message = MessageModel(
      messageId: _firestore.collection('chats').doc().id, // Generate a new ID
      senderId: currentUser.uid,
      content: content,
      timestamp: Timestamp.now(),
      messageType: 'text',
      isRead: false,
    );

    // Add message to the messages subcollection
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(message.messageId)
        .set(message.toJson());

    // Update the last message in the main chat document
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': content,
      'lastMessageTimestamp': Timestamp.now(),
    });
  }
}