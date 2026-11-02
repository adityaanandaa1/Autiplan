import 'package:flutter/material.dart';
import '../theme/theme.dart';

class ChildHeader extends StatelessWidget {
  const ChildHeader({
    super.key,
    required this.greeting,
    required this.childName,
  });

  final String greeting;
  final String childName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.grid20,
        AppSpacing.grid20,
        AppSpacing.grid20,
        AppSpacing.grid16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(greeting, style: AppTypography.sekunderAnak),
          const SizedBox(height: AppSpacing.grid4),
          Text(childName, style: AppTypography.sapaanAnak),
        ],
      ),
    );
  }
}
