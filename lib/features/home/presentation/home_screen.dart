import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/bible_translation.dart';
import '../../../core/models/reading_plan.dart';
import '../../../core/providers/date_provider.dart';
import '../../../core/providers/journal_providers.dart';
import '../../../core/providers/reading_providers.dart';
import '../../../core/providers/translation_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/services/bible_link_service.dart';
import '../../../core/services/reading_plan_service.dart';
import '../../founding_docs/presentation/founding_doc_reader_screen.dart';
import '../../journal/presentation/journal_page.dart';
import '../../reading/presentation/passage_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../../core/models/founding_doc.dart';
import '../../../core/providers/founding_docs_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(journalThemeProvider);

    final schedule = ref.watch(todaysScheduleProvider);
    final planAsync = ref.watch(activePlanProvider);
    final planName = planAsync.whenOrNull(data: (plan) => plan.name);
    final totalDays = planAsync.whenOrNull(
      data: (plan) => plan.schedule.length,
    );

    // When iCloud syncs a journal file, reload the document provider.
    ref.listen(journalWatcherProvider, (_, _) {
      ref.invalidate(journalDocumentProvider);
    });

    final w = MediaQuery.of(context).size.width;
    final hPad = w < 600
        ? 20.0
        : w < 900
        ? 40.0
        : 72.0;
    final cardPad = w < 600
        ? 20.0
        : w < 900
        ? 32.0
        : 52.0;
    final topPad = w < 600 ? 32.0 : 52.0;

    return Scaffold(
      // The desk texture Container covers only the screen viewport.
      // On iOS the SingleChildScrollView renders off-screen content on the
      // Scaffold background — set it to the texture's dark base tone so
      // white text and buttons don't disappear against white when scrolled.
      backgroundColor: theme.scaffoldFallbackColor,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(theme.bgAsset),
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
                              'Thy Word is a lamp unto my feet\nand a Light unto my path',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (ref.watch(appSettingsProvider).showQuickStart) ...[
                  const SizedBox(height: 16),
                  const _QuickStartBanner(),
                ],
                const SizedBox(height: 32),
                const _DateNavigator(),
                const SizedBox(height: 40),

                if (ref.watch(planJustCompletedProvider)) ...[
                  const _PlanCompletionBanner(),
                  const SizedBox(height: 24),
                ],

                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: AssetImage(theme.cardBgAsset),
                        fit: BoxFit.cover,
                        opacity: theme.cardOpacity,
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
                          InkWell(
                            onTap: () => _showPlanSelector(context, ref),
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 2,
                                horizontal: 2,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    planName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.swap_horiz,
                                    size: 14,
                                    color: Colors.grey[500],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (schedule != null && totalDays != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Day ${schedule.day} of $totalDays',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ],
                        const SizedBox(height: 28),
                        const _TranslationSelector(),
                        const SizedBox(height: 40),

                        if (schedule != null) ...[
                          ...schedule.sections
                              .asMap()
                              .entries
                              .where((e) => e.value.readings.isNotEmpty)
                              .map(
                                (e) => _ReadingSection(
                                  section: e.value,
                                  sectionIndex: e.key,
                                ),
                              ),
                          const _SyncPlanButton(),
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
                const SizedBox(height: 20),
                const _DateNavigator(compact: true),

                if (ref.watch(foundingDocsEnabledProvider)) ...[
                  const SizedBox(height: 56),
                  const _FoundingDocsCard(),
                ],

                const SizedBox(height: 48),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.settings,
                          color: Colors.white.withValues(alpha: 0.65),
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.65),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'build 37',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.4),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
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

  void _showPlanSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _PlanSelector(),
    );
  }
}

/// Shown on the first day of a new plan cycle (user-anchored mode only).
///
/// Quiet acknowledgment — warm but unobtrusive. Disappears automatically
/// the following day as the cycle banner condition no longer holds.
class _PlanCompletionBanner extends ConsumerWidget {
  const _PlanCompletionBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planName = ref
        .watch(activePlanProvider)
        .whenOrNull(data: (plan) => plan.name);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF5C6B4A).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF5C6B4A).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Color(0xFF5C6B4A),
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Plan complete',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3F2E1F),
                  ),
                ),
                if (planName != null)
                  Text(
                    'You\'ve finished $planName. Beginning again from Day 1.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A group of tappable readings for one section of the day's schedule.
///
/// If [section.label] is non-null a header is shown (e.g. 'Morning').
/// Plans that don't use time-of-day framing omit the label entirely.
class _ReadingSection extends StatelessWidget {
  final ReadingSection section;
  final int sectionIndex;

  const _ReadingSection({required this.section, required this.sectionIndex});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section.label != null) ...[
            Text(
              section.label!,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
            ),
            const SizedBox(height: 10),
          ],
          ...section.readings.asMap().entries.map(
            (e) => _TappableReading(
              reference: e.value,
              sectionIndex: sectionIndex,
              readingIndex: e.key,
            ),
          ),
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
/// translations, or launches Logos directly for the Logos segment.
///
/// When the global "show checkboxes" setting is on, a completion checkbox
/// appears to the left. Tapping it marks/unmarks the reading without
/// navigating away.
class _TappableReading extends ConsumerWidget {
  final BibleReference reference;
  final int sectionIndex;
  final int readingIndex;

  const _TappableReading({
    required this.reference,
    required this.sectionIndex,
    required this.readingIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translation = ref.watch(selectedTranslationProvider);

    Future<void> openReading() async {
      if (translation.isExternal) {
        final launched = await BibleLinkService.openInLogos(reference);
        if (!launched && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open Logos \u2014 is it installed?'),
            ),
          );
        }
      } else {
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  PassageScreen(reference: reference, translation: translation),
            ),
          );
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: openReading,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
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
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const JournalPage())),
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
                        final preview = text.length > 160
                            ? '${text.substring(0, 160)}\u2026'
                            : text;
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
/// Forward navigation is unrestricted — users can read ahead freely.
/// A pill appears when viewing a past date, a future date, or when a new
/// calendar day has become available mid-session.
class _DateNavigator extends ConsumerWidget {
  const _DateNavigator({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final notifier = ref.read(selectedDateProvider.notifier);
    final isToday = notifier.isToday;
    final isFuture = notifier.isFuture;
    final newDayAvailable = notifier.newDayAvailable;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _NavArrow(
              icon: Icons.chevron_left,
              onTap: notifier.goBack,
              compact: compact,
            ),
            Flexible(
              child: Column(
                children: [
                  Text(
                    DateFormat('EEEE').format(date),
                    style: compact
                        ? const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          )
                        : Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: compact ? 2 : 4),
                  Text(
                    DateFormat('MMMM d, y').format(date),
                    style: compact
                        ? TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.8),
                          )
                        : Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            _NavArrow(
              icon: Icons.chevron_right,
              onTap: notifier.goForward,
              compact: compact,
            ),
          ],
        ),
        if (!isToday || newDayAvailable) ...[
          SizedBox(height: compact ? 8 : 16),
          TextButton(
            onPressed: notifier.goToToday,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF3F2E1F),
              backgroundColor: Colors.white.withValues(alpha: 0.88),
              padding: compact
                  ? const EdgeInsets.symmetric(horizontal: 12, vertical: 4)
                  : const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              isFuture ? 'You\'re ahead — Return to Today' : 'Return to Today',
              style: TextStyle(
                fontSize: compact ? 10 : 13,
                fontWeight: FontWeight.w600,
              ),
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
  final bool compact;

  const _NavArrow({required this.icon, this.onTap, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final size = compact ? 28.0 : 52.0;
    final iconSize = compact ? 16.0 : 30.0;
    // GestureDetector with opaque hit-testing is more reliable than
    // Material+InkWell inside a ScrollView on iOS — no gesture arena conflict.
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: iconSize),
      ),
    );
  }
}

/// Bottom sheet for switching the active reading plan.
///
/// Tapping a plan card expands it to reveal start mode options.
/// The user chooses "Start today" (Day 1 from today) or "Follow the calendar"
/// (use day-of-year). M'Cheyne shows an additional note about seasonal alignment.
class _PlanSelector extends ConsumerStatefulWidget {
  const _PlanSelector();

  @override
  ConsumerState<_PlanSelector> createState() => _PlanSelectorState();
}

class _PlanSelectorState extends ConsumerState<_PlanSelector> {
  String? _expandedPlanId;

  void _activate(String planId, bool startToday) {
    ref.read(selectedPlanIdProvider.notifier).select(planId);
    if (startToday) {
      ref.read(planStartProvider.notifier).setStartDate(planId, DateTime.now());
    } else {
      ref.read(planStartProvider.notifier).setCalendar(planId);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = ref.watch(selectedPlanIdProvider);
    final startModes = ref.watch(planStartProvider);
    final plans = ReadingPlanService.availablePlans;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Fixed header ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 4, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: Colors.grey[500],
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Text(
              'Reading Plan',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3F2E1F),
              ),
            ),
          ),
          // ── Scrollable plan list ──────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...plans.map((plan) {
                    final isSelected = plan.id == selectedId;
                    final isExpanded = _expandedPlanId == plan.id;
                    final startMode = startModes[plan.id];
                    final currentModeLabel =
                        (startMode == null || startMode == 'calendar')
                        ? (plan.calendarAligned
                              ? 'Following the calendar'
                              : 'Synced with Plan')
                        : 'Started $startMode';

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _expandedPlanId = isExpanded ? null : plan.id;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF5C6B4A).withValues(alpha: 0.1)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF5C6B4A)
                                : Colors.grey[200]!,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Header row ──────────────────────────────────────
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        plan.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: Color(0xFF3F2E1F),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        plan.author,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        plan.description,
                                        maxLines: isExpanded ? 10 : 2,
                                        overflow: isExpanded
                                            ? TextOverflow.visible
                                            : TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700],
                                          height: 1.4,
                                        ),
                                      ),
                                      if (isSelected && !isExpanded) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          currentModeLabel,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: const Color(
                                              0xFF5C6B4A,
                                            ).withValues(alpha: 0.8),
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isSelected) ...[
                                      const Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF5C6B4A),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    Icon(
                                      isExpanded
                                          ? Icons.expand_less
                                          : Icons.expand_more,
                                      color: isSelected
                                          ? const Color(0xFF5C6B4A)
                                          : Colors.grey[400],
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // ── Start mode choice (expanded only) ───────────────
                            if (isExpanded) ...[
                              const SizedBox(height: 14),
                              const Divider(height: 1),
                              const SizedBox(height: 14),
                              Text(
                                'When would you like to begin?',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _StartButton(
                                      label: 'Start today',
                                      sublabel: 'You\'ll be on Day 1',
                                      onTap: () => _activate(plan.id, true),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _StartButton(
                                      label: plan.calendarAligned
                                          ? 'Follow the calendar'
                                          : 'Sync with Plan',
                                      sublabel: plan.calendarAligned
                                          ? 'Picks up where the plan is today'
                                          : 'Your position is set by today\'s date',
                                      onTap: () => _activate(plan.id, false),
                                    ),
                                  ),
                                ],
                              ),
                              if (plan.id == 'mcheyne') ...[
                                const SizedBox(height: 10),
                                Text(
                                  'M\'Cheyne aligns specific passages with seasons '
                                  'of the church year — Advent, Easter, and others. '
                                  '"Follow the calendar" honours that design.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: () async {
                                  final day = await showDialog<int>(
                                    context: context,
                                    builder: (_) => const _DayEntryDialog(),
                                  );
                                  if (day != null) {
                                    ref
                                        .read(selectedPlanIdProvider.notifier)
                                        .select(plan.id);
                                    ref
                                        .read(planStartProvider.notifier)
                                        .setDay(plan.id, day);
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                    }
                                  }
                                },
                                child: Center(
                                  child: Text(
                                    'Jump to a specific day →',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: const Color(
                                        0xFF5C6B4A,
                                      ).withValues(alpha: 0.8),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown at the bottom of the reading card for non-calendar plans.
///
/// Navigates the user to the currently viewed day, then re-anchors the plan
/// so that day becomes today. Only visible when viewing a non-today date.
class _SyncPlanButton extends ConsumerWidget {
  const _SyncPlanButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planId = ref.watch(selectedPlanIdProvider);
    final meta = ReadingPlanService.availablePlans.firstWhere(
      (p) => p.id == planId,
      orElse: () => ReadingPlanService.availablePlans.first,
    );
    if (meta.calendarAligned) return const SizedBox.shrink();

    ref.watch(selectedDateProvider); // rebuild when date changes
    if (ref.read(selectedDateProvider.notifier).isToday) {
      return const SizedBox.shrink();
    }

    final schedule = ref.watch(todaysScheduleProvider);
    if (schedule == null) return const SizedBox.shrink();
    final planDay = schedule.day;

    return Column(
      children: [
        Divider(height: 1, color: Colors.grey[300]),
        const SizedBox(height: 14),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _confirmSync(context, ref, planId, planDay),
                child: Text(
                  'Sync plan to this day →',
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF5C6B4A).withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _showInfo(context),
                child: Icon(
                  Icons.help_outline,
                  size: 15,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmSync(
    BuildContext context,
    WidgetRef ref,
    String planId,
    int planDay,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sync plan to this day?'),
        content: Text(
          'Day $planDay will become your current day. '
          'Your plan position will be adjusted so today\'s readings '
          'match where you are now.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sync Plan'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(planStartProvider.notifier).setDay(planId, planDay);
      ref.read(selectedDateProvider.notifier).goToToday();
    }
  }

  void _showInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sync Plan'),
        content: const Text(
          'Adjusts your plan position so the day you\'re currently '
          'viewing becomes today. Use this if you\'ve fallen behind '
          'or read ahead and want to reset where you are in the plan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Dialog for entering a specific day number to jump to in a reading plan.
class _DayEntryDialog extends StatefulWidget {
  const _DayEntryDialog();

  @override
  State<_DayEntryDialog> createState() => _DayEntryDialogState();
}

class _DayEntryDialogState extends State<_DayEntryDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value < 1) {
      setState(() => _error = 'Enter a day number (1 or higher)');
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Jump to Day'),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        autofocus: true,
        decoration: InputDecoration(hintText: 'e.g. 47', errorText: _error),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: const Text('Go')),
      ],
    );
  }
}

/// Card below the Scripture reading card showing the current Founding Document.
///
/// Federalist Papers: shows the bookmarked segment with a preview and mark-read
/// action. Declaration / Constitution: shows a single "Read" entry.
/// A three-pill selector at the bottom switches between documents.
class _FoundingDocsCard extends ConsumerWidget {
  const _FoundingDocsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeDoc = ref.watch(foundingDocsActiveProvider);
    final docsAsync = ref.watch(foundingDocsProvider);
    final bookmark = ref.watch(federalistBookmarkProvider);

    final w = MediaQuery.of(context).size.width;
    final cardPad = w < 600
        ? 20.0
        : w < 900
        ? 32.0
        : 52.0;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: const DecorationImage(
            image: AssetImage('assets/images/AmerFlag.jpg'),
            fit: BoxFit.cover,
            opacity: 0.15,
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
                  Icons.history_edu,
                  size: 38,
                  color: Color(0xFF9C7A5B),
                ),
                const SizedBox(width: 24),
                Text(
                  'Founding Docs',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Content area ──────────────────────────────────────────────
            docsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Loading…', style: TextStyle(color: Colors.grey)),
              ),
              error: (e, _) =>
                  Text('Error: $e', style: const TextStyle(color: Colors.red)),
              data: (docs) {
                if (activeDoc == FoundingDocType.federalistPapers) {
                  final segs = docs.federalistSegments;
                  final idx = bookmark.clamp(0, segs.length - 1);
                  final seg = segs[idx];
                  return _FederalistCardBody(
                    seg: seg,
                    totalSegments: docs.federalistTotalSegments,
                  );
                } else {
                  return _ReferenceDocCardBody(docType: activeDoc);
                }
              },
            ),

            const SizedBox(height: 24),

            // ── Document selector pills ────────────────────────────────────
            Wrap(
              spacing: 8,
              children: FoundingDocType.values.map((type) {
                final isActive = type == activeDoc;
                return GestureDetector(
                  onTap: () => ref
                      .read(foundingDocsActiveProvider.notifier)
                      .select(type),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF9C7A5B).withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFF9C7A5B)
                            : Colors.grey.withValues(alpha: 0.4),
                        width: isActive ? 1.5 : 1.0,
                      ),
                    ),
                    child: Text(
                      type.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isActive
                            ? const Color(0xFF9C7A5B)
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FederalistCardBody extends ConsumerWidget {
  final FederalistSegment seg;
  final int totalSegments;

  const _FederalistCardBody({required this.seg, required this.totalSegments});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = seg.paragraphs.isNotEmpty ? seg.paragraphs.first.text : '';
    final previewText = preview.length > 120
        ? '${preview.substring(0, 120)}…'
        : preview;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          seg.cardTitle,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF3F2E1F),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          seg.author,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
        if (seg.isMultiPart) ...[
          const SizedBox(height: 2),
          Text(
            'Part ${seg.segmentInPaper} of ${seg.totalInPaper}',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
        const SizedBox(height: 10),
        Text(
          previewText,
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 14,
            color: Colors.grey[700],
            height: 1.5,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const FederalistReaderScreen(),
                ),
              ),
              child: const Text(
                'Read →',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF9C7A5B),
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFF9C7A5B),
                ),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => ref
                  .read(federalistBookmarkProvider.notifier)
                  .advance(totalSegments),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Mark as read',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReferenceDocCardBody extends StatelessWidget {
  final FoundingDocType docType;

  const _ReferenceDocCardBody({required this.docType});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            docType.fullTitle,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3F2E1F),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DocSectionReaderScreen(docType: docType),
            ),
          ),
          child: const Text(
            'Read →',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF9C7A5B),
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: Color(0xFF9C7A5B),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Quick Start Banner ────────────────────────────────────────────────────────

class _QuickStartBanner extends StatelessWidget {
  const _QuickStartBanner();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showGuide(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.menu_book_outlined,
              size: 20,
              color: Color(0xFF5C6B4A),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Quick Start Guide',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3F2E1F),
                ),
              ),
            ),
            const Text(
              'Start here →',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF5C6B4A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGuide(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _QuickStartSheet(),
    );
  }
}

class _QuickStartSheet extends StatelessWidget {
  const _QuickStartSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BibleJournal',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3F2E1F),
                        ),
                      ),
                      Text(
                        'Quick Start — a guide for new readers',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: Colors.grey[400],
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: Colors.grey[200]),
          // Content
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              children: const [
                _QsSection(
                  title: 'WHAT IS THIS?',
                  body:
                      'A quiet reading companion built around the M\'Cheyne plan — four passages a day, calibrated to the church calendar. Open it, read, write what moves you, close it. That\'s the whole idea.\n\nThink of it as a desk you return to each morning.',
                ),
                _QsSection(
                  title: 'GETTING STARTED',
                  body:
                      'Your reading plan and translation are set and waiting on the main screen. The passages for today are already there.\n\nTo switch plans or adjust where you are in a plan, tap the plan name — the small italic line just beneath the word Reading.\n\nYou can also choose your Bible translation there: KJV, BSB, or Logos if you have it installed.',
                ),
                _QsSection(
                  title: 'READING AT YOUR OWN PACE',
                  body:
                      'BibleJournal doesn\'t track streaks or mark you absent. Come back after a week away — your plan is right where you left it, no guilt attached.\n\nUse the arrows on either side of the date to move forward or back. Read ahead if you\'re on a roll. Catch up when life settles. When you\'re ready to return to today, a "Return to Today" pill will appear — one tap brings you home.\n\nWelcome back. Just read.',
                ),
                _QsSection(
                  title: 'PICKING UP WHERE YOU LEFT OFF',
                  body:
                      'Been away for a few days? Navigate back to the last day you read and tap Sync Plan at the bottom of the reading card — you\'ll land on today with those readings waiting.',
                ),
                _QsSection(
                  title: 'CLIPPING VERSES',
                  body:
                      'Open any passage from the reading card. Tap a verse number to anchor a selection — tap a second to extend the range. A Clip pill floats up at the bottom; tap it and the selected verses are formatted as a block quote, attributed with the reference and translation, and sent straight to your journal entry.\n\nClipped verses land at the cursor in your journal. From there, use the standard copy, cut, and paste to arrange them however you like.',
                ),
                _QsSection(
                  title: 'LISTEN TO A PASSAGE',
                  body:
                      'Check the Read Aloud box at the top of any passage to enable listening mode. Tap the play button to begin — the passage is read verse by verse, with the current verse highlighted in blue.\n\nTap any verse to jump to that point. Use the Speed slider to slow things down or speed them up. Tap Voice to choose from any English voice installed on your device.\n\nThe default system voices are serviceable but thin. The enhanced and premium voices are dramatically better — natural pacing, clear diction, easy to follow. Worth the download.\n\nOn iPhone or iPad:\nSettings → Accessibility → Spoken Content → Voices → English → tap a voice → Download.\nLook for voices marked Enhanced or Premium. Siri voices (where available) are excellent.\n\nOn Mac:\nSystem Settings → Accessibility → Spoken Content → System Voice → Manage Voices → download any Enhanced voice under English.\n\nOnce downloaded, they appear immediately in the Voice picker inside BibleJournal. No restart needed.',
                ),
                _QsSection(
                  title: 'THE JOURNAL',
                  body:
                      'Tap Open journal to write. It saves automatically as you type — there\'s no save button, nothing to lose.\n\nWhen you want a copy for yourself, tap the share icon in the upper right. The first time, it will ask whether you prefer Email or Messages — your entry lands wherever you already look for things.',
                ),
                _QsSection(
                  title: 'FOUNDING DOCUMENTS (OPTIONAL)',
                  body:
                      'Settings → Show Founding Documents adds a daily reading from the Federalist Papers, the Declaration of Independence, or the Constitution below your Scripture card. Toggle it off to hide.',
                ),
                _QsSection(
                  title: 'SENDING FEEDBACK',
                  body:
                      'Take a screenshot of anything that confuses you or breaks. TestFlight will offer to attach it to a feedback report — that comes straight to us with your device information included. No email, no form to find.\n\nIf something delights you, that\'s worth a screenshot too.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QsSection extends StatelessWidget {
  final String title;
  final String body;

  const _QsSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF5C6B4A),
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF3F2E1F),
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}

/// A compact two-line button used inside the plan start mode chooser.
class _StartButton extends StatelessWidget {
  final String label;
  final String sublabel;
  final VoidCallback onTap;

  const _StartButton({
    required this.label,
    required this.sublabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF5C6B4A).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF5C6B4A).withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3F2E1F),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
