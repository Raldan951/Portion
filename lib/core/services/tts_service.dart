import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();

  void Function()? onComplete;
  void Function()? onError;

  Future<void> init() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setCompletionHandler(() => onComplete?.call());
    _tts.setErrorHandler((_) => onError?.call());
  }

  Future<List<String>> englishVoices() async {
    final raw = await _tts.getVoices as List<dynamic>?;
    if (raw == null) return [];
    return raw
        .cast<Map>()
        .where((v) {
          final locale = (v['locale'] as String? ?? '').toLowerCase();
          return locale.startsWith('en');
        })
        .map((v) => v['name'] as String)
        .toList()
      ..sort();
  }

  Future<void> speak(String text) => _tts.speak(text);

  Future<void> pause() => _tts.pause();

  Future<void> stop() => _tts.stop();

  Future<void> setRate(double rate) => _tts.setSpeechRate(rate);

  Future<void> setVoice(String name) =>
      _tts.setVoice({'name': name, 'locale': 'en-US'});
}
