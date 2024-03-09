import 'dart:developer' as dev;
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
import 'package:string_similarity/string_similarity.dart';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;

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

  late List<String> allLocation;

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

  Future<String> loadLocation() async {
    return await rootBundle.loadString('assets/location.txt');
  }

  Future<List<String>> readLocation() async {
    String file = await loadLocation();

    try {
      List<String> lines = file.split('\n');
      return lines;
    } catch (e) {
      return [];
    }
  }

  Future<void> enablePip() async {
    const rational = Rational.vertical();
    floating.enable(
      aspectRatio: rational,
    );
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

    List<String> allLocation = await readLocation();
    var matches = _speechWord.bestMatch(allLocation);
    var destination =
        await collection.findOne({'name': matches.bestMatch.target});
    if (destination != null && matches.bestMatch.rating! >= 0.7) {
      TextToSpeech().speak('กำลังเปิดการนำทางไปที่ :${destination['name']}');
      enablePip();
      await launchUrl(Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=${destination['lat']},${destination['lng']}&travelmode=walking'));
    }
    setState(() {
      onSpeech = false;

      if (destination == null) {
        TextToSpeech().speak('ฉันไม่รู้จักสถานที่นี้');
        _speechWord = '';
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
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Wrap(
                      direction: Axis.vertical,
                      spacing: 20,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 15),
                          child: FloatingActionButton(
                            backgroundColor:
                                const Color.fromARGB(255, 15, 2, 131),
                            tooltip: 'เพิ่มสถานที่',
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => const UploadImage()));
                            },
                            child: const Icon(Icons.add_a_photo_outlined,
                                color: Colors.white, size: 28),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 15),
                          child: FloatingActionButton(
                            backgroundColor:
                                const Color.fromARGB(255, 15, 2, 131),
                            tooltip: 'ตรวจจับวัตถุ',
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => YoloVideo(
                                  vision: vision,
                                ),
                              ));
                            },
                            child: const Icon(Icons.visibility,
                                color: Colors.white, size: 28),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
                Expanded(
                    flex: 0,
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 200,
                          ),
                          Expanded(
                              child: Center(
                            child: _speechToText.isNotListening ||
                                    _speechWord == ''
                                ? const Text(
                                    'แตะกลางเจอเพื่อพูด',
                                    style: TextStyle(fontSize: 20.0),
                                    textAlign: TextAlign.center,
                                  )
                                : Expanded(
                                    child: Container(
                                      child: _speechWord == ''
                                          ? const Text(
                                              'กำลังฟังชื่อสถานที่...',
                                              style: TextStyle(fontSize: 20.0),
                                              textAlign: TextAlign.center,
                                            )
                                          : Text(
                                              _speechWord,
                                              style: const TextStyle(
                                                  fontSize: 20.0),
                                              textAlign: TextAlign.center,
                                            ),
                                    ),
                                  ),
                          ))
                        ]))
              ],
            ),
          ),
        ),
      ),
      childWhenEnabled: YoloVideo(
        vision: vision,
      ),
    );
  }
}
