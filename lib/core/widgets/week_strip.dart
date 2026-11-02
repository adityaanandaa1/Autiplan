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
              color: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  Text(
                    dayName,
                    style: const TextStyle(
                      fontFamily: AppTypography.fontParent,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.teksSekunder,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.utama : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        fontFamily: AppTypography.fontParent,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.teks,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (hasActivities)
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.anakAksen,
                        shape: BoxShape.circle,
                      ),
                    )
                  else
                    const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
