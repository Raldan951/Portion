enum FoundingDocType {
  federalistPapers,
  declaration,
  constitution;

  String get displayName => switch (this) {
        FoundingDocType.federalistPapers => 'Federalist',
        FoundingDocType.declaration => 'Declaration',
        FoundingDocType.constitution => 'Constitution',
      };

  String get fullTitle => switch (this) {
        FoundingDocType.federalistPapers => 'The Federalist Papers',
        FoundingDocType.declaration => 'Declaration of Independence',
        FoundingDocType.constitution => 'The Constitution',
      };
}

class DocParagraph {
  final int idx;
  final String text;

  const DocParagraph({required this.idx, required this.text});

  factory DocParagraph.fromJson(Map<String, dynamic> j) =>
      DocParagraph(idx: j['idx'] as int, text: j['text'] as String);
}

class FederalistSegment {
  final int segmentIdx;
  final int paperNumber;
  final String paperTitle;
  final String author;
  final int segmentInPaper;
  final int totalInPaper;
  final List<DocParagraph> paragraphs;

  const FederalistSegment({
    required this.segmentIdx,
    required this.paperNumber,
    required this.paperTitle,
    required this.author,
    required this.segmentInPaper,
    required this.totalInPaper,
    required this.paragraphs,
  });

  factory FederalistSegment.fromJson(Map<String, dynamic> j) =>
      FederalistSegment(
        segmentIdx: j['segment_idx'] as int,
        paperNumber: j['paper_number'] as int,
        paperTitle: j['paper_title'] as String,
        author: j['author'] as String,
        segmentInPaper: j['segment_in_paper'] as int,
        totalInPaper: j['total_in_paper'] as int,
        paragraphs: (j['paragraphs'] as List)
            .map((p) => DocParagraph.fromJson(p as Map<String, dynamic>))
            .toList(),
      );

  String get cardTitle => 'No. $paperNumber — $paperTitle';
  bool get isMultiPart => totalInPaper > 1;
}

class DocSection {
  final int sectionIdx;
  final String title;
  final List<DocParagraph> paragraphs;

  const DocSection({
    required this.sectionIdx,
    required this.title,
    required this.paragraphs,
  });

  factory DocSection.fromJson(Map<String, dynamic> j) => DocSection(
        sectionIdx: j['section_idx'] as int,
        title: j['title'] as String,
        paragraphs: (j['paragraphs'] as List)
            .map((p) => DocParagraph.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}

class FoundingDocs {
  final String federalistTitle;
  final int federalistTotalSegments;
  final List<FederalistSegment> federalistSegments;
  final String declarationTitle;
  final List<DocSection> declarationSections;
  final String constitutionTitle;
  final List<DocSection> constitutionSections;

  const FoundingDocs({
    required this.federalistTitle,
    required this.federalistTotalSegments,
    required this.federalistSegments,
    required this.declarationTitle,
    required this.declarationSections,
    required this.constitutionTitle,
    required this.constitutionSections,
  });

  factory FoundingDocs.fromJson(Map<String, dynamic> j) {
    final fp = j['federalist_papers'] as Map<String, dynamic>;
    final decl = j['declaration'] as Map<String, dynamic>;
    final const_ = j['constitution'] as Map<String, dynamic>;
    return FoundingDocs(
      federalistTitle: fp['title'] as String,
      federalistTotalSegments: fp['total_segments'] as int,
      federalistSegments: (fp['segments'] as List)
          .map((s) => FederalistSegment.fromJson(s as Map<String, dynamic>))
          .toList(),
      declarationTitle: decl['title'] as String,
      declarationSections: (decl['sections'] as List)
          .map((s) => DocSection.fromJson(s as Map<String, dynamic>))
          .toList(),
      constitutionTitle: const_['title'] as String,
      constitutionSections: (const_['sections'] as List)
          .map((s) => DocSection.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
