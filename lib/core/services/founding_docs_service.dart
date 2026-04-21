import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/founding_doc.dart';

class FoundingDocsService {
  static const _assetPath = 'assets/data/founding_docs.json';

  FoundingDocs? _cache;

  Future<FoundingDocs> load() async {
    _cache ??= FoundingDocs.fromJson(
      json.decode(await rootBundle.loadString(_assetPath))
          as Map<String, dynamic>,
    );
    return _cache!;
  }
}
