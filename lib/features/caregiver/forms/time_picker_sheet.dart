import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/buttons.dart';
import '../../../data/models/models.dart';
import 'form_field.dart';
import 'form_utils.dart';
import 'sheet_scaffold.dart';

class TimePickerResult {
  const TimePickerResult({required this.date, required this.start, this.end});

  final DateTime date;
  final TimeOfDayLite start;
  final TimeOfDayLite? end;
}

Future<TimePickerResult?> showDateTimePickerSheet(
  BuildContext context, {
  required DateTime initialDate,
  required TimeOfDayLite initialStart,
  TimeOfDayLite? initialEnd,
  bool allowClearEnd = true,
}) {
  return showModalBottomSheet<TimePickerResult>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _DateTimePickerBody(
      initialDate: initialDate,
      initialStart: initialStart,
      initialEnd: initialEnd,
      allowClearEnd: allowClearEnd,
    ),
  );
}

class _DateTimePickerBody extends StatefulWidget {
  const _DateTimePickerBody({
    required this.initialDate,
    required this.initialStart,
    this.initialEnd,
    required this.allowClearEnd,
  });

  final DateTime initialDate;
  final TimeOfDayLite initialStart;
  final TimeOfDayLite? initialEnd;
  final bool allowClearEnd;

  @override
  State<_DateTimePickerBody> createState() => _DateTimePickerBodyState();
}

class _DateTimePickerBodyState extends State<_DateTimePickerBody> {
  late DateTime _selectedDate;
  late TimeOfDayLite _start;
  TimeOfDayLite? _end;

  @override
  void initState() {
    super.initState();
    _selectedDate = dateOnly(widget.initialDate);
    _start = widget.initialStart;
    _end = widget.initialEnd;
  }

  Future<void> _pickStart() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _start.hour, minute: _start.minute),
    );
    if (picked != null) {
      setState(() => _start = TimeOfDayLite(picked.hour, picked.minute));
    }
  }

  Future<void> _pickEnd() async {
    final current = _end ?? _start;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (picked != null) {
      setState(() => _end = TimeOfDayLite(picked.hour, picked.minute));
    }
  }

  @override
  Widget build(BuildContext context) {
    final monday =
        _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    final weekDates = List.generate(7, (i) => monday.add(Duration(days: i)));

    return SheetScaffold(
      title: 'Pilih waktu',
      subtitle: formatDateLong(_selectedDate),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FormLabel('Tanggal'),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: weekDates.map((d) {
                final selected = isSameDay(d, _selectedDate);
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.grid8),
                  child: ChoiceChip(
                    label: Text(formatDateShort(d)),
                    selected: selected,
                    selectedColor: AppColors.utamaLembut,
                    backgroundColor: AppColors.latar,
                    showCheckmark: false,
                    labelStyle: AppTypography.meta.copyWith(
                      color: selected ? AppColors.utama : AppColors.teks,
                    ),
                    onSelected: (_) =>
                        setState(() => _selectedDate = dateOnly(d)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.grid16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FormLabel('Mulai'),
                    FormLinkRow(
                      text: formatTimeLite(_start),
                      trailing: const Icon(
                        LucideIcons.clock,
                        size: AppSpacing.iconSize18,
                      ),
                      onTap: _pickStart,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.grid12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FormLabel(
                      'Selesai',
                      optional: widget.allowClearEnd ? '(opsional)' : null,
                    ),
                    FormLinkRow(
                      text: _end != null ? formatTimeLite(_end!) : 'Pagi',
                      onTap: _pickEnd,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_end != null && widget.allowClearEnd)
                            GestureDetector(
                              onTap: () => setState(() => _end = null),
                              child: const Icon(
                                LucideIcons.x,
                                size: AppSpacing.iconSize16,
                                color: AppColors.teksSekunder,
                              ),
                            ),
                          const SizedBox(width: 4),
                          const Icon(
                            LucideIcons.clock,
                            size: AppSpacing.iconSize18,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.grid24),
          PrimaryButton(
            label: 'Simpan waktu',
            onPressed: () {
              Navigator.of(context).pop(
                TimePickerResult(date: _selectedDate, start: _start, end: _end),
              );
            },
          ),
        ],
      ),
    );
  }
}
