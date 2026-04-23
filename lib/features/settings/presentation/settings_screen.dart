import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/founding_doc.dart';
import '../../../core/services/icloud_service.dart';
import '../../../core/models/journal_theme.dart';
import '../../../core/providers/founding_docs_provider.dart';
import '../../../core/providers/journal_providers.dart';
import '../../../core/providers/journal_share_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/providers/theme_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _exporting = false;
  bool _exportingObsidian = false;

  Future<void> _exportToFolder(BuildContext context) async {
    setState(() => _exportingObsidian = true);
    try {
      String? path = await ICloudService.loadExportFolder();
      path ??= await ICloudService.pickExportFolder();

      if (path == null) return; // user cancelled

      final service = await ref.read(journalServiceProvider.future);
      final count = await service.exportToFolder(path);
      await ICloudService.releaseExportFolder();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(count == 0
            ? 'No journal entries to export.'
            : '$count ${count == 1 ? 'entry' : 'entries'} exported.'),
      ));
    } catch (e) {
      await ICloudService.releaseExportFolder();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')));
    } finally {
      if (mounted) setState(() => _exportingObsidian = false);
    }
  }

  Future<void> _exportJournal(BuildContext context) async {
    setState(() => _exporting = true);
    try {
      final service = await ref.read(journalServiceProvider.future);
      final paths = await service.allEntryPaths();

      if (!context.mounted) return;

      if (paths.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No journal entries to export.')),
        );
        return;
      }

      final files = paths.map((p) => XFile(p)).toList();
      final box = context.findRenderObject() as RenderBox?;
      final origin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : Rect.fromLTWH(
              MediaQuery.of(context).size.width / 2,
              MediaQuery.of(context).size.height / 2,
              1,
              1,
            );

      await Share.shareXFiles(
        files,
        subject: 'Portion entries',
        sharePositionOrigin: origin,
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(journalThemeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF8F2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3F2E1F)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF3F2E1F),
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _SectionHeader('Appearance'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theme',
                  style: TextStyle(
                    fontSize: 15,
                    color: const Color(0xFF2C2C2C),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: JournalTheme.values.map((theme) {
                      final isSelected = theme == currentTheme;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () =>
                              ref.read(journalThemeProvider.notifier).select(theme),
                          child: _ThemeCard(theme: theme, isSelected: isSelected),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _SectionHeader('Journal'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                ListTile(
                  title: const Text(
                    'Export entries',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF2C2C2C),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Share all journal entries as Markdown files',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  trailing: _exporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.ios_share, color: Colors.grey[600], size: 20),
                  onTap: _exporting ? null : () => _exportJournal(context),
                ),
                Divider(height: 1, color: Colors.grey[200]),
                _ShareDestinationTile(),
                if (Platform.isMacOS) ...[
                  Divider(height: 1, color: Colors.grey[200]),
                  ListTile(
                    title: const Text(
                      'Export to folder',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF2C2C2C),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Copy all entries to a folder you choose',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    trailing: _exportingObsidian
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.folder_copy_outlined,
                            color: Colors.grey[600], size: 20),
                    onTap: _exportingObsidian
                        ? null
                        : () => _exportToFolder(context),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader('Quick Start'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text(
                    'Show Quick Start Guide',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF2C2C2C),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Displays a guide banner at the top of the home screen',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  value: ref.watch(appSettingsProvider).showQuickStart,
                  activeThumbColor: const Color(0xFF5C6B4A),
                  onChanged: (v) =>
                      ref.read(appSettingsProvider.notifier).setShowQuickStart(v),
                ),
                Divider(height: 1, color: Colors.grey[200]),
                SwitchListTile(
                  title: const Text(
                    'Show Read Aloud controls',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF2C2C2C),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Adds a Read Aloud toggle inside each passage',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  value: ref.watch(appSettingsProvider).showReadAloud,
                  activeThumbColor: const Color(0xFF5C6B4A),
                  onChanged: (v) =>
                      ref.read(appSettingsProvider.notifier).setShowReadAloud(v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader('Founding Documents'),
          _FoundingDocsSettings(),
          const SizedBox(height: 24),
          _SectionHeader('Feedback'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: ListTile(
              title: const Text(
                'Send feedback',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF2C2C2C),
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Feature requests, bug reports, or general feedback',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              trailing: Icon(Icons.mail_outline, color: Colors.grey[600], size: 20),
              onTap: () async {
                final uri = Uri.parse(
                  'mailto:Raldan@proton.me?subject=Portion%20Feedback',
                );
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Logos is a trademark of Faithlife. Portion is not affiliated with or endorsed by Faithlife.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey[400], height: 1.5),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _FoundingDocsSettings extends ConsumerWidget {
  const _FoundingDocsSettings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(foundingDocsEnabledProvider);
    final activeDoc = ref.watch(foundingDocsActiveProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text(
              'Show Founding Documents',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF2C2C2C),
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Adds a reading card below Scripture',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            value: enabled,
            activeThumbColor: const Color(0xFF9C7A5B),
            onChanged: (v) =>
                ref.read(foundingDocsEnabledProvider.notifier).set(v),
          ),
          if (enabled) ...[
            Divider(height: 1, color: Colors.grey[200]),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active document',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<FoundingDocType>(
                    segments: FoundingDocType.values
                        .map((t) => ButtonSegment<FoundingDocType>(
                              value: t,
                              label: Text(t.displayName),
                            ))
                        .toList(),
                    selected: {activeDoc},
                    onSelectionChanged: (s) => ref
                        .read(foundingDocsActiveProvider.notifier)
                        .select(s.first),
                    style: SegmentedButton.styleFrom(
                      foregroundColor: const Color(0xFF9C7A5B),
                      selectedForegroundColor: Colors.white,
                      selectedBackgroundColor: const Color(0xFF9C7A5B),
                      side: const BorderSide(color: Color(0xFF9C7A5B)),
                      textStyle: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ShareDestinationTile extends ConsumerWidget {
  const _ShareDestinationTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dest = ref.watch(journalShareDestinationProvider);
    final label = switch (dest) {
      JournalShareDestination.email => 'Email',
      JournalShareDestination.messages => 'Messages',
      null => 'Not set',
    };

    return ListTile(
      title: const Text(
        'Share entry to',
        style: TextStyle(
          fontSize: 15,
          color: Color(0xFF2C2C2C),
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        label,
        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
      onTap: () => _pick(context, ref),
    );
  }

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final dest = await showDialog<JournalShareDestination>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Share entry to'),
        children: [
          SimpleDialogOption(
            onPressed: () =>
                Navigator.of(ctx).pop(JournalShareDestination.messages),
            child: const Text('Messages'),
          ),
          SimpleDialogOption(
            onPressed: () =>
                Navigator.of(ctx).pop(JournalShareDestination.email),
            child: const Text('Email'),
          ),
        ],
      ),
    );
    if (dest != null) {
      ref.read(journalShareDestinationProvider.notifier).select(dest);
    }
  }
}

/// A small card showing the theme's background thumbnail and accent colour swatch.
class _ThemeCard extends StatelessWidget {
  final JournalTheme theme;
  final bool isSelected;

  const _ThemeCard({required this.theme, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 96,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF5C6B4A)
                  : Colors.grey[300]!,
              width: isSelected ? 2.5 : 1.0,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(theme.bgAsset, fit: BoxFit.cover),
                // Accent colour swatch strip at the bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 16,
                  child: ColoredBox(color: theme.accentColor),
                ),
                if (isSelected)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Color(0xFF5C6B4A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          theme.displayName,
          style: TextStyle(
            fontSize: 11,
            color: isSelected
                ? const Color(0xFF5C6B4A)
                : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey[500],
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
