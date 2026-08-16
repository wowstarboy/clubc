import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class CommentSkeleton extends StatelessWidget {
  const CommentSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListTile(
        leading: const CircleAvatar(
          radius: 18,
          backgroundColor: Colors.white,
        ),
        title: Container(
          height: 12,
          width: 150,
          color: Colors.white,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Container(
              height: 10,
              width: double.infinity,
              color: Colors.white,
            ),
            const SizedBox(height: 6),
            Container(
              height: 10,
              width: 100,
              color: Colors.white,
            ),
          ],
        ),
        trailing: const Icon(Icons.favorite_outline, size: 20),
      ),
    );
  }
}
