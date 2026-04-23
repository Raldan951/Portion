import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/bible_verse.dart';
import '../../../core/models/reading_plan.dart';
import '../../../core/models/bible_translation.dart';
import '../../../core/providers/journal_providers.dart';
import '../../../core/providers/reading_providers.dart';
import '../../../core/providers/translation_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/providers/tts_provider.dart';

/// Displays a single Bible passage inline with interactive verse selection.
///
/// Tap a verse number once to anchor a selection (the verse highlights).
/// Tap a second verse number to extend the selection to a range.
/// A Clip pill floats at the bottom — tapping it formats the selected verses
/// and enqueues them in [clipQueueProvider], then pops back to [JournalPage].
class PassageScreen extends StatelessWidget {
  final BibleReference reference;
  final BibleTranslation translation;

  const PassageScreen({
    super.key,
    required this.reference,
    required this.translation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF8F2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3A2A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          reference.display,
          style: const TextStyle(
            color: Color(0xFF2C3A2A),
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
        child: _PassageBody(
          reference: reference,
          translation: translation,
        ),
      ),
    );
  }
}

class _PassageBody extends ConsumerWidget {
  final BibleReference reference;
  final BibleTranslation translation;

  const _PassageBody({required this.reference, required this.translation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!translation.available) {
      return _ComingSoon(translation: translation);
    }

    final end = reference.chapterEnd ?? reference.chapter;
    final chapterAsync = ref.watch(
      chapterProvider((translation, reference.book, reference.chapter, end)),
    );

    return chapterAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          'Could not load passage.\n$e',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
      ),
      data: (verses) {
        if (verses.isEmpty) {
          return const Center(
            child: Text(
              'No text found for this passage.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        return _InteractiveVerseText(verses: verses, reference: reference);
      },
    );
  }
}

// ── Interactive verse text ────────────────────────────────────────────────────

/// Renders verses with tappable verse numbers for selection and clipping.
///
/// Selection model:
///   • First tap on a verse number → that verse becomes the anchor (highlighted).
///   • Tap on any other verse number → range from anchor to that verse fills in.
///   • Tap the anchor verse again (no end selected) → deselects everything.
///   • Subsequent taps adjust the end of the range.
///
/// A Clip pill animates in at the bottom while any selection is active.
/// Tapping it formats the selected text, enqueues it via [clipQueueProvider],
/// then pops back to the calling screen (typically [JournalPage]).
class _InteractiveVerseText extends ConsumerStatefulWidget {
  final List<BibleVerse> verses;
  final BibleReference reference;

  const _InteractiveVerseText({
    required this.verses,
    required this.reference,
  });

  @override
  ConsumerState<_InteractiveVerseText> createState() =>
      _InteractiveVerseTextState();
}

class _InteractiveVerseTextState
    extends ConsumerState<_InteractiveVerseText> {
  // Selection — null means nothing selected
  ({int chapter, int verse})? _anchor;
  ({int chapter, int verse})? _end;

  bool _readAloudActive = false;

  // Cached so dispose() can call stop() without relying on ref validity
  late final TtsNotifier _ttsNotifier;

  @override
  void initState() {
    super.initState();
    _ttsNotifier = ref.read(ttsProvider.notifier);
  }

  @override
  void dispose() {
    _ttsNotifier.stop();
    super.dispose();
  }

  // Sort key that makes cross-chapter comparisons trivial (max 999 verses/chapter)
  static int _key(int chapter, int verse) => chapter * 1000 + verse;

  bool _isSelected(int chapter, int verse) {
    if (_anchor == null) return false;
    final a = _key(_anchor!.chapter, _anchor!.verse);
    final e = _end != null ? _key(_end!.chapter, _end!.verse) : a;
    final k = _key(chapter, verse);
    return k >= (a < e ? a : e) && k <= (a > e ? a : e);
  }

  int get _selectedCount => _anchor == null
      ? 0
      : widget.verses
          .where((v) => _isSelected(v.chapter, v.verse))
          .length;

  void _onVerseNumberTap(int chapter, int verse) {
    // While TTS is active AND read aloud is on, tapping a verse number seeks
    if (_readAloudActive && ref.read(ttsProvider).status != TtsStatus.idle) {
      _seekToVerse(chapter, verse);
      return;
    }
    // Otherwise: clip selection behavior
    setState(() {
      if (_anchor == null) {
        _anchor = (chapter: chapter, verse: verse);
        _end = null;
      } else if (_end == null &&
          chapter == _anchor!.chapter &&
          verse == _anchor!.verse) {
        _anchor = null;
      } else {
        _end = (chapter: chapter, verse: verse);
      }
    });
  }

  void _seekToVerse(int chapter, int verse) {
    final idx = widget.verses.indexWhere(
      (v) => v.chapter == chapter && v.verse == verse,
    );
    if (idx < 0) return;
    ref.read(ttsProvider.notifier).playVerses(widget.verses, startIndex: idx);
    setState(() { _anchor = null; _end = null; });
  }

  void _handleClip() {
    if (_anchor == null) return;

    final a = _anchor!;
    final e = _end ?? a;
    final minKey = _key(a.chapter, a.verse) < _key(e.chapter, e.verse)
        ? (chapter: a.chapter, verse: a.verse)
        : (chapter: e.chapter, verse: e.verse);
    final maxKey = _key(a.chapter, a.verse) > _key(e.chapter, e.verse)
        ? (chapter: a.chapter, verse: a.verse)
        : (chapter: e.chapter, verse: e.verse);

    final selected = widget.verses.where((v) => _isSelected(v.chapter, v.verse)).toList();
    if (selected.isEmpty) return;

    final combinedText = selected.map((v) => v.text).join(' ');

    // Build a readable reference string
    final book = widget.reference.book;
    final String refStr;
    if (minKey.chapter == maxKey.chapter) {
      refStr = minKey.verse == maxKey.verse
          ? '$book ${minKey.chapter}:${minKey.verse}'
          : '$book ${minKey.chapter}:${minKey.verse}\u2013${maxKey.verse}';
    } else {
      refStr =
          '$book ${minKey.chapter}:${minKey.verse}\u2013${maxKey.chapter}:${maxKey.verse}';
    }

    final translation = ref.read(selectedTranslationProvider);
    // ❝ … ❞  —  Reference  Translation
    final clipText =
        '\u275D $combinedText \u275E\n    \u2014 $refStr  ${translation.label}';

    ref.read(clipQueueProvider.notifier).enqueue(clipText);

    setState(() {
      _anchor = null;
      _end = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Clipped to journal'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  void _showVoicePicker(TtsState tts) {
    if (tts.availableVoices.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _VoicePicker(
        voices: tts.availableVoices,
        selected: tts.selectedVoice,
        onSelect: (name) {
          ref.read(ttsProvider.notifier).setVoice(name);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tts = ref.watch(ttsProvider);
    final showReadAloud = ref.watch(appSettingsProvider).showReadAloud;
    final translation = ref.watch(selectedTranslationProvider);

    // Pre-build a flat list of items: chapter headings + verses
    final bool multiChapter = widget.reference.chapterEnd != null &&
        widget.reference.chapterEnd != widget.reference.chapter;
    final items = <_ListItem>[];
    int? lastChapter;
    for (final verse in widget.verses) {
      if (verse.chapter != lastChapter) {
        if (multiChapter) {
          items.add(_ChapterHeadingItem(
              '${widget.reference.book} ${verse.chapter}'));
        }
        lastChapter = verse.chapter;
      }
      items.add(_VerseItem(verse));
    }

    final verseItems = items.whereType<_VerseItem>().toList();
    final bottomPad = _readAloudActive ? 180.0 : 32.0;

    return Column(
      children: [
        // Header: translation badge + optional Read Aloud toggle
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF5C6B4A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                translation.fullName,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF5C6B4A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (showReadAloud) ...[
              const Spacer(),
              Checkbox(
                value: _readAloudActive,
                activeColor: const Color(0xFF5C6B4A),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                onChanged: (v) {
                  setState(() => _readAloudActive = v ?? false);
                  if (!(v ?? false)) _ttsNotifier.stop();
                },
              ),
              const Icon(Icons.volume_up_outlined, size: 13, color: Color(0xFF5C6B4A)),
              const SizedBox(width: 4),
              const Text(
                'Read Aloud',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF5C6B4A),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 2),
            ],
          ],
        ),
        const SizedBox(height: 8),

        // Verse list + overlays
        Expanded(
          child: Stack(
            children: [
              ListView.builder(
                padding: EdgeInsets.only(bottom: bottomPad),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final item = items[i];
                  if (item is _ChapterHeadingItem) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 24, bottom: 8),
                      child: Text(
                        item.text,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2C3A2A),
                          letterSpacing: 0.8,
                        ),
                      ),
                    );
                  }
                  final verse = (item as _VerseItem).verse;
                  final selected = _isSelected(verse.chapter, verse.verse);
                  final verseIdx = verseItems.indexOf(item);
                  final isSpeaking = _readAloudActive &&
                      tts.status != TtsStatus.idle &&
                      tts.currentVerseIndex == verseIdx;
                  return _VerseRow(
                    verse: verse,
                    selected: selected,
                    isSpeaking: isSpeaking,
                    onVerseNumberTap: _onVerseNumberTap,
                    onVerseTextTap: _readAloudActive ? _seekToVerse : (_, _) {},
                  );
                },
              ),

              // TTS control bar — only when Read Aloud is active
              if (_readAloudActive)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _TtsBar(
                    tts: tts,
                    onPlayPause: () {
                      final notifier = ref.read(ttsProvider.notifier);
                      if (tts.status == TtsStatus.playing) {
                        notifier.pause();
                      } else if (tts.status == TtsStatus.paused) {
                        notifier.resume();
                      } else {
                        int startIndex = 0;
                        if (_anchor != null) {
                          final idx = widget.verses.indexWhere(
                            (v) => v.chapter == _anchor!.chapter &&
                                   v.verse == _anchor!.verse,
                          );
                          if (idx >= 0) startIndex = idx;
                        }
                        notifier.playVerses(widget.verses, startIndex: startIndex);
                        setState(() { _anchor = null; _end = null; });
                      }
                    },
                    onStop: () => ref.read(ttsProvider.notifier).stop(),
                    onRateChange: (v) => ref.read(ttsProvider.notifier).setRate(v),
                    onVoiceTap: () => _showVoicePicker(tts),
                  ),
                ),

              // Clip pill — above TTS bar when Read Aloud active, else standard position
              AnimatedSlide(
                offset: _anchor != null ? Offset.zero : const Offset(0, 0.3),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: AnimatedOpacity(
                  opacity: _anchor != null ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 180),
                  child: IgnorePointer(
                    ignoring: _anchor == null,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: _readAloudActive ? 104 : 32,
                        ),
                        child: _ClipPill(
                          verseCount: _selectedCount,
                          onClip: _handleClip,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── TTS bar ───────────────────────────────────────────────────────────────────

class _TtsBar extends StatelessWidget {
  final TtsState tts;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;
  final ValueChanged<double> onRateChange;
  final VoidCallback onVoiceTap;

  const _TtsBar({
    required this.tts,
    required this.onPlayPause,
    required this.onStop,
    required this.onRateChange,
    required this.onVoiceTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = tts.status != TtsStatus.idle;
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: Color(0xFFF3EFE6),
        border: Border(top: BorderSide(color: Color(0xFFDDD8CC), width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // Play / Pause
          IconButton(
            icon: Icon(
              tts.status == TtsStatus.playing
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              size: 28,
            ),
            color: const Color(0xFF5C6B4A),
            onPressed: onPlayPause,
          ),
          // Stop
          IconButton(
            icon: const Icon(Icons.stop_rounded, size: 26),
            color: isActive ? const Color(0xFF5C6B4A) : const Color(0xFFBBB8B0),
            onPressed: isActive ? onStop : null,
          ),
          // Rate slider
          const Text(
            'Speed',
            style: TextStyle(fontSize: 12, color: Color(0xFF5C6B4A)),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: const Color(0xFF5C6B4A),
                inactiveTrackColor: const Color(0xFF5C6B4A).withValues(alpha: 0.25),
                thumbColor: const Color(0xFF5C6B4A),
                overlayColor: const Color(0xFF5C6B4A).withValues(alpha: 0.15),
                trackHeight: 2.5,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              ),
              child: Slider(
                value: tts.speechRate,
                min: 0.25,
                max: 1.0,
                onChanged: onRateChange,
              ),
            ),
          ),
          // Voice button
          TextButton(
            onPressed: tts.availableVoices.isNotEmpty ? onVoiceTap : null,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF5C6B4A),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.record_voice_over_outlined, size: 17),
                SizedBox(width: 4),
                Text('Voice', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Voice picker ──────────────────────────────────────────────────────────────

class _VoicePicker extends StatelessWidget {
  final List<String> voices;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _VoicePicker({
    required this.voices,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Choose Voice',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3A2A),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: voices.length,
              itemBuilder: (_, i) {
                final name = voices[i];
                final isSelected = name == selected;
                return ListTile(
                  title: Text(
                    name,
                    style: TextStyle(
                      fontSize: 15,
                      color: isSelected
                          ? const Color(0xFF5C6B4A)
                          : const Color(0xFF2C3A2A),
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Color(0xFF5C6B4A), size: 18)
                      : null,
                  onTap: () => onSelect(name),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Verse row ─────────────────────────────────────────────────────────────────

/// A single verse: tappable verse number + flowing text.
/// Background warms to amber when selected; soft blue when currently speaking.
class _VerseRow extends StatelessWidget {
  final BibleVerse verse;
  final bool selected;
  final bool isSpeaking;
  final void Function(int chapter, int verse) onVerseNumberTap;
  final void Function(int chapter, int verse) onVerseTextTap;

  const _VerseRow({
    required this.verse,
    required this.selected,
    required this.isSpeaking,
    required this.onVerseNumberTap,
    required this.onVerseTextTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = isSpeaking
        ? const Color(0xFFDCEEFF)
        : selected
            ? const Color(0xFFFFF3C4)
            : Colors.transparent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      color: bg,
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onVerseNumberTap(verse.chapter, verse.verse),
            child: SizedBox(
              width: 24,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${verse.verse}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSpeaking
                        ? const Color(0xFF1A5C9C)
                        : selected
                            ? const Color(0xFF8B6914)
                            : const Color(0xFF5C6B4A),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onVerseTextTap(verse.chapter, verse.verse),
              child: Text(
                '${verse.text} ',
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFF2C3A2A),
                  height: 1.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Clip pill ─────────────────────────────────────────────────────────────────

class _ClipPill extends StatelessWidget {
  final int verseCount;
  final VoidCallback onClip;

  const _ClipPill({required this.verseCount, required this.onClip});

  @override
  Widget build(BuildContext context) {
    final label = verseCount == 1 ? '1 verse' : '$verseCount verses';
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(32),
      color: const Color(0xFF5C6B4A),
      child: InkWell(
        onTap: onClip,
        borderRadius: BorderRadius.circular(32),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.content_cut, color: Colors.white, size: 17),
              const SizedBox(width: 10),
              Text(
                '$label  \u2022  Clip to Journal',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── List item types ───────────────────────────────────────────────────────────

sealed class _ListItem {}

class _ChapterHeadingItem extends _ListItem {
  final String text;
  _ChapterHeadingItem(this.text);
}

class _VerseItem extends _ListItem {
  final BibleVerse verse;
  _VerseItem(this.verse);
}

// ── Coming soon ───────────────────────────────────────────────────────────────

class _ComingSoon extends StatelessWidget {
  final BibleTranslation translation;

  const _ComingSoon({required this.translation});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 56,
            color: const Color(0xFF5C6B4A).withValues(alpha: 0.4),
          ),
          const SizedBox(height: 28),
          Text(
            '${translation.label} is on its way.',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C3A2A),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'We\u2019re building the text library now.\n'
            'Open Logos from the home screen in the meantime.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
