class FirestoreCollections {
  // User Collection
  static const String users = 'users';

  // Fields for User Collection
  static const String uid = 'uid';
  static const String username = 'username';
  static const String displayName = 'displayName';
  static const String email = 'email';
  static const String bio = 'bio';
  static const String profilePhotoUrl = 'profilePhotoUrl';
  static const String website = 'website';
  static const String isVerified = 'isVerified';
  static const String createdAt = 'createdAt';

  // Post Collection
  static const String posts = 'posts';

  // Fields for Post Collection
  static const String postId = 'postId';
  static const String authorId = 'authorId';
  static const String mediaUrl = 'mediaUrl';
  static const String mediaType = 'mediaType';
  static const String caption = 'caption';
  static const String likeCount = 'likeCount';
  static const String commentsCount = 'commentsCount';
  static const String mediaUrls = 'mediaUrls';
  static const String musicUrl = 'musicUrl';
  static const String location = 'location';
  static const String tags = 'tags';

  // Post Likes Collection
  static const String postLikes = 'post_likes';

  // Fields for Post Likes Collection
  static const String likeId = 'likeId';
  // postId is already defined
  static const String userId = 'userId';
  // createdAt is already defined

  // Comments sub-collection (within a post)
  static const String comments = 'comments';

  // Fields for Comments Collection
  static const String commentId = 'commentId';
  // authorId is already defined
  static const String commentText = 'commentText';
  static const String commentLikeCount = 'commentLikeCount';
  static const String replyCount = 'replyCount'; // Field to count replies on a comment
  // createdAt is already defined

  // Comment Likes Collection (sub-collection of a comment)
  static const String commentLikes = 'comment_likes';

  // Replies sub-collection (within a comment)
  static const String replies = 'replies';

  // Fields for Replies Collection
  // A reply has its own ID.
  static const String replyId = 'replyId'; 
  // A reply document has the same structure as a comment document,
  // using fields like: authorId, commentText, likeCount, createdAt.

  // Reply Likes Collection (sub-collection of a reply)
  static const String replyLikes = 'reply_likes';


  // Stories Collection
  static const String stories = 'stories';

  // Fields for Stories Collection
  static const String storyId = 'storyId';
  static const String expiresAt = 'expiresAt';
  static const String viewers = 'viewers';

  // Follows Collection
  static const String follows = 'follows';

  // Fields for Follows Collection
  static const String followerId = 'followerId';
  static const String followingId = 'followingId';

  // Blocks Collection
  static const String blocks = 'blocks';

  // Fields for Blocks Collection
  static const String blockerId = 'blockerId';
  static const String blockedId = 'blockedId';

  // Reports Collection
  static const String reports = 'reports';

  // Fields for Reports Collection
  static const String reporterId = 'reporterId';
  static const String reportedId = 'reportedId';
  static const String reason = 'reason';
  static const String contentId = 'contentId';
  static const String contentType = 'contentType';

  // --- Chat Feature --- 

  // Collection for chat rooms
  static const String chats = 'chats';

  // Fields for Chats Collection
  static const String chatId = 'chatId';
  static const String participants = 'participants';
  static const String lastMessage = 'lastMessage';
  static const String lastMessageTimestamp = 'lastMessageTimestamp';

  // Sub-Collection for messages within a chat
  static const String messages = 'messages';

  // Fields for Messages Sub-Collection
  static const String messageId = 'messageId';
  static const String senderId = 'senderId';
  static const String content = 'content';
  static const String timestamp = 'timestamp';
  static const String messageType = 'messageType';
  static const String isRead = 'isRead';
}
