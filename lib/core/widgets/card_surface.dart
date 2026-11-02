import 'package:flutter/material.dart';
import '../theme/theme.dart';

class CardSurface extends StatelessWidget {
  const CardSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.grid16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.permukaan,
        borderRadius: AppRadius.kartuOrangTua,
      ),
      padding: padding,
      child: child,
    );
  }
}
