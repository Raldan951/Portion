/// The Bible translations the app can work with.
///
/// [available] marks whether the text is currently bundled and readable inline.
enum BibleTranslation {
  kjv(
    label: 'KJV',
    fullName: 'King James Version',
    available: true,
  ),
  bsb(
    label: 'BSB',
    fullName: 'Berean Standard Bible',
    available: true,
  ),
  logos(
    label: 'Logos',
    fullName: 'Open in Logos',
    available: true,
  );

  const BibleTranslation({
    required this.label,
    required this.fullName,
    required this.available,
  });

  /// Short label shown in the SegmentedButton.
  final String label;

  /// Full descriptive name shown in tooltips and detail screens.
  final String fullName;

  /// Whether this translation's text is bundled and readable inline.
  final bool available;

  bool get isExternal => this == BibleTranslation.logos;
}
