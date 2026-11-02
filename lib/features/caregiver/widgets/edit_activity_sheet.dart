import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/clock.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/activity_icon_data.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/calm_snackbar.dart';
import '../../../core/widgets/suggestion_card.dart';
import '../../../data/models/models.dart';
import '../../../data/providers.dart';
import '../../../domain/schedule_rules.dart';
import '../../../domain/suggestion_engine.dart';
import '../forms/form_field.dart';
import '../forms/form_utils.dart';
import '../forms/icon_picker_sheet.dart';
import '../forms/sheet_scaffold.dart';
import '../forms/time_feedback.dart';
import '../forms/time_picker_sheet.dart';
import 'add_activity_advanced.dart';
import 'change_preview_sheet.dart';
import 'delete_activity_dialog.dart';
import 'suggestion_detail_sheet.dart';

/// Sheet Ubah jadwal (OT-10/11, aturan §8.7).
class EditActivitySheet extends ConsumerStatefulWidget {
  const EditActivitySheet({
    super.key,
    required this.activity,
    required this.child,
    this.prefillStart,
    this.prefillEnd,
    this.suggestionId,
  });

  /// Kegiatan asli seperti tersimpan di state. Dasar pembanding "sebelum"
  /// untuk perubahan inti (§8.7); jangan diisi objek yang sudah dimodifikasi.
  final Activity activity;
  final Child child;

  /// Jam usulan yang sudah terisi di form (mis. dari saran "Geser", §9.2).
  /// [prefillEnd] hanya dipakai bila [prefillStart] diisi.
  final TimeOfDayLite? prefillStart;
  final TimeOfDayLite? prefillEnd;

  /// ID saran asal sheet ini. Setelah perubahan berhasil disimpan, status
  /// saran menjadi `applied` (§9.1).
  final String? suggestionId;

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

  /// True bila pengguna mengisi Nama singkat sendiri di sheet ini. Selain
  /// itu Nama singkat mengikuti Nama bila Nama diubah (§8.6), dan tetap
  /// seperti semula bila Nama tidak diubah.
  bool _shortManual = false;

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
    _start = widget.prefillStart ?? a.start;
    _end = widget.prefillStart != null ? widget.prefillEnd : a.end;
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

  void _syncShortTitle() {
    final title = _titleController.text.trim();
    _shortTitleController.text = title == _original.title
        ? _original.shortTitle
        : shortTitleFromTitle(title);
  }

  void _onTitleChanged(String _) {
    setState(() {
      if (!_shortManual) _syncShortTitle();
    });
  }

  void _onShortTitleChanged(String value) {
    setState(() {
      _shortManual = value.trim().isNotEmpty;
      if (!_shortManual) _syncShortTitle();
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

  Activity _buildCandidate() {
    final built = buildActivity(
      id: _original.id,
      childId: _original.childId,
      title: _titleController.text,
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

  /// Semua perubahan, termasuk yang tidak memicu pesan: tanggal, nama
  /// singkat, langkah, ulangi, mode mandiri.
  bool _anyChanged(Activity candidate) =>
      _coreChanged(candidate) ||
      !isSameDay(candidate.date, _original.date) ||
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

  /// Kartu saran kontekstual waktu tenang (§8.7): kegiatan hasil ubahan
  /// memakai layar dan selesai kurang dari {quietTimeMinutes} sebelum Tidur.
  /// Saran diambil dari mesin saran (§9.1) atas state hipotetis yang memuat
  /// kegiatan hasil ubahan, supaya "Lihat alasannya" membuka detail saran
  /// quietTime yang sebenarnya.
  ({Suggestion suggestion, int gap})? _quietTimeSuggestion(
    AppState state,
    Activity candidate,
  ) {
    if (!candidate.usesScreen || candidate.end == null) return null;
    final hypothetical = state.copyWith(
      activities: [
        for (final a in state.activities) a.id == candidate.id ? candidate : a,
      ],
    );
    final found =
        generateSuggestions(
          hypothetical,
          candidate.date,
          candidate.childId,
        ).where(
          (s) =>
              s.type == SuggestionType.quietTime &&
              s.payload['screenActivityId'] == candidate.id,
        );
    if (found.isEmpty) return null;
    final suggestion = found.first;
    final sleepStart = TimeOfDayLite.fromJson(
      Map<String, dynamic>.from(suggestion.payload['sleepStart'] as Map),
    );
    final gap = sleepStart.toMinutes() - candidate.end!.toMinutes();
    // Data kegiatan hasil ubahan belum tersimpan: sertakan jam selesai dan
    // tanggalnya supaya aksi "Tambahkan waktu tenang" tidak memakai data lama.
    return (
      suggestion: suggestion.copyWith(
        payload: {
          ...suggestion.payload,
          'screenEnd': candidate.end!.toJson(),
          'screenDate': candidate.date.toIso8601String(),
        },
      ),
      gap: gap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final candidate = _buildCandidate();
    final coreChanged = _coreChanged(candidate);
    final anyChanged = _anyChanged(candidate);

    final titleBlank = _titleController.text.trim().isEmpty;
    final shortTitleValid = isValidShortTitle(_shortTitleController.text);
    final quiet = _quietTimeSuggestion(state, candidate);
    final message = _messageController.text.trim();
    final canSave =
        !titleBlank &&
        shortTitleValid &&
        !TimeFeedback.blocksSave(candidate, state.activities) &&
        anyChanged &&
        (!coreChanged || (message.isNotEmpty && message.length <= 120));
    // "Simpan" hanya bila yang berubah cuma bagian di luar nama/ikon/jam
    // (§8.7); selebihnya "Kirim perubahan" (nonaktif sampai ada perubahan).
    final saveLabel = (!coreChanged && anyChanged)
        ? 'Simpan'
        : 'Kirim perubahan';

    return SheetScaffold(
      title: 'Ubah jadwal',
      subtitle: 'Untuk ${widget.child.name} · ${formatDateShort(_date)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label nama dengan ikon pencil (OT-10).
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.grid6),
            child: Row(
              children: [
                Icon(
                  LucideIcons.pencil,
                  size: AppSpacing.iconSize16,
                  color: AppColors.teksSekunder,
                ),
                SizedBox(width: AppSpacing.grid6),
                Text('Nama kegiatan', style: AppTypography.meta),
              ],
            ),
          ),
          FormTextField(
            controller: _titleController,
            hint: 'Nama kegiatan',
            maxLength: 40,
            onChanged: _onTitleChanged,
            errorText: titleBlank ? 'Nama kegiatan wajib diisi.' : null,
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
                    // Selesai kosong hanya untuk Tidur (§8.6): kembalikan.
                    _end ??= defaultEndFor(_start, preferred: _original.end);
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
            childName: widget.child.name,
            onUseSlot: (start, end) => setState(() {
              _start = start;
              _end = end;
            }),
          ),
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
                backgroundColor: AppColors.transparan,
                isScrollControlled: true,
                builder: (ctx) => ChangePreviewSheet(
                  childName: widget.child.name,
                  palette: ChildPalette.fromTheme(widget.child.theme),
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
          if (quiet != null) ...[
            const SizedBox(height: AppSpacing.grid12),
            SuggestionCard(
              content:
                  '${candidate.title} selesai ${quiet.gap} menit sebelum tidur. '
                  'Layar menjelang tidur bisa membuat ${widget.child.name} '
                  'lebih lama tertidur. Tambahkan waktu tenang tanpa layar?',
              actionLabel: 'Lihat alasannya',
              onTap: () => showSuggestionDetailSheet(
                context,
                suggestion: quiet.suggestion,
              ),
            ),
          ],
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
              childName: widget.child.name,
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
    final suggestionId = widget.suggestionId;

    final result = applyActivityEdit(
      state: appState,
      updated: candidate,
      message: coreChanged ? _messageController.text : null,
      now: now,
      noticeId: generateId('notice'),
    );
    // Status saran menjadi applied hanya setelah perubahan tersimpan (§9.1).
    notifier.updateState(
      suggestionId == null
          ? result.state
          : result.state.copyWith(
              suggestionStatus: {
                ...result.state.suggestionStatus,
                suggestionId: SuggestionStatus.applied,
              },
            ),
    );

    Navigator.of(context).pop();
    CalmSnackbar.show(
      context,
      message: coreChanged
          ? 'Perubahan terkirim ke ${widget.child.name}'
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

    // Setelah sheet ditutup, `ref` ikut tidak berlaku (StateError). Ambil
    // container provider sekarang; ia hidup lebih lama daripada sheet, jadi
    // aman dipakai di callback Urungkan.
    final container = ProviderScope.containerOf(context, listen: false);
    final now = container.read(clockProvider).now;

    final deleted = deleteActivity(
      state: container.read(appStateProvider),
      activityId: activity.id,
      now: now,
      noticeId: generateId('notice'),
    );
    container.read(appStateProvider.notifier).updateState(deleted.state);

    Navigator.of(context).pop();
    CalmSnackbar.show(
      context,
      message: '${activity.title} dihapus',
      actionLabel: 'Urungkan',
      onActionPressed: () {
        final current = container.read(appStateProvider);
        container
            .read(appStateProvider.notifier)
            .updateState(undoDeleteActivity(current, deleted));
      },
    );
  }
}
