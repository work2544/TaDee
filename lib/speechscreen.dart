import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:mongo_dart/mongo_dart.dart' show Db, DbCollection;
import 'package:url_launcher/url_launcher.dart';

class SpeechScreen extends StatefulWidget {
  const SpeechScreen({super.key});

  @override
  State<SpeechScreen> createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  final SpeechToText _speechToText = SpeechToText();
  String _speechWord = '';
  bool initSpeech = false;
  bool onSpeech = false;

  late DbCollection collection;
  static Db? db;
  bool isConnecting = true;
  var destination;

  late FlutterTts flutterTts;
  String? language = 'th-TH';
  String? engine = 'com.google.android.tts';
  bool get isAndroid => Platform.isAndroid;
  double volume = 1;
  double pitch = 1.0;
  double rate = 0.5;

  @override
  void initState() {
    super.initState();
    _connection();
  }

  void _initSpeech() async {
    await _speechToText.initialize();

    setState(() {
      initSpeech = true;
      log('done _initSpeech');
    });
  }

  void _startListening() async {
    await _speechToText.listen(
      onResult: _onSpeechResult,
      pauseFor: const Duration(seconds: 4),
    );
    setState(() {
      log('start listening');
      onSpeech = true;
    });
  }

  void _stopListening() async {
    await _speechToText.stop();
    destination = await collection.findOne({'name': _speechWord});
    if (destination != null) {
      await launchUrl(Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=${destination['lat']},${destination['lng']}&travelmode=walking'));
    }
    setState(() {
      log('stop listening');
      onSpeech = false;
      if (destination != null) {
        log('destination ${destination['name']} ${destination['lat']} ${destination['lng']}');
      }
      else{
        _speak('ฉันไม่รู้จักสถานที่นี้');
      }
    });
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _speechWord = result.recognizedWords.replaceAll(' ', '');
      if (_speechToText.isNotListening && onSpeech) {
        _stopListening();
      }
    });
  }

  Future<void> _connection() async {
    if (db == null) {
      try {
        db = await Db.create(
            'mongodb+srv://worklao21:0881496697_Zaa@cluster0.b0htsww.mongodb.net/TaDee?retryWrites=true&w=majority');
        await db!.open();
        collection = db!.collection('TaDee.chunks');
        _initSpeech();
        _initTts();
        setState(() {
          log('done connection');
          _speak('กรุณาแตะหน้าจอแล้วพูดชื่อสถานที่');
          isConnecting = false;
        });
      } catch (e) {
        log(e.toString());
      }
    } else {
      setState(() {
        isConnecting = false;
      });
    }
  }

  _initTts() {
    flutterTts = FlutterTts();
    _setAwaitOptions();
    if (isAndroid) {
      _getDefaultVoice();
    }

    if (isAndroid) {
      flutterTts.setInitHandler(() {
        setState(() {
          log('done initTTS');
        });
      });
    }
  }

  Future _getDefaultVoice() async {
    var voice = await flutterTts.getDefaultVoice;
    if (voice != null) {
      log(voice.toString());
    }
  }

  Future _speak(String newVoiceText) async {
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);

    if (newVoiceText.isNotEmpty) {
      await flutterTts.speak(newVoiceText);
    }
  }

  Future _setAwaitOptions() async {
    await flutterTts.awaitSpeakCompletion(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => {
          if (initSpeech)
            {
              _speechToText.isNotListening
                  ? _startListening()
                  : _stopListening()
            }
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(16),
                child: const Text(
                  'กำลังฟังชื่อสถานที่:',
                  style: TextStyle(fontSize: 20.0),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _speechWord,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _speechToText.isNotListening.toString(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
