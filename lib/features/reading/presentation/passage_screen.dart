import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/bible_verse.dart';
import '../../../core/models/reading_plan.dart';
import '../../../core/models/bible_translation.dart';
import '../../../core/providers/reading_providers.dart';
import '../../../core/services/bible_link_service.dart';

/// Displays a single Bible passage inline.
///
/// Navigated to when the user taps an inline-translation reading (KJV, BSB,
/// WEB). Logos taps bypass this screen and open the external app directly.
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
                      content: Text('Could not open Logos \u2014 is it installed?'),
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
        padding: const EdgeInsets.fromLTRB(48, 32, 48, 48),
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
            const SizedBox(height: 40),
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
        return _VerseText(verses: verses, reference: reference);
      },
    );
  }
}

/// Renders the chapter text as flowing prose with inline verse numbers.
///
/// Uses [SelectableText.rich] so the text can be copied. For multi-chapter
/// readings, a small chapter heading separates each chapter.
class _VerseText extends StatelessWidget {
  final List<BibleVerse> verses;
  final BibleReference reference;

  const _VerseText({required this.verses, required this.reference});

  @override
  Widget build(BuildContext context) {
    final bool multiChapter = reference.chapterEnd != null &&
        reference.chapterEnd != reference.chapter;

    final spans = <InlineSpan>[];
    int? currentChapter;

    for (final verse in verses) {
      if (verse.chapter != currentChapter) {
        if (currentChapter != null) {
          spans.add(const TextSpan(text: '\n\n'));
        }
        if (multiChapter) {
          spans.add(
            TextSpan(
              text: '${reference.book} ${verse.chapter}\n\n',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3A2A),
                letterSpacing: 0.8,
                height: 1.0,
              ),
            ),
          );
        }
        currentChapter = verse.chapter;
      }

      // Verse number — small, olive, inline
      spans.add(
        TextSpan(
          text: '${verse.verse}\u2009',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF5C6B4A),
          ),
        ),
      );

      // Verse text — flows continuously; trailing space joins to next verse
      spans.add(
        TextSpan(
          text: '${verse.text} ',
        ),
      );
    }

    return SelectableText.rich(
      TextSpan(
        style: const TextStyle(
          fontSize: 18,
          color: Color(0xFF2C3A2A),
          height: 1.8,
        ),
        children: spans,
      ),
    );
  }
}

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
