import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/activity_icon_data.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/calm_snackbar.dart';
import '../../../core/widgets/child_segmented.dart';
import '../../../data/models/models.dart';
import '../../../data/providers.dart';
import '../../../domain/schedule_rules.dart';
import '../forms/form_field.dart';
import '../forms/form_utils.dart';
import '../forms/icon_picker_sheet.dart';
import '../forms/sheet_scaffold.dart';
import '../forms/time_picker_sheet.dart';
import 'add_activity_advanced.dart';

/// Sheet Tambah jadwal (OT-08, aturan §8.6).
class AddActivitySheet extends ConsumerStatefulWidget {
  const AddActivitySheet({
    super.key,
    required this.childId,
    required this.initialDate,
    this.initialTitle,
    this.initialIcon,
    this.initialStart,
    this.initialEnd,
  });

  final String childId;
  final DateTime initialDate;
  final String? initialTitle;
  final ActivityIcon? initialIcon;
  final TimeOfDayLite? initialStart;
  final TimeOfDayLite? initialEnd;

  @override
  ConsumerState<AddActivitySheet> createState() => _AddActivitySheetState();
}

class _AddActivitySheetState extends ConsumerState<AddActivitySheet> {
  late String _childId;
  late final TextEditingController _titleController;
  late final TextEditingController _shortTitleController;
  ActivityIcon? _icon;
  late DateTime _date;
  late TimeOfDayLite _start;
  TimeOfDayLite? _end;

  final List<TextEditingController> _stepControllers = [];
  final Set<int> _repeatWeekdays = {};
  bool _independentMode = false;
  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();
    _childId = widget.childId;
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _shortTitleController = TextEditingController();
    _icon = widget.initialIcon;
    _date = dateOnly(widget.initialDate);
    _start = widget.initialStart ?? const TimeOfDayLite(17, 15);
    _end = widget.initialEnd ?? const TimeOfDayLite(17, 45);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _shortTitleController.dispose();
    for (final c in _stepControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addStep() {
    if (_stepControllers.length < 5) {
      setState(() => _stepControllers.add(TextEditingController()));
    }
  }

  void _removeStep(int index) {
    setState(() {
      _stepControllers[index].dispose();
      _stepControllers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final child = state.children.firstWhere((c) => c.id == _childId);
    final childIndex = state.children.indexWhere((c) => c.id == _childId);

    final titleText = _titleController.text.trim();
    final candidate = buildActivity(
      id: 'temp-new',
      childId: _childId,
      title: titleText.isNotEmpty ? titleText : 'Kegiatan Baru',
      icon: _icon ?? ActivityIcon.main,
      date: _date,
      start: _start,
      end: _end,
      steps: _stepControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
      repeatWeekdays: _repeatWeekdays,
      shortTitle: _shortTitleController.text,
      independentMode: _independentMode,
    );

    final conflicts = findConflicts(
      activity: candidate,
      allActivities: state.activities,
    );
    final isConflicting = conflicts.isNotEmpty;

    TimeOfDayLite? freeSlot;
    if (isConflicting) {
      freeSlot = findNearestFreeSlot(
        activity: candidate,
        allActivities: state.activities,
        conflictingActivity: conflicts.first,
        minGapMinutes: state.settings.minGapMinutes,
      );
    }

    final canSave = titleText.isNotEmpty && _icon != null && !isConflicting;

    return SheetScaffold(
      title: 'Tambah jadwal',
      subtitle: formatDateLong(_date),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FormLabel('Untuk'),
          ChildSegmented(
            children: state.children
                .map((c) => ChildSegmentData(name: c.name, age: c.age))
                .toList(),
            selectedIndex: childIndex,
            onSegmentSelected: (idx) {
              setState(() => _childId = state.children[idx].id);
            },
          ),
          const SizedBox(height: AppSpacing.grid16),
          const FormLabel('Nama kegiatan'),
          FormTextField(
            controller: _titleController,
            hint: 'Contoh: Mandi sore',
            maxLength: 40,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.grid16),
          const FormLabel('Ikon'),
          FormLinkRow(
            leading: _icon != null
                ? Icon(
                    lucideIconFor(_icon!),
                    size: AppSpacing.iconSize20,
                    color: AppColors.utama,
                  )
                : null,
            text: _icon != null ? activityIconLabel(_icon!) : null,
            hint: 'Pilih ikon',
            trailing: const Text('Ganti', style: AppTypography.tautanAksi),
            onTap: () async {
              final picked =
                  await showIconPickerSheet(context, selected: _icon);
              if (picked != null) {
                setState(() {
                  _icon = picked;
                  if (picked == ActivityIcon.tidur) _end = null;
                });
              }
            },
          ),
          const SizedBox(height: AppSpacing.grid16),
          const FormLabel('Waktu'),
          FormLinkRow(
            leading: const Icon(LucideIcons.clock, size: AppSpacing.iconSize20),
            text:
                '${formatDateShort(_date)} · ${formatTimeLite(_start)} – ${_end != null ? formatTimeLite(_end!) : "Pagi"}',
            trailing: const Icon(
              LucideIcons.chevronRight,
              size: AppSpacing.iconSize20,
            ),
            onTap: () async {
              final res = await showDateTimePickerSheet(
                context,
                initialDate: _date,
                initialStart: _start,
                initialEnd: _end,
                allowClearEnd: _icon == ActivityIcon.tidur,
              );
              if (res != null) {
                setState(() {
                  _date = res.date;
                  _start = res.start;
                  _end = res.end;
                });
              }
            },
          ),
          if (isConflicting) ...[
            const SizedBox(height: AppSpacing.grid12),
            FormInfoBox(
              text:
                  'Waktu ini bentrok dengan ${conflicts.first.title} (${formatTimeLite(conflicts.first.start)}–${conflicts.first.end != null ? formatTimeLite(conflicts.first.end!) : "Pagi"}). Pilih waktu lain supaya ${child.name} tidak bingung.',
              actionLabel: freeSlot != null
                  ? 'Pakai ${formatTimeLite(freeSlot)}'
                  : null,
              onAction: freeSlot != null
                  ? () {
                      setState(() {
                        final dur = candidate.end != null
                            ? candidate.end!.toMinutes() -
                                candidate.start.toMinutes()
                            : 30;
                        _start = freeSlot!;
                        final endMin = freeSlot.toMinutes() + dur;
                        _end = TimeOfDayLite(endMin ~/ 60, endMin % 60);
                      });
                    }
                  : null,
            ),
          ],
          FormLinkRow(
            leading: const Icon(
              LucideIcons.slidersHorizontal,
              size: AppSpacing.iconSize20,
            ),
            text: 'Langkah & pengulangan',
            trailing: Text(
              '${_stepControllers.length} langkah',
              style: AppTypography.meta,
            ),
            onTap: () => setState(() => _showAdvanced = !_showAdvanced),
          ),
          if (_showAdvanced)
            AddActivityAdvanced(
              childName: child.name,
              stepControllers: _stepControllers,
              repeatWeekdays: _repeatWeekdays,
              shortTitleController: _shortTitleController,
              independentMode: _independentMode,
              onAddStep: _addStep,
              onRemoveStep: _removeStep,
              onDayToggled: (day) => setState(() {
                if (_repeatWeekdays.contains(day)) {
                  _repeatWeekdays.remove(day);
                } else {
                  _repeatWeekdays.add(day);
                }
              }),
              onIndependentChanged: (v) => setState(() => _independentMode = v),
            ),
          const SizedBox(height: AppSpacing.grid24),
          PrimaryButton(
            label: 'Simpan jadwal',
            enabled: canSave,
            onPressed: () => _save(child),
          ),
        ],
      ),
    );
  }

  void _save(Child child) {
    final title = _titleController.text.trim();
    final steps = _stepControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final newAct = buildActivity(
      id: generateId('act'),
      childId: _childId,
      title: title,
      icon: _icon!,
      date: _date,
      start: _start,
      end: _end,
      steps: steps,
      repeatWeekdays: _repeatWeekdays,
      shortTitle: _shortTitleController.text,
      independentMode: _independentMode,
    );

    final appState = ref.read(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);

    notifier.updateState(
      appState.copyWith(activities: [...appState.activities, newAct]),
    );

    Navigator.of(context).pop();
    CalmSnackbar.show(
      context,
      message: 'Jadwal tersimpan dan dikirim ke HP ${child.name}',
    );
  }
}

