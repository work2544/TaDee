import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:mongo_dart/mongo_dart.dart' show Db, GridFS;
import 'package:flutter/services.dart' show rootBundle;

class UploadImage extends StatefulWidget {
  const UploadImage({super.key});
  @override
  State<UploadImage> createState() => _UploadImageState();
}

class _UploadImageState extends State<UploadImage> {
  var dateTime;
  LocationData? currentLocation;
  late bool _serviceEnabled;
  late PermissionStatus _permissionGranted;

  XFile? mediaFile;
  dynamic _pickImageError;
  String? _retrieveDataError;
  final ImagePicker _picker = ImagePicker();
  bool isConnecting = true;

  final _formKey = GlobalKey<FormState>();
  final _locationName = TextEditingController();

  static Db? db;
  late GridFS bucket;

  List<String>? allLocation;

  Future<String> loadLocation() async {
    return await rootBundle.loadString('assets/location.txt');
  }

  Future<void> readLocation() async {
    String file = await loadLocation();
    LineSplitter ls = const LineSplitter();
    List<String> lines = ls.convert(file);
    setState(() {
      allLocation = lines;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('ตาดี'),
        ),
        body: isConnecting
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : SingleChildScrollView(
                child: Form(
                    key: _formKey,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(children: <Widget>[
                        FormField(builder: (FormFieldState<XFile> file) {
                          return Column(
                            children: <Widget>[
                              Center(child: _previewImages()),
                              const SizedBox(
                                height: 15.0,
                              ),
                              FloatingActionButton(
                                onPressed: pickImageCamera,
                                child: const Icon(Icons.camera_alt),
                              ),
                            ],
                          );
                        }),
                        const SizedBox(
                          height: 15.0,
                        ),
                        allLocation == null
                            ? const Text('กำลังโหลดข้อมูล')
                            : DropdownMenu(
                                initialSelection: allLocation![0],
                                controller: _locationName,
                                requestFocusOnTap: false,
                                label: const Text('ระบุชื่อสถานที่'),
                                dropdownMenuEntries: allLocation!
                                    .map<DropdownMenuEntry<String>>(
                                        (String location) {
                                  return DropdownMenuEntry<String>(
                                    value: location,
                                    label: location,
                                  );
                                }).toList(),
                              ),
                        ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate() &&
                                mediaFile != null) {
                              upload();
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (BuildContext context) =>
                                          super.widget));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('เสร็จสมบูรณ์')),
                              );
                            }
                            if (mediaFile == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('กรุณาถ่ายภาพ')),
                              );
                            }
                          },
                          child: const Text('ยืนยัน'),
                        ),
                      ]),
                    ))));
  }

  void pickImageCamera() async {
    try {
      final pickedImages = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50,
      );
      if (pickedImages == null) return;
      await getCurrentLocation();
      setState(() {
        mediaFile = pickedImages;
      });
    } catch (e) {
      setState(() {
        _pickImageError = e;
      });
    }
  }

  void upload() async {
    try {
      if (mediaFile != null) {}
      final bytes = await File(mediaFile!.path).readAsBytes();

      Map<String, dynamic> image = {
        "name": _locationName.text.replaceAll(' ', ''),
        "lat": currentLocation!.latitude,
        "lng": currentLocation!.longitude,
        "date": dateTime,
        "data": base64Encode(bytes)
      };
      await bucket.chunks.insert(image);
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> getCurrentLocation() async {
    Location location = Location();

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    location.getLocation().then(
      (location) {
        currentLocation = location;
        dateTime = DateTime.now().toUtc().toIso8601String();
      },
    );
  }

  Text? _getRetrieveErrorWidget() {
    if (_retrieveDataError != null) {
      final Text result = Text(_retrieveDataError!);
      _retrieveDataError = null;
      return result;
    }
    return null;
  }

  Widget _previewImages() {
    final Text? retrieveError = _getRetrieveErrorWidget();
    if (retrieveError != null) {
      return retrieveError;
    }
    if (mediaFile != null) {
      return Image.file(File(mediaFile!.path));
    }
    if (_pickImageError != null) {
      return Text(
        'Pick image error: $_pickImageError',
        textAlign: TextAlign.center,
      );
    } else {
      return const Text(
        'กรุณาถ่ายภาพ',
        textAlign: TextAlign.center,
      );
    }
  }

  Future<void> connection() async {
    if (db == null) {
      try {
        db = await Db.create(
            'mongodb+srv://worklao21:0881496697_Zaa@cluster0.b0htsww.mongodb.net/TaDee?retryWrites=true&w=majority');
        await db!.open();
        bucket = GridFS(db!, "TaDee");
        setState(() {
          isConnecting = false;
        });
      } catch (e) {
        log(e.toString());
      }
    } else {
      bucket = GridFS(db!, "TaDee");
      setState(() {
        isConnecting = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
    readLocation();
    connection();
  }

  @override
  void dispose() {
    super.dispose();
    _locationName.dispose();
  }
}
