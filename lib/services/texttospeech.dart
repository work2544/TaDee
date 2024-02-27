import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeech {
  //Instance
  static final TextToSpeech _instance = TextToSpeech._internal();

  //TTS
  final double volume = 1;
  final double pitch = 1.0;
  final double rate = 0.7;
  final String language = 'th-TH';
  final String engine = 'com.google.android.tts';
  late FlutterTts flutterTts;

  factory TextToSpeech() {
    return _instance;
  }

  TextToSpeech._internal() {
    // initialization logic
    flutterTts = FlutterTts();
    _setAwaitOptions();
    flutterTts.setLanguage(language);
    flutterTts.setEngine(engine);
    flutterTts.setInitHandler(() {});
    flutterTts.setVolume(volume);
    flutterTts.setSpeechRate(rate);
    flutterTts.setPitch(pitch);
  }

  Future _setAwaitOptions() async {
    await flutterTts.awaitSpeakCompletion(true);
  }

  Future<void> callSpeak(String newVoiceText) async {
    if (newVoiceText.isNotEmpty) {
      await flutterTts.speak(newVoiceText);
    }
  }

  void speak(String newVoiceText) {
    callSpeak(newVoiceText);
  }

  void stop() {
    flutterTts.stop();
  }
}
