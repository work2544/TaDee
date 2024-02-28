import 'dart:developer' as dev;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:mongo_dart/mongo_dart.dart' show Db, DbCollection;
import 'package:tadeeflutter/uploadimage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/texttospeech.dart';
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

  late FlutterVision vision;
  final floating = Floating();
  final myController = TextEditingController(text: '5');

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
    myController.dispose();
    await vision.closeYoloModel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    const rational = Rational.vertical();
    final screenSize =
        MediaQuery.of(context).size * MediaQuery.of(context).devicePixelRatio;
    final height = screenSize.width ~/ rational.aspectRatio;
    if (lifecycleState == AppLifecycleState.inactive) {
      floating.enable(
        //aspectRatio: const Rational.vertical(),
        sourceRectHint: Rectangle<int>(
          0,
          0,
          screenSize.width.toInt(),
          height,
        ),
      );
    }
  }

  Future<void> enablePip() async {
    Size screenSize =
        WidgetsBinding.instance.platformDispatcher.views.first.physicalSize;

    const rational = Rational.vertical();

    final height = screenSize.width ~/ rational.aspectRatio;

    final status = await floating.enable(
      //aspectRatio: rational,
      sourceRectHint: Rectangle<int>(
        0,
        (screenSize.height ~/ 2) - (height ~/ 2),
        screenSize.width.toInt(),
        height,
      ),
    );
    debugPrint('PiP enabled? $status');
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
      TextToSpeech().speak('กำลังเปิดการนำทางไปที่ :${destination['name']}');
      enablePip();
      await launchUrl(Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=${destination['lat']},${destination['lng']}&travelmode=walking'));
    }
    setState(() {
      onSpeech = false;
      if (destination == null) {
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
          TextToSpeech().speak('กรุณาแตะกลางหน้าจอแล้วพูดชื่อสถานที่');
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
                  TextField(
                    controller: myController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter a time duration',
                    ),
                  ),
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
                ],
              ),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
          floatingActionButton: FloatingActionButton(
            backgroundColor: const Color.fromARGB(255, 15, 2, 131),
            tooltip: 'เพิ่มสถานที่',
            onPressed: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const UploadImage()));
            },
            child: const Icon(Icons.camera_alt_outlined,
                color: Colors.white, size: 28),
          ),
        ),
      ),
      childWhenEnabled: YoloVideo(
        vision: vision,
        intputduration: int.parse(myController.text),
      ),
    );
  }
}
