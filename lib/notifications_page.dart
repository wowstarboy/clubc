import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        children: const [
          _NotificationHeader(title: 'New'),
          _NotificationListItem(
            username: 'Jane Smith',
            actionText: 'liked your post.',
            time: '15m',
            hasPostImage: true,
          ),
          _NotificationListItem(
            username: 'John Doe',
            actionText: 'started following you.',
            time: '45m',
            isFollow: true,
          ),
          _NotificationListItem(
            username: 'Creative Coder',
            actionText: 'commented: \"This looks amazing! 🔥\"',
            time: '2h',
            hasPostImage: true,
          ),
          _NotificationHeader(title: 'This Week'),
          _NotificationListItem(
            username: 'Flutter Dev',
            actionText: 'liked your comment: \"Great work!\"',
            time: '1d',
            isVerified: true,
          ),
          _NotificationListItem(
            username: 'Alex Ray',
            actionText: 'started following you.',
            time: '2d',
            isFollow: true,
          ),
        ],
      ),
    );
  }
}

// A SIMPLE HEADER FOR GROUPING NOTIFICATIONS
class _NotificationHeader extends StatelessWidget {
  final String title;
  const _NotificationHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
    );
  }
}

// WIDGET FOR EACH NOTIFICATION ITEM
class _NotificationListItem extends StatelessWidget {
  final String username;
  final String actionText;
  final String time;
  final bool isVerified;
  final bool hasPostImage;
  final bool isFollow;

  const _NotificationListItem({
    required this.username,
    required this.actionText,
    required this.time,
    this.isVerified = false,
    this.hasPostImage = false,
    this.isFollow = false,
  });

  @override
  Widget build(BuildContext context) {
    final placeholderColor = Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[300];
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subtextColor = Theme.of(context).textTheme.bodySmall?.color;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 26,
            backgroundColor: placeholderColor,
          ),
          const SizedBox(width: 12),

          // Notification Text
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 14, color: textColor, height: 1.4),
                children: [
                  TextSpan(
                    text: username,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (isVerified)
                    const WidgetSpan(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: Icon(Icons.verified, color: Colors.blue, size: 14),
                      ),
                      alignment: PlaceholderAlignment.middle,
                    ),
                  TextSpan(text: ' $actionText'),
                  TextSpan(
                    text: ' $time',
                    style: TextStyle(color: subtextColor, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Post Image or Follow Button
          if (hasPostImage)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: placeholderColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          if (isFollow)
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Follow', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}
