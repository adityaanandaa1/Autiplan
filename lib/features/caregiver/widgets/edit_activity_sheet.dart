import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/clock.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/activity_icon_data.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/calm_snackbar.dart';
import '../../../data/models/models.dart';
import '../../../data/providers.dart';
import '../../../domain/schedule_rules.dart';
import '../forms/form_field.dart';
import '../forms/form_utils.dart';
import '../forms/icon_picker_sheet.dart';
import '../forms/sheet_scaffold.dart';
import '../forms/time_picker_sheet.dart';
import 'add_activity_advanced.dart';
import 'change_preview_sheet.dart';
import 'delete_activity_dialog.dart';

/// Sheet Ubah jadwal (OT-10/11, aturan §8.7).
class EditActivitySheet extends ConsumerStatefulWidget {
  const EditActivitySheet({
    super.key,
    required this.activity,
    required this.child,
  });

  final Activity activity;
  final Child child;

  @override
  ConsumerState<EditActivitySheet> createState() => _EditActivitySheetState();
}

class _EditActivitySheetState extends ConsumerState<EditActivitySheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _shortTitleController;
  late final TextEditingController _messageController;
  late ActivityIcon _icon;
  late DateTime _date;
  late TimeOfDayLite _start;
  TimeOfDayLite? _end;

  final List<TextEditingController> _stepControllers = [];
  late Set<int> _repeatWeekdays;
  late bool _independentMode;
  bool _showAdvanced = false;

  Activity get _original => widget.activity;

  @override
  void initState() {
    super.initState();
    final a = widget.activity;
    _titleController = TextEditingController(text: a.title);
    _shortTitleController = TextEditingController(text: a.shortTitle);
    _messageController = TextEditingController();
    _icon = a.icon;
    _date = dateOnly(a.date);
    _start = a.start;
    _end = a.end;
    _repeatWeekdays = {...a.repeatWeekdays};
    _independentMode = a.independentMode;
    for (final step in a.steps) {
      _stepControllers.add(TextEditingController(text: step));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _shortTitleController.dispose();
    _messageController.dispose();
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

  Activity _buildCandidate() {
    final built = buildActivity(
      id: _original.id,
      childId: _original.childId,
      title: _titleController.text.trim().isNotEmpty
          ? _titleController.text.trim()
          : _original.title,
      icon: _icon,
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
    // Ikon tidak berubah: pertahankan usesScreen asli (§6, layar ikut ikon).
    if (_icon == _original.icon && built.usesScreen != _original.usesScreen) {
      return built.copyWith(usesScreen: _original.usesScreen);
    }
    return built;
  }

  /// Perubahan inti §8.7: nama, ikon, jam mulai, jam selesai.
  bool _coreChanged(Activity candidate) =>
      candidate.title != _original.title ||
      candidate.icon != _original.icon ||
      candidate.start != _original.start ||
      candidate.end != _original.end;

  bool _anyChanged(Activity candidate) =>
      _coreChanged(candidate) ||
      candidate.shortTitle != _original.shortTitle ||
      !_sameList(candidate.steps, _original.steps) ||
      candidate.repeatWeekdays.length != _original.repeatWeekdays.length ||
      !candidate.repeatWeekdays.containsAll(_original.repeatWeekdays) ||
      candidate.independentMode != _original.independentMode;

  bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Kartu saran kontekstual waktu tenang (§9.2): kegiatan memakai layar,
  /// selesai kurang dari {quietTimeMinutes} sebelum kegiatan Tidur.
  String? _quietTimeSuggestionText(AppState state, Activity candidate) {
    if (!candidate.usesScreen || candidate.end == null) return null;
    final sleepActivities = state.activities
        .where(
          (a) =>
              a.childId == candidate.childId &&
              a.icon == ActivityIcon.tidur &&
              isSameDay(a.date, candidate.date),
        )
        .toList();
    if (sleepActivities.isEmpty) return null;
    final sleep = sleepActivities.first;
    if (sleep.start.toMinutes() <= candidate.end!.toMinutes()) return null;
    final gap = sleep.start.toMinutes() - candidate.end!.toMinutes();
    if (gap >= state.settings.quietTimeMinutes) return null;
    return '${candidate.title} selesai $gap menit sebelum tidur. '
        'Layar menjelang tidur bisa membuat ${widget.child.name} '
        'lebih lama tertidur. Tambahkan waktu tenang tanpa layar?';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final candidate = _buildCandidate();
    final coreChanged = _coreChanged(candidate);
    final anyChanged = _anyChanged(candidate);

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

    final quietTime = _quietTimeSuggestionText(state, candidate);
    final message = _messageController.text.trim();
    final canSave = !isConflicting &&
        anyChanged &&
        (!coreChanged || (message.isNotEmpty && message.length <= 120));
    final saveLabel = coreChanged ? 'Kirim perubahan' : 'Simpan';

    return SheetScaffold(
      title: 'Ubah jadwal',
      subtitle: 'Untuk ${widget.child.name} · ${formatDateShort(_date)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label nama dengan ikon pencil (OT-10).
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.grid6),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.pencil,
                  size: AppSpacing.iconSize16,
                  color: AppColors.teksSekunder,
                ),
                const SizedBox(width: AppSpacing.grid6),
                const Text('Nama kegiatan', style: AppTypography.meta),
              ],
            ),
          ),
          FormTextField(
            controller: _titleController,
            hint: 'Nama kegiatan',
            maxLength: 40,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.grid16),
          const FormLabel('Ikon'),
          FormLinkRow(
            leading: Icon(
              lucideIconFor(_icon),
              size: AppSpacing.iconSize20,
              color: AppColors.utama,
            ),
            text: activityIconLabel(_icon),
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
                  'Waktu ini bentrok dengan ${conflicts.first.title} (${formatTimeLite(conflicts.first.start)}–${conflicts.first.end != null ? formatTimeLite(conflicts.first.end!) : "Pagi"}). Pilih waktu lain supaya ${widget.child.name} tidak bingung.',
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
          const SizedBox(height: AppSpacing.grid16),
          if (coreChanged) ...[
            FormLabel('Pesan untuk ${widget.child.name}', optional: 'wajib'),
            FormTextField(
              controller: _messageController,
              hint: 'Contoh: Pak Lana sedang sakit. Kita nonton film dulu.',
              maxLength: 120,
              onChanged: (_) => setState(() {}),
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.grid4),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text('${message.length}/120', style: AppTypography.meta),
              ),
            ),
            FormTextLink(
              label:
                  'Lihat tampilan Dulu → Sekarang di HP ${widget.child.name}',
              onTap: () => showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (ctx) => ChangePreviewSheet(
                  childName: widget.child.name,
                  before: ActivitySnapshot(
                    shortTitle: _original.shortTitle,
                    title: _original.title,
                    icon: _original.icon,
                    start: _original.start,
                  ),
                  after: ActivitySnapshot(
                    shortTitle: candidate.shortTitle,
                    title: candidate.title,
                    icon: candidate.icon,
                    start: candidate.start,
                  ),
                  message: message,
                ),
              ),
            ),
          ] else
            FormInfoBox(
              text:
                  'Kolom "Pesan untuk ${widget.child.name}" muncul setelah kamu mengubah nama, ikon, atau jam.',
            ),
          if (quietTime != null) ...[
            const SizedBox(height: AppSpacing.grid12),
            FormInfoBox(text: quietTime),
          ],
          const SizedBox(height: AppSpacing.grid16),
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
              childName: widget.child.name,
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
            label: saveLabel,
            enabled: canSave,
            onPressed: () => _save(candidate, coreChanged),
          ),
          const SizedBox(height: AppSpacing.grid8),
          DangerOutlineButton(
            label: 'Hapus kegiatan',
            onPressed: () => _delete(),
          ),
        ],
      ),
    );
  }

  void _save(Activity candidate, bool coreChanged) {
    final appState = ref.read(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final now = ref.read(clockProvider).now;

    final result = applyActivityEdit(
      state: appState,
      updated: candidate,
      message: coreChanged ? _messageController.text : null,
      now: now,
      noticeId: generateId('notice'),
    );
    notifier.updateState(result.state);

    Navigator.of(context).pop();
    CalmSnackbar.show(
      context,
      message: coreChanged
          ? 'Perubahan dikirim ke HP ${widget.child.name}'
          : 'Jadwal tersimpan dan dikirim ke HP ${widget.child.name}',
    );
  }

  Future<void> _delete() async {
    final activity = _original;
    final confirmed = await showDeleteActivityDialog(
      context,
      activity: activity,
      childName: widget.child.name,
    );
    if (confirmed != true || !mounted) return;

    final appState = ref.read(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final now = ref.read(clockProvider).now;

    final deleted = deleteActivity(
      state: appState,
      activityId: activity.id,
      now: now,
      noticeId: generateId('notice'),
    );
    notifier.updateState(deleted.state);

    Navigator.of(context).pop();
    CalmSnackbar.show(
      context,
      message: '${activity.title} dihapus',
      actionLabel: 'Urungkan',
      onActionPressed: () {
        final current = ref.read(appStateProvider);
        ref
            .read(appStateProvider.notifier)
            .updateState(undoDeleteActivity(current, deleted));
      },
    );
  }
}