import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/bible_verse.dart';
import '../../../core/models/reading_plan.dart';
import '../../../core/models/bible_translation.dart';
import '../../../core/providers/journal_providers.dart';
import '../../../core/providers/reading_providers.dart';
import '../../../core/providers/translation_provider.dart';
import '../../../core/services/bible_link_service.dart';

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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () async {
                final launched = await BibleLinkService.openInLogos(reference);
                if (!launched && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Could not open Logos \u2014 is it installed?'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Open in Logos'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF5C6B4A),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF5C6B4A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                translation.fullName,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF5C6B4A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Expanded(
              child: _PassageBody(
                reference: reference,
                translation: translation,
              ),
            ),
          ],
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
    setState(() {
      if (_anchor == null) {
        // First tap — set anchor
        _anchor = (chapter: chapter, verse: verse);
        _end = null;
      } else if (_end == null &&
          chapter == _anchor!.chapter &&
          verse == _anchor!.verse) {
        // Tap same verse with nothing else selected → clear
        _anchor = null;
      } else {
        // Extend or adjust range end
        _end = (chapter: chapter, verse: verse);
      }
    });
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

  @override
  Widget build(BuildContext context) {
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

    return Stack(
      children: [
        // Verse list
        ListView.builder(
          padding: const EdgeInsets.only(bottom: 120),
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
            return _VerseRow(
              verse: verse,
              selected: selected,
              onVerseNumberTap: _onVerseNumberTap,
            );
          },
        ),

        // Clip pill — slides in when a selection exists
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
                  padding: const EdgeInsets.only(bottom: 32),
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
    );
  }
}

// ── Verse row ─────────────────────────────────────────────────────────────────

/// A single verse: tappable verse number + flowing text.
/// Background warms to amber when the verse is within the active selection.
class _VerseRow extends StatelessWidget {
  final BibleVerse verse;
  final bool selected;
  final void Function(int chapter, int verse) onVerseNumberTap;

  const _VerseRow({
    required this.verse,
    required this.selected,
    required this.onVerseNumberTap,
  });

  @override
  Widget build(BuildContext context) {
    // Row-based layout replaces RichText+WidgetSpan. GestureDetector inside
    // WidgetSpan has broken hit-testing on iOS (especially verse 1). A plain
    // Row with a fixed-width verse-number column is fully reliable on all
    // platforms and matches the standard Bible app layout.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      color: selected ? const Color(0xFFFFF3C4) : Colors.transparent,
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
                    color: selected
                        ? const Color(0xFF8B6914)
                        : const Color(0xFF5C6B4A),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${verse.text} ',
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF2C3A2A),
                height: 1.8,
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
            'Use \u201cOpen in Logos\u201d above in the meantime.',
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
