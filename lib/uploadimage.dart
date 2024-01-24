import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mongo_dart/mongo_dart.dart' show Db, GridFS;

class UploadImage extends StatefulWidget {
  final double sourceLat;
  final double sourceLng;
  const UploadImage(this.sourceLat, this.sourceLng, {super.key});

  @override
  State<UploadImage> createState() => _UploadImageState();
}

class _UploadImageState extends State<UploadImage> {
  XFile? mediaFile;
  dynamic _pickImageError;
  String? _retrieveDataError;
  final ImagePicker _picker = ImagePicker();
  bool isConnecting = true;

  final _formKey = GlobalKey<FormState>();
  final _locationName = TextEditingController();

  final url =
      'mongodb+srv://worklao21:0881496697_Zaa@cluster0.b0htsww.mongodb.net/TaDee?retryWrites=true&w=majority';
  late GridFS bucket;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('TaDee'),
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
                        TextFormField(
                          decoration: const InputDecoration(
                            icon: Icon(Icons.location_city_rounded),
                            helperText: 'ระบุชื่อสถานที่',
                          ),
                          controller: _locationName,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'โปรดระบุชื่อสถานที่';
                            }
                            return null;
                          },
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate() ||
                                mediaFile != null) {
                              upload();
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (BuildContext context) =>
                                          super.widget));
                              ScaffoldMessenger.of(context).showSnackBar(
                                // นำค่าข้อมูลไปแสดงหรือใช้งานผ่าน controller
                                const SnackBar(content: Text('เสร็จสมบูรณ์')),
                              );
                            }
                            if (mediaFile == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                // นำค่าข้อมูลไปแสดงหรือใช้งานผ่าน controller
                                const SnackBar(content: Text('กรุณาถ่ายภาพ')),
                              );
                            }
                          },
                          child: const Text('Submit'),
                        ),
                      ]),
                    ))));
  }

  void pickImageCamera() async {
    try {
      final pickedImages = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (pickedImages == null) return;

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
    final bytes = await File(mediaFile!.path).readAsBytes();

    Map<String, dynamic> image = {
      "name": _locationName.text,
      "lat": widget.sourceLat,
      "lng": widget.sourceLng,
      "data": base64Encode(bytes)
    };
    await bucket.chunks.insert(image);
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
        'You have not yet picked an image.',
        textAlign: TextAlign.center,
      );
    }
  }

  Future connection() async {
    Db db = await Db.create(url);
    await db.open();
    bucket = GridFS(db, "image");
  }

  @override
  void initState() {
    super.initState();
    connection();
    setState(() {
      isConnecting = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
    _locationName.dispose();
  }
}
