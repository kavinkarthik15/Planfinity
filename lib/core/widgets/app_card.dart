import 'package:flutter/material.dart';

import '../constants/ui_constants.dart';
import '../theme/theme.dart';

class AppCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  double scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => scale = 0.97),
      onTapUp: (_) {
        setState(() => scale = 1.0);
      },
      onTapCancel: () => setState(() => scale = 1.0),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: Material(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(UIConstants.radius),
          child: InkWell(
            borderRadius: BorderRadius.circular(UIConstants.radius),
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.all(UIConstants.padding),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(UIConstants.radius),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
