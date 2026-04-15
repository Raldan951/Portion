import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/providers/journal_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _exporting = false;

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
        subject: 'BibleJournal entries',
        sharePositionOrigin: origin,
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          _SectionHeader('Journal'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: ListTile(
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
          ),
        ],
      ),
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
