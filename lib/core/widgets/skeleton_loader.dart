import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../constants/ui_constants.dart';
import '../theme/theme.dart';

class SkeletonLoader extends StatelessWidget {
  const SkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.card,
      highlightColor: Colors.grey.shade700,
      child: Column(
        children: [
          _box(height: 120),
          const SizedBox(height: 16),
          _box(height: 70),
          const SizedBox(height: 16),
          _box(height: 70),
          const SizedBox(height: 12),
          _box(height: 70),
          const SizedBox(height: 12),
          _box(height: 70),
        ],
      ),
    );
  }

  Widget _box({required double height}) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(UIConstants.radius),
      ),
    );
  }
}
