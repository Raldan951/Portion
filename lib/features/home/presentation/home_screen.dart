import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/bible_translation.dart';
import '../../../core/models/reading_plan.dart';
import '../../../core/providers/date_provider.dart';
import '../../../core/providers/journal_providers.dart';
import '../../../core/providers/reading_providers.dart';
import '../../../core/providers/translation_provider.dart';
import '../../../core/services/bible_link_service.dart';
import '../../journal/presentation/journal_page.dart';
import '../../reading/presentation/passage_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const String bgImage = 'assets/images/desk_texture.jpg';
    const String cardBgImage = 'assets/images/aramaic2.jpg';
    const double cardOpacity = 0.15;

    final schedule = ref.watch(todaysScheduleProvider);
    final planName = ref.watch(mcheynePlanProvider).whenOrNull(
      data: (plan) => plan.name,
    );

    final w = MediaQuery.of(context).size.width;
    final hPad = w < 600 ? 20.0 : w < 900 ? 40.0 : 72.0;
    final cardPad = w < 600 ? 20.0 : w < 900 ? 32.0 : 52.0;
    final topPad = w < 600 ? 32.0 : 52.0;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(bgImage),
            fit: BoxFit.cover,
            opacity: 1.0,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(hPad, topPad, hPad, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === Bible Journal Heading / Logo Area ===
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.menu_book,
                        size: 48,
                        color: Color(0xFF3F2E1F),
                      ),
                      const SizedBox(width: 16),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BibleJournal',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: const Color(0xFF3F2E1F),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            Text(
                              'v2 • Your reading, study and prayer aid',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                const _DateNavigator(),
                const SizedBox(height: 40),

                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: AssetImage(cardBgImage),
                        fit: BoxFit.cover,
                        opacity: cardOpacity,
                      ),
                    ),
                    padding: EdgeInsets.all(cardPad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.bookmark_border,
                              size: 38,
                              color: Color(0xFF5C6B4A),
                            ),
                            const SizedBox(width: 24),
                            Text(
                              'Reading',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ],
                        ),
                        if (planName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            planName,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),
                        const _TranslationSelector(),
                        const SizedBox(height: 40),

                        if (schedule != null) ...[
                          _ReadingSection(
                            label: 'Morning',
                            readings: schedule.morning,
                          ),
                          _ReadingSection(
                            label: 'Evening',
                            readings: schedule.evening,
                          ),
                        ] else
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'Loading readings\u2026',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 88),

                Text(
                  'Your Journal',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 28),
                const _JournalPreviewCard(),

                const SizedBox(height: 120),
                Center(
                  child: Opacity(
                    opacity: 0.78,
                    child: Text(
                      'This is your quiet space.\nThe Scriptures themselves are the real Park.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A labelled group of tappable readings (Morning or Evening).
class _ReadingSection extends StatelessWidget {
  final String label;
  final List<BibleReference> readings;

  const _ReadingSection({required this.label, required this.readings});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
          ),
          const SizedBox(height: 10),
          ...readings.map((ref) => _TappableReading(reference: ref)),
        ],
      ),
    );
  }
}

/// Horizontal segmented picker for choosing the active Bible translation.
/// Lives inside the reading card, just above the passage list.
class _TranslationSelector extends ConsumerWidget {
  const _TranslationSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedTranslationProvider);

    return SegmentedButton<BibleTranslation>(
      segments: BibleTranslation.values.map((t) {
        return ButtonSegment<BibleTranslation>(
          value: t,
          label: Text(t.label),
          tooltip: t.available ? t.fullName : '${t.fullName} — coming soon',
        );
      }).toList(),
      selected: {selected},
      onSelectionChanged: (Set<BibleTranslation> selection) {
        ref.read(selectedTranslationProvider.notifier).select(selection.first);
      },
      style: SegmentedButton.styleFrom(
        foregroundColor: const Color(0xFF5C6B4A),
        selectedForegroundColor: Colors.white,
        selectedBackgroundColor: const Color(0xFF5C6B4A),
        side: const BorderSide(color: Color(0xFF5C6B4A)),
      ),
    );
  }
}

/// A single reading passage — taps open PassageScreen for inline
/// translations, or launch Logos directly for the Logos segment.
class _TappableReading extends ConsumerWidget {
  final BibleReference reference;

  const _TappableReading({required this.reference});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translation = ref.watch(selectedTranslationProvider);

    return InkWell(
      onTap: () async {
        if (translation.isExternal) {
          // Logos: open the passage directly in the external app.
          final launched = await BibleLinkService.openInLogos(reference);
          if (!launched && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not open Logos \u2014 is it installed?'),
              ),
            );
          }
        } else {
          // Inline translation: navigate to the reading screen.
          if (context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PassageScreen(
                  reference: reference,
                  translation: translation,
                ),
              ),
            );
          }
        }
      },
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              reference.display,
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF5C6B4A),
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFF5C6B4A),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              translation.isExternal ? Icons.open_in_new : Icons.menu_book,
              size: 14,
              color: const Color(0xFF5C6B4A),
            ),
          ],
        ),
      ),
    );
  }
}

/// Journal preview card on the home screen.
///
/// Shows the first few lines of today's document (or a prompt if empty).
/// Tapping opens the full [JournalPage].
class _JournalPreviewCard extends ConsumerWidget {
  const _JournalPreviewCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docAsync = ref.watch(journalDocumentProvider);
    final w = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const JournalPage()),
      ),
      child: Card(
        elevation: 4,
        color: const Color(0xFFFAF7F0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(w < 600 ? 24.0 : 44.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.edit_note,
                    color: Color(0xFF5C6B4A),
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: docAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (err, st) => const SizedBox.shrink(),
                      data: (doc) {
                        final text = doc?.body.trim() ?? '';
                        if (text.isEmpty) {
                          return const Text(
                            'Tap to begin writing\u2026',
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 16,
                              color: Color(0xFFB8A898),
                              fontStyle: FontStyle.italic,
                            ),
                          );
                        }
                        final preview =
                            text.length > 160 ? '${text.substring(0, 160)}\u2026' : text;
                        return Text(
                          preview,
                          style: const TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 15,
                            color: Color(0xFF2C2C2C),
                            height: 1.6,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Open journal \u2192',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF5C6B4A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Floating date navigation bar — lives between the greeting and reading card.
///
/// Day of week large, full date below. Circle arrow buttons on each side.
/// Forward arrow fades when on today (the anchor). A warm "Return to Today"
/// pill appears only when viewing a past date.
class _DateNavigator extends ConsumerWidget {
  const _DateNavigator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final notifier = ref.read(selectedDateProvider.notifier);
    final today = DateTime.now();
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _NavArrow(
              icon: Icons.chevron_left,
              onTap: notifier.goBack,
            ),
            Flexible(
              child: Column(
                children: [
                  Text(
                    DateFormat('EEEE').format(date),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMMM d, y').format(date),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            _NavArrow(
              icon: Icons.chevron_right,
              onTap: isToday ? null : notifier.goForward,
              dimmed: isToday,
            ),
          ],
        ),
        if (!isToday) ...[
          const SizedBox(height: 16),
          TextButton(
            onPressed: notifier.goToToday,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF3F2E1F),
              backgroundColor: Colors.white.withValues(alpha: 0.88),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Return to Today',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
    );
  }
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool dimmed;

  const _NavArrow({required this.icon, this.onTap, this.dimmed = false});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: dimmed ? 0.28 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }
}
