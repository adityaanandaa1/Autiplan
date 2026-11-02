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
import '../forms/form_field.dart';
import '../forms/form_utils.dart';
import '../forms/icon_picker_sheet.dart';
import '../forms/sheet_scaffold.dart';
import '../forms/time_feedback.dart';
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
    this.suggestionId,
  });

  final String childId;
  final DateTime initialDate;
  final String? initialTitle;
  final ActivityIcon? initialIcon;
  final TimeOfDayLite? initialStart;
  final TimeOfDayLite? initialEnd;

  /// ID saran asal sheet ini (§9.1). Setelah jadwal berhasil disimpan,
  /// status saran menjadi `applied`.
  final String? suggestionId;

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

  /// True bila pengguna mengisi Nama singkat sendiri; selain itu Nama singkat
  /// mengikuti dua kata pertama Nama (§8.6).
  bool _shortManual = false;

  @override
  void initState() {
    super.initState();
    _childId = widget.childId;
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _shortTitleController = TextEditingController(
      text: shortTitleFromTitle(widget.initialTitle ?? ''),
    );
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

  void _onTitleChanged(String _) {
    setState(() {
      if (!_shortManual) {
        _shortTitleController.text = shortTitleFromTitle(_titleController.text);
      }
    });
  }

  void _onShortTitleChanged(String value) {
    setState(() {
      _shortManual = value.trim().isNotEmpty;
      if (!_shortManual) {
        _shortTitleController.text = shortTitleFromTitle(_titleController.text);
      }
    });
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

  void _reorderStep(int oldIndex, int newIndex) {
    setState(() {
      final moved = _stepControllers.removeAt(oldIndex);
      _stepControllers.insert(newIndex, moved);
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

    final shortTitleValid = isValidShortTitle(_shortTitleController.text);
    final canSave =
        titleText.isNotEmpty &&
        _icon != null &&
        shortTitleValid &&
        !TimeFeedback.blocksSave(candidate, state.activities);

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
            onChanged: _onTitleChanged,
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
              final picked = await showIconPickerSheet(
                context,
                selected: _icon,
              );
              if (picked != null) {
                setState(() {
                  _icon = picked;
                  if (picked == ActivityIcon.tidur) {
                    _end = null;
                  } else {
                    // Selesai kosong hanya untuk Tidur (§8.6).
                    _end ??= defaultEndFor(_start);
                  }
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
          TimeFeedback(
            candidate: candidate,
            allActivities: state.activities,
            minGapMinutes: state.settings.minGapMinutes,
            childName: child.name,
            onUseSlot: (start, end) => setState(() {
              _start = start;
              _end = end;
            }),
          ),
          const SizedBox(height: AppSpacing.grid16),
          const FormLabel('Opsi lanjutan'),
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
              onReorderStep: _reorderStep,
              onDayToggled: (day) => setState(() {
                if (_repeatWeekdays.contains(day)) {
                  _repeatWeekdays.remove(day);
                } else {
                  _repeatWeekdays.add(day);
                }
              }),
              onShortTitleChanged: _onShortTitleChanged,
              shortTitleError: shortTitleValid
                  ? null
                  : 'Nama singkat maksimal 2 kata.',
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
    final suggestionId = widget.suggestionId;

    // Kegiatan baru bukan perubahan: tidak membuat ChangeNotice (§8.6).
    // Status saran menjadi applied hanya setelah jadwal tersimpan (§9.1).
    notifier.updateState(
      appState.copyWith(
        activities: [...appState.activities, newAct],
        suggestionStatus: suggestionId == null
            ? appState.suggestionStatus
            : {
                ...appState.suggestionStatus,
                suggestionId: SuggestionStatus.applied,
              },
      ),
    );

    Navigator.of(context).pop();
    CalmSnackbar.show(
      context,
      message: 'Jadwal tersimpan dan dikirim ke HP ${child.name}',
    );
  }
}
