import 'package:url_launcher/url_launcher.dart';
import '../models/reading_plan.dart';

/// Builds external Bible links and launches them.
///
/// Currently supports the Logos deep-link scheme (logosres:).
/// Designed to grow: future providers (BibleGateway, ESV API, etc.)
/// will be added here without touching the UI layer.
class BibleLinkService {
  /// Builds a Logos deep-link for the given [reference] and [version].
  ///
  /// Format confirmed from Pete's Obsidian reference vault:
  ///   logosres:nkjv;ref=BibleNKJV.Genesis.1
  ///   logosres:nkjv;ref=BibleNKJV.1%20Kings.5
  ///
  /// Spaces in book names are encoded as %20 (as Logos expects).
  /// Only the start chapter is used for ranges — Logos opens at that point.
  static String logosUrl(BibleReference ref, {String version = 'nkjv'}) {
    final versionUpper = version.toUpperCase();
    final encodedBook = ref.book.replaceAll(' ', '%20');
    return 'logosres:$version;ref=Bible$versionUpper.$encodedBook.${ref.chapter}';
  }

  /// Opens [ref] in the Logos app.
  ///
  /// Returns true if Logos was launched successfully.
  /// Returns false if Logos is not installed or the link could not be opened.
  static Future<bool> openInLogos(
    BibleReference ref, {
    String version = 'nkjv',
  }) async {
    final url = logosUrl(ref, version: version);
    // Uri.parse handles the logosres: opaque URI scheme correctly.
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri);
    }
    return false;
  }
}
