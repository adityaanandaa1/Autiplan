import 'package:flutter/material.dart';
import '../theme/theme.dart';

class ChildSegmented extends StatelessWidget {
  const ChildSegmented({
    super.key,
    required this.children,
    required this.selectedIndex,
    required this.onSegmentSelected,
  });

  final List<ChildSegmentData> children;
  final int selectedIndex;
  final ValueChanged<int> onSegmentSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.permukaan,
        border: Border.all(color: AppColors.garis),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(children.length, (index) {
          final child = children[index];
          final isSelected = index == selectedIndex;

          return Expanded(
            child: GestureDetector(
              onTap: () => onSegmentSelected(index),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.utamaLembut : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${child.name} · ${child.age} th',
                  style: AppTypography.isi.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.utama : AppColors.teks,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class ChildSegmentData {
  const ChildSegmentData({
    required this.name,
    required this.age,
  });

  final String name;
  final int age;
}
