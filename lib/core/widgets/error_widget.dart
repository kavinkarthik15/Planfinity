import 'package:flutter/material.dart';

import '../theme/theme.dart';

class CustomErrorWidget extends StatelessWidget {
  final VoidCallback onRetry;

  const CustomErrorWidget({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: AppColors.danger),
          const SizedBox(height: 16),
          const Text(
            'Something went wrong',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
