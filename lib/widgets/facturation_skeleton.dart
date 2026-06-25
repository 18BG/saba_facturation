import 'package:flutter/material.dart';

import 'shimmer.dart';

/// Skeleton placeholder that mirrors the Facturation page layout
/// (top bar, filter bar, summary strip and grid) while data loads.
class FacturationSkeleton extends StatelessWidget {
  const FacturationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top bar.
          Container(
            height: 64,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: const [
                SkeletonBox(width: 120, height: 18),
                SizedBox(width: 16),
                SkeletonBox(width: 90, height: 18),
                Spacer(),
                SkeletonBox(width: 220, height: 32, radius: 8),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Filter bar.
                  Row(
                    children: const [
                      SkeletonBox(width: 130, height: 36, radius: 8),
                      SizedBox(width: 10),
                      SkeletonBox(width: 130, height: 36, radius: 8),
                      SizedBox(width: 10),
                      SkeletonBox(width: 150, height: 36, radius: 8),
                      Spacer(),
                      SkeletonBox(width: 110, height: 36, radius: 8),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Summary strip.
                  Row(
                    children: List.generate(
                      6,
                      (i) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: i == 5 ? 0 : 10),
                          child: const SkeletonBox(height: 70, radius: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Grid.
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SkeletonBox(height: 20, radius: 4),
                          const SizedBox(height: 14),
                          Expanded(
                            child: ListView.separated(
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: 9,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (_, _) =>
                                  const SkeletonBox(height: 24, radius: 4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
