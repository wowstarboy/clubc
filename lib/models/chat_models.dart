import 'package:cloud_firestore/cloud_firestore.dart';

// Represents a chat room between users
class ChatModel {
  final String chatId;
  final List<String> participants;
  final String lastMessage;
  final Timestamp lastMessageTimestamp;

  ChatModel({
    required this.chatId,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTimestamp,
  });

  Map<String, dynamic> toJson() => {
        'chatId': chatId,
        'participants': participants,
        'lastMessage': lastMessage,
        'lastMessageTimestamp': lastMessageTimestamp,
      };

  static ChatModel fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;
    return ChatModel(
      chatId: snapshot['chatId'] ?? '',
      participants: List<String>.from(snapshot['participants'] ?? []),
      lastMessage: snapshot['lastMessage'] ?? '',
      lastMessageTimestamp: snapshot['lastMessageTimestamp'] ?? Timestamp.now(),
    );
  }
}

// Represents a single message within a chat room
class MessageModel {
  final String messageId;
  final String senderId;
  final String content;
  final Timestamp timestamp;
  final String messageType; // e.g., 'text', 'image', 'video'
  final bool isRead;

  MessageModel({
    required this.messageId,
    required this.senderId,
    required this.content,
    required this.timestamp,
    required this.messageType,
    required this.isRead,
  });

  Map<String, dynamic> toJson() => {
        'messageId': messageId,
        'senderId': senderId,
        'content': content,
        'timestamp': timestamp,
        'messageType': messageType,
        'isRead': isRead,
      };

  static MessageModel fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;
    return MessageModel(
      messageId: snapshot['messageId'] ?? '',
      senderId: snapshot['senderId'] ?? '',
      content: snapshot['content'] ?? '',
      timestamp: snapshot['timestamp'] ?? Timestamp.now(),
      messageType: snapshot['messageType'] ?? 'text',
      isRead: snapshot['isRead'] ?? false,
    );
  }
}
