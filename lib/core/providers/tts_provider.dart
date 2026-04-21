import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bible_verse.dart';
import '../services/tts_service.dart';

enum TtsStatus { idle, playing, paused }

class TtsState {
  final TtsStatus status;
  final int currentVerseIndex;
  final double speechRate;
  final String? selectedVoice;
  final List<String> availableVoices;

  const TtsState({
    this.status = TtsStatus.idle,
    this.currentVerseIndex = -1,
    this.speechRate = 0.5,
    this.selectedVoice,
    this.availableVoices = const [],
  });

  TtsState copyWith({
    TtsStatus? status,
    int? currentVerseIndex,
    double? speechRate,
    String? selectedVoice,
    List<String>? availableVoices,
  }) =>
      TtsState(
        status: status ?? this.status,
        currentVerseIndex: currentVerseIndex ?? this.currentVerseIndex,
        speechRate: speechRate ?? this.speechRate,
        selectedVoice: selectedVoice ?? this.selectedVoice,
        availableVoices: availableVoices ?? this.availableVoices,
      );
}

class TtsNotifier extends Notifier<TtsState> {
  late final TtsService _service;
  List<BibleVerse> _verses = [];

  @override
  TtsState build() {
    _service = TtsService();
    _service.onComplete = _onVerseComplete;
    _service.onError = _onError;
    _init();
    return const TtsState();
  }

  Future<void> _init() async {
    await _service.init();
    final voices = await _service.englishVoices();
    state = state.copyWith(availableVoices: voices);
  }

  void _onVerseComplete() {
    if (state.status != TtsStatus.playing) return;
    final next = state.currentVerseIndex + 1;
    if (next >= _verses.length) {
      _verses = [];
      state = state.copyWith(status: TtsStatus.idle, currentVerseIndex: -1);
      return;
    }
    state = state.copyWith(currentVerseIndex: next);
    _service.speak(_verses[next].text);
  }

  void _onError() {
    _verses = [];
    state = state.copyWith(status: TtsStatus.idle, currentVerseIndex: -1);
  }

  Future<void> playVerses(List<BibleVerse> verses, {int startIndex = 0}) async {
    if (verses.isEmpty) return;
    await _service.stop();
    _verses = verses;
    final idx = startIndex.clamp(0, verses.length - 1);
    state = state.copyWith(status: TtsStatus.playing, currentVerseIndex: idx);
    await _service.speak(verses[idx].text);
  }

  Future<void> pause() async {
    if (state.status != TtsStatus.playing) return;
    await _service.stop();
    state = state.copyWith(status: TtsStatus.paused);
  }

  Future<void> resume() async {
    if (state.status != TtsStatus.paused) return;
    final idx = state.currentVerseIndex;
    if (idx < 0 || idx >= _verses.length) {
      state = state.copyWith(status: TtsStatus.idle, currentVerseIndex: -1);
      return;
    }
    state = state.copyWith(status: TtsStatus.playing);
    await _service.speak(_verses[idx].text);
  }

  Future<void> stop() async {
    await _service.stop();
    _verses = [];
    state = state.copyWith(status: TtsStatus.idle, currentVerseIndex: -1);
  }

  Future<void> setRate(double rate) async {
    state = state.copyWith(speechRate: rate);
    await _service.setRate(rate);
  }

  Future<void> setVoice(String name) async {
    state = state.copyWith(selectedVoice: name);
    await _service.setVoice(name);
  }
}

final ttsProvider = NotifierProvider<TtsNotifier, TtsState>(TtsNotifier.new);
