import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ReelSkeleton extends StatelessWidget {
  const ReelSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Main Content (Video Placeholder)
          Container(
            color: Colors.white,
          ),

          // 2. Details and Actions Overlay
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Left Side: User Info & Caption
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(radius: 18, backgroundColor: Colors.white),
                              const SizedBox(width: 10),
                              Container(height: 14, width: 120, color: Colors.white),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(height: 12, width: double.infinity, color: Colors.white),
                          const SizedBox(height: 6),
                          Container(height: 12, width: 180, color: Colors.white),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Right Side: Action Buttons
                    Column(
                      children: List.generate(3, (index) => 
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: Column(
                            children: [
                              const CircleAvatar(radius: 15, backgroundColor: Colors.white),
                              const SizedBox(height: 6),
                              Container(height: 10, width: 30, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
