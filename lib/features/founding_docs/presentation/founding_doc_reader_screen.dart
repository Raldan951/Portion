import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/founding_doc.dart';
import '../../../core/providers/founding_docs_provider.dart';
import '../../../core/providers/journal_providers.dart';

// Entry point for Federalist Papers — opens at the current bookmark segment.
class FederalistReaderScreen extends ConsumerWidget {
  const FederalistReaderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(foundingDocsProvider);
    final bookmark = ref.watch(federalistBookmarkProvider);

    return docsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error loading: $e')),
      ),
      data: (docs) {
        final segs = docs.federalistSegments;
        final idx = bookmark.clamp(0, segs.length - 1);
        return _FoundingDocReaderScreen(
          docType: FoundingDocType.federalistPapers,
          title: segs[idx].cardTitle,
          paragraphs: segs[idx].paragraphs,
          segmentLabel: segs[idx].isMultiPart
              ? 'Part ${segs[idx].segmentInPaper} of ${segs[idx].totalInPaper}'
              : null,
          author: segs[idx].author,
          onMarkRead: () => ref
              .read(federalistBookmarkProvider.notifier)
              .advance(docs.federalistTotalSegments),
        );
      },
    );
  }
}

// Entry point for Declaration / Constitution reference readers.
class DocSectionReaderScreen extends ConsumerWidget {
  final FoundingDocType docType;

  const DocSectionReaderScreen({super.key, required this.docType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(foundingDocsProvider);

    return docsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error loading: $e')),
      ),
      data: (docs) {
        final sections = docType == FoundingDocType.declaration
            ? docs.declarationSections
            : docs.constitutionSections;
        return _MultiSectionReaderScreen(docType: docType, sections: sections);
      },
    );
  }
}

// ── Single-segment reader (Federalist Papers) ─────────────────────────────────

class _FoundingDocReaderScreen extends StatefulWidget {
  final FoundingDocType docType;
  final String title;
  final List<DocParagraph> paragraphs;
  final String? segmentLabel;
  final String? author;
  final VoidCallback? onMarkRead;

  const _FoundingDocReaderScreen({
    required this.docType,
    required this.title,
    required this.paragraphs,
    this.segmentLabel,
    this.author,
    this.onMarkRead,
  });

  @override
  State<_FoundingDocReaderScreen> createState() =>
      _FoundingDocReaderScreenState();
}

class _FoundingDocReaderScreenState extends State<_FoundingDocReaderScreen> {
  int? _clippedParaIdx;

  void _handleLongPress(int idx) {
    setState(() => _clippedParaIdx = idx);
  }

  void _clearClip() {
    setState(() => _clippedParaIdx = null);
  }

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
          widget.docType.fullTitle,
          style: const TextStyle(
            color: Color(0xFF2C3A2A),
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C3A2A),
                  height: 1.3,
                ),
              ),
              if (widget.author != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.author!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              if (widget.segmentLabel != null) ...[
                const SizedBox(height: 2),
                Text(
                  widget.segmentLabel!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
              const SizedBox(height: 24),
              ...widget.paragraphs.map(
                (para) => _ParagraphTile(
                  para: para,
                  isSelected: _clippedParaIdx == para.idx,
                  onLongPress: () => _handleLongPress(para.idx),
                  contextLabel: widget.title,
                ),
              ),
              if (widget.onMarkRead != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                Center(
                  child: FilledButton.icon(
                    onPressed: () {
                      widget.onMarkRead!();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Mark as read — Next'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF5C6B4A),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (_clippedParaIdx != null)
            _ClipPill(
              para: widget.paragraphs[_clippedParaIdx!],
              contextLabel: widget.title,
              onDismiss: _clearClip,
            ),
        ],
      ),
    );
  }
}

// ── Multi-section reader (Declaration / Constitution) ────────────────────────

class _MultiSectionReaderScreen extends StatefulWidget {
  final FoundingDocType docType;
  final List<DocSection> sections;

  const _MultiSectionReaderScreen({
    required this.docType,
    required this.sections,
  });

  @override
  State<_MultiSectionReaderScreen> createState() =>
      _MultiSectionReaderScreenState();
}

class _MultiSectionReaderScreenState
    extends State<_MultiSectionReaderScreen> {
  int? _clippedParaGlobalIdx; // section_idx * 1000 + para_idx (unique key)
  String _clippedContextLabel = '';
  DocParagraph? _clippedPara;

  void _handleLongPress(DocSection section, DocParagraph para) {
    setState(() {
      _clippedParaGlobalIdx = section.sectionIdx * 1000 + para.idx;
      _clippedContextLabel = section.title;
      _clippedPara = para;
    });
  }

  void _clearClip() {
    setState(() {
      _clippedParaGlobalIdx = null;
      _clippedPara = null;
    });
  }

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
          widget.docType.fullTitle,
          style: const TextStyle(
            color: Color(0xFF2C3A2A),
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
      ),
      body: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 80),
            itemCount: widget.sections.length,
            itemBuilder: (context, i) {
              final section = widget.sections[i];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (i > 0) const SizedBox(height: 32),
                  Text(
                    section.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2C3A2A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...section.paragraphs.map(
                    (para) => _ParagraphTile(
                      para: para,
                      isSelected: _clippedParaGlobalIdx ==
                          section.sectionIdx * 1000 + para.idx,
                      onLongPress: () => _handleLongPress(section, para),
                      contextLabel: section.title,
                    ),
                  ),
                ],
              );
            },
          ),
          if (_clippedPara != null)
            _ClipPill(
              para: _clippedPara!,
              contextLabel: _clippedContextLabel,
              onDismiss: _clearClip,
            ),
        ],
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _ParagraphTile extends StatelessWidget {
  final DocParagraph para;
  final bool isSelected;
  final VoidCallback onLongPress;
  final String contextLabel;

  const _ParagraphTile({
    required this.para,
    required this.isSelected,
    required this.onLongPress,
    required this.contextLabel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF5C6B4A).withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '¶${para.idx + 1}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[400],
                  height: 1.8,
                  fontFamily: 'Georgia',
                ),
              ),
            ),
            Expanded(
              child: Text(
                para.text,
                style: const TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 16,
                  color: Color(0xFF2C2C2C),
                  height: 1.7,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClipPill extends ConsumerWidget {
  final DocParagraph para;
  final String contextLabel;
  final VoidCallback onDismiss;

  const _ClipPill({
    required this.para,
    required this.contextLabel,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      left: 24,
      right: 24,
      bottom: 32,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(32),
        color: const Color(0xFF3F2E1F),
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: () {
            final clip =
                '> ¶${para.idx + 1} — $contextLabel\n> ${para.text}';
            ref.read(clipQueueProvider.notifier).enqueue(clip);
            onDismiss();
            Navigator.of(context).pop();
          },
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.content_cut, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text(
                  'Clip ¶${para.idx + 1} to Journal',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: onDismiss,
                  child: const Icon(Icons.close, color: Colors.white70, size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
