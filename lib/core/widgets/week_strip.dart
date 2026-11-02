import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/theme.dart';

class WeekStrip extends StatelessWidget {
  const WeekStrip({
    super.key,
    required this.dates,
    required this.selectedDate,
    required this.onDateSelected,
    required this.datesWithActivities,
  });

  final List<DateTime> dates;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final Set<DateTime> datesWithActivities;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: dates.map((date) {
        final isSelected = DateUtils.isSameDay(date, selectedDate);
        final hasActivities = datesWithActivities.any(
          (d) => DateUtils.isSameDay(d, date),
        );
        final dayName = DateFormat.E('id_ID').format(date);

        return Expanded(
          child: GestureDetector(
            onTap: () => onDateSelected(date),
            child: Container(
              color: AppColors.transparan,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.grid8),
              child: Column(
                children: [
                  Text(
                    dayName,
                    style: AppTypography.mikro.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.teksSekunder,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.grid6),
                  Container(
                    width: AppSpacing.weekDateCircle,
                    height: AppSpacing.weekDateCircle,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.utama
                          : AppColors.transparan,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${date.day}',
                      style: AppTypography.angkaTanggal.copyWith(
                        color: isSelected
                            ? AppColors.teksDiAtasUtama
                            : AppColors.teks,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.grid6),
                  if (hasActivities)
                    Container(
                      width: AppSpacing.weekDot,
                      height: AppSpacing.weekDot,
                      decoration: const BoxDecoration(
                        color: AppColors.anakAksen,
                        shape: BoxShape.circle,
                      ),
                    )
                  else
                    const SizedBox(height: AppSpacing.weekDot),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
