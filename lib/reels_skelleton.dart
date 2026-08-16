 import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ReelSkeleton extends StatelessWidget {
  const ReelSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Background Shimmer (Inaziba kioo chote)
        Shimmer.fromColors(
          baseColor: Colors.grey[900]!,
          highlightColor: Colors.grey[800]!,
          child: Container(color: Colors.black),
        ),

        // 2. UI Overlays (Details na Actions)
        Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Details upande wa kushoto
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _shimmerBox(width: 36, height: 36, isCircle: true),
                        const SizedBox(width: 10),
                        _shimmerBox(width: 100, height: 15),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _shimmerBox(width: double.infinity, height: 12),
                    const SizedBox(height: 8),
                    _shimmerBox(width: 200, height: 12),
                    const SizedBox(height: 50),
                  ],
                ),
              ),

              // Actions upande wa kulia
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: List.generate(3, (index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: _shimmerBox(width: 30, height: 30, isCircle: true),
                )),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _shimmerBox({required double width, required double height, bool isCircle = false}) {
    return Shimmer.fromColors(
      baseColor: Colors.white10,
      highlightColor: Colors.white24,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.black,
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircle ? null : BorderRadius.circular(4),
        ),
      ),
    );
  }
}
