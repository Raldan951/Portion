import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/reading_plan.dart';
import '../../../core/providers/date_provider.dart';
import '../../../core/providers/journal_providers.dart';
import '../../../core/services/journal_service.dart';
import '../../../core/providers/reading_providers.dart';
import '../../../core/providers/translation_provider.dart';
import '../../../core/services/bible_link_service.dart';
import '../../reading/presentation/passage_screen.dart';

/// Full-screen journal page for a single day.
///
/// Styled as an open notebook — cream background, ruled horizontal lines,
/// left margin rule, Georgia serif. Auto-saves 300 ms after the last keystroke.
///
/// Reading chips at the top let the user open any of the day's passages
/// directly from within the journal. Clipped passages (enqueued by
/// PassageScreen via [clipQueueProvider]) are inserted at the cursor.
class JournalPage extends ConsumerStatefulWidget {
  const JournalPage({super.key});

  @override
  ConsumerState<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends ConsumerState<JournalPage> {
  final _controller = TextEditingController();
  Timer? _debounce;
  bool _initialized = false;

  // Cached so dispose() can save without accessing ref after unmount.
  JournalService? _cachedService;
  String? _cachedDateKey;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    // On macOS the window can be closed (Cmd+W / red button) without going
    // through the AppBar back handler. Flush any pending debounce save now
    // using the cached service so the text isn't lost.
    if ((_debounce?.isActive ?? false) &&
        _cachedService != null &&
        _cachedDateKey != null) {
      final body = _controller.text;
      final svc = _cachedService!;
      final key = _cachedDateKey!;
      _debounce!.cancel();
      unawaited(svc.upsertDocument(key, body));
    } else {
      _debounce?.cancel();
    }
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _saveNow);
  }

  Future<void> _saveNow() async {
    final body = _controller.text;
    try {
      // Use cached service/dateKey if available so this works even after pop.
      final service = _cachedService ??
          (mounted ? await ref.read(journalServiceProvider.future) : null);
      if (service == null) return;
      final dateKey = _cachedDateKey ??
          (mounted
              ? DateFormat('yyyy-MM-dd').format(ref.read(selectedDateProvider))
              : null);
      if (dateKey == null) return;
      _cachedService = service;
      _cachedDateKey = dateKey;
      await service.upsertDocument(dateKey, body);
      if (mounted) ref.invalidate(journalDocumentProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Journal save failed: $e')),
        );
      }
    }
  }

  void _insertClip(String clipText) {
    final current = _controller.text;
    final sel = _controller.selection;
    final insertAt =
        sel.isValid && sel.baseOffset >= 0 ? sel.baseOffset : current.length;

    // Ensure two newlines before the clip if we're mid-document
    final before = current.substring(0, insertAt);
    final after = current.substring(insertAt);
    final prefix =
        (before.isNotEmpty && !before.endsWith('\n\n')) ? '\n\n' : '';
    const suffix = '\n\n';
    final insertion = prefix + clipText + suffix;

    _controller.value = TextEditingValue(
      text: before + insertion + after,
      selection: TextSelection.collapsed(offset: insertAt + insertion.length),
    );
    _saveNow();
  }

  @override
  Widget build(BuildContext context) {
    final docAsync = ref.watch(journalDocumentProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final schedule = ref.watch(todaysScheduleProvider);

    // Initialise the controller once, when the document first resolves.
    // Uses addPostFrameCallback so we never mutate controller or provider
    // state during a build frame (illegal in Flutter and silently breaks
    // things like clip insertion and auto-save).
    if (!_initialized) {
      docAsync.whenData((doc) {
        if (_initialized) return;
        _initialized = true; // set immediately so re-builds don't re-enter
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          // Remove listener before programmatic set so _onTextChanged
          // does not fire (which would start an auto-save of empty text).
          _controller.removeListener(_onTextChanged);
          _controller.text = doc?.body ?? '';
          _controller.addListener(_onTextChanged);
          // Drain any clip that was queued before the page opened.
          final pending = ref.read(clipQueueProvider);
          if (pending != null) {
            _insertClip(pending);
            ref.read(clipQueueProvider.notifier).clear();
          }
        });
      });
    }

    // React to clips enqueued while the page is already open (e.g. user
    // opened PassageScreen from the reading chips and clipped back here).
    ref.listen<String?>(clipQueueProvider, (_, clip) {
      if (clip != null) {
        _insertClip(clip);
        ref.read(clipQueueProvider.notifier).clear();
      }
    });

    final dateLabel = DateFormat('EEEE, MMMM d, y').format(selectedDate);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF7F0),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3A2A)),
          onPressed: () async {
            _debounce?.cancel();
            FocusScope.of(context).unfocus();
            final navigator = Navigator.of(context);
            // Use cached service, or fall back to the already-resolved
            // provider value (synchronous — never hangs).
            final service = _cachedService ??
                ref.read(journalServiceProvider).when(
                  data: (s) => s,
                  loading: () => null,
                  error: (_, _) => null,
                );
            final dateKey = _cachedDateKey ??
                DateFormat('yyyy-MM-dd')
                    .format(ref.read(selectedDateProvider));
            if (service != null) {
              try {
                await service.upsertDocument(dateKey, _controller.text);
              } catch (_) {}
            }
            navigator.pop();
          },
        ),
        title: Text(
          dateLabel,
          style: const TextStyle(
            fontFamily: 'Georgia',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3A2A),
          ),
        ),
      ),
      body: Column(
        children: [
          // Reading chips — tap any passage to open it, then clip back
          if (schedule != null) _ReadingChipsRow(schedule: schedule),
          const Divider(height: 1, thickness: 1, color: Color(0xFFD4C5A9)),

          // The journal page itself
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Stack(
                children: [
                  // Ruled paper background — fills whatever height the text needs
                  Positioned.fill(
                    child: CustomPaint(painter: _RuledLinePainter()),
                  ),

                  // Writing area — transparent over the ruled paper
                  Padding(
                    padding: const EdgeInsets.fromLTRB(64, 14, 24, 120),
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      maxLines: null,
                      minLines: 32,
                      style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 17,
                        height: 1.88,
                        color: Color(0xFF2C2C2C),
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Begin writing\u2026',
                        hintStyle: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 17,
                          color: Color(0xFFB8A898),
                          fontStyle: FontStyle.italic,
                        ),
                        border: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      cursorColor: const Color(0xFF5C6B4A),
                      cursorWidth: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reading chips ─────────────────────────────────────────────────────────────

/// Horizontal row of tappable chips — one per passage in today's readings.
/// Tapping opens PassageScreen; returning from it drops any clip into the page.
class _ReadingChipsRow extends ConsumerWidget {
  final DailySchedule schedule;

  const _ReadingChipsRow({required this.schedule});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translation = ref.watch(selectedTranslationProvider);
    final allReadings = schedule.allReadings;

    return Container(
      color: const Color(0xFFFAF7F0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: allReadings.map((reading) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                avatar: const Icon(
                  Icons.menu_book_outlined,
                  size: 14,
                  color: Color(0xFF5C6B4A),
                ),
                label: Text(
                  reading.display,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF5C6B4A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                backgroundColor: const Color(0xFFEFEADF),
                side: const BorderSide(color: Color(0xFF5C6B4A), width: 0.6),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                onPressed: () async {
                  if (translation.isExternal) {
                    await BibleLinkService.openInLogos(reading);
                  } else {
                    if (context.mounted) {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PassageScreen(
                            reference: reading,
                            translation: translation,
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Ruled paper painter ───────────────────────────────────────────────────────

/// Draws ruled notebook lines and a left margin rule behind the journal text.
///
/// Line spacing (32 px) matches the text's line height (Georgia 17 × 1.88 ≈ 32).
/// The first line is offset to sit beneath the first line of text.
class _RuledLinePainter extends CustomPainter {
  static const double _lineSpacing = 32.0;
  static const double _firstLineY = 46.0; // aligns with first text baseline
  static const double _marginX = 52.0;

  @override
  void paint(Canvas canvas, Size size) {
    // Horizontal rules
    final rulePaint = Paint()
      ..color = const Color(0xFFD4C5A9)
      ..strokeWidth = 0.6;

    double y = _firstLineY;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), rulePaint);
      y += _lineSpacing;
    }

    // Left margin rule (dusty rose — classic college-ruled feel)
    canvas.drawLine(
      Offset(_marginX, 0),
      Offset(_marginX, size.height),
      Paint()
        ..color = const Color(0xFFDDB0A0)
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(_RuledLinePainter old) => false;
}
