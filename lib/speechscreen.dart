import 'dart:developer' as dev;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:mongo_dart/mongo_dart.dart' show Db, DbCollection;
import 'package:url_launcher/url_launcher.dart';
import 'services/texttospeech.dart';
import 'dart:math';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:tadeeflutter/services/yolovideo.dart';
import 'package:floating/floating.dart';

class SpeechScreen extends StatefulWidget {
  const SpeechScreen({super.key});

  @override
  State<SpeechScreen> createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen>
    with WidgetsBindingObserver {
  final SpeechToText _speechToText = SpeechToText();

  String _speechWord = '';
  bool initSpeech = false;
  bool onSpeech = false;

  late DbCollection collection;
  static Db? db;
  bool isConnecting = true;

  TextToSpeech customTTs = TextToSpeech();

  late FlutterVision vision;
  final floating = Floating();

  @override
  void initState() {
    super.initState();
    _connection();
    WidgetsBinding.instance.addObserver(this);
    WidgetsFlutterBinding.ensureInitialized();

    vision = FlutterVision();
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    TextToSpeech().stop();
    WidgetsBinding.instance.removeObserver(this);
    floating.dispose();
    await vision.closeYoloModel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.inactive) {
      floating.enable(aspectRatio: const Rational.square());
      dev.log('lifecycleState == AppLifecycleState.inactive');
    }
    dev.log('didChangeAppLifecycleState');
  }

  Future<void> enablePip() async {
    const rational = Rational.vertical();
    FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;
    Size size = view.physicalSize;
    double width = size.width;
    final height = width ~/ rational.aspectRatio;

    final status = await floating.enable(
      aspectRatio: rational,
      sourceRectHint: Rectangle<int>(
        0,
        (height ~/ 2) - (height ~/ 2),
        width.toInt(),
        height,
      ),
    );
    dev.log('PiP enabled? $status');
  }

  void _initSpeech() async {
    await _speechToText.initialize();
    setState(() {
      initSpeech = true;
    });
  }

  void _startListening() async {
    await _speechToText.listen(
      onResult: _onSpeechResult,
      pauseFor: const Duration(seconds: 4),
    );
    setState(() {
      onSpeech = true;
    });
  }

  void _stopListening() async {
    await _speechToText.stop();
    var destination = await collection.findOne({'name': _speechWord});
    if (destination != null) {
      TextToSpeech().speak('กำลังเปิดการนำทาง');
      enablePip();
      await launchUrl(Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=${destination['lat']},${destination['lng']}&travelmode=walking'));
    }
    setState(() {
      onSpeech = false;
      if (destination != null) {
        dev.log(
            'destination ${destination['name']} ${destination['lat']} ${destination['lng']}');
      } else {
        TextToSpeech().speak('ฉันไม่รู้จักสถานที่นี้');
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
        setState(() {
          TextToSpeech().speak('กรุณาแตะหน้าจอแล้วพูดชื่อสถานที่');
          isConnecting = false;
        });
      } catch (e) {
        dev.log(e.toString());
      }
    } else {
      _initSpeech();
      setState(() {
        isConnecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PiPSwitcher(
      childWhenDisabled: Scaffold(
        body: Scaffold(
          appBar: AppBar(),
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => {
              if (initSpeech)
                {if (_speechToText.isNotListening) _startListening()}
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
        ),
      ),
      childWhenEnabled: YoloVideo(vision: vision),
    );
  }
}
