import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_liveness_app/take_cropped_picture.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

import 'face_detection_page.dart';
import 'package:image/image.dart' as img;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await requestCameraPermission();

  runApp(const MyApp());
}

/// Requests camera permission from the user.
Future<void> requestCameraPermission() async {
  final status = await Permission.camera.request();
  if (!status.isGranted) {
    // Handle permission denial
    runApp(const PermissionDeniedApp());
  }
}

class PermissionDeniedApp extends StatelessWidget {
  const PermissionDeniedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("Permission Denied")),
        body: Center(
          child: AlertDialog(
            title: const Text("Permission Denied"),
            content: const Text("Camera access is required for verification."),
            actions: [
              TextButton(
                onPressed: () => SystemNavigator.pop(),
                child: const Text("OK"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: 'Material App', home: HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? capturedImagePath;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  Uint8List? returnCaptureImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.amberAccent,
        toolbarHeight: 70,
        centerTitle: true,
        title: const Text('Verify Your Identity'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (capturedImagePath != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(capturedImagePath!),
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              const Text(
                'Please click the button below to start verification',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.amberAccent,
                ),
                onPressed: () async {
                  final cameras = await availableCameras();
                  if (cameras.isNotEmpty) {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FaceDetectionPage(),
                      ),
                    );
                    if (result is String) {
                      setState(() {
                        capturedImagePath = result;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Verification Successful!')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Camera not active!')),
                    );
                  }
                },
                child: const Text(
                  'Verify Now',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.amberAccent,
                ),
                onPressed: () async {
                  // _launchCamera().then((Value) {
                  //   cropImage(_imageFile!.path).then((croppedFile) {
                  //     if (croppedFile != null) {
                  //       setState(() {
                  //         _readNIDFromImage(_imageFile!);
                  //       });
                  //     } else {
                  //       ScaffoldMessenger.of(context).showSnackBar(
                  //         const SnackBar(content: Text('Crop cancelled')),
                  //       );
                  //     }
                  //   });
                  // });
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TakeCroppedPicture()),
                  ).then((returnImage) {
                    setState(() {
                      returnCaptureImage = Uint8List.fromList(
                        img.encodeJpg(returnImage!),
                      );
                    });
                  });
                },
                child: const Text(
                  'Capture NID',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              returnCaptureImage != null
                  ? Image.memory(returnCaptureImage!)
                  : Container(),
              SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.amberAccent,
                ),
                onPressed: () async {
                  // For picking an image
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (image != null) {
                    cropImage(image.path).then((croppedFile) {
                      setState(() {
                        _readNIDFromImage(croppedFile!);
                      });
                    });
                  }
                },
                child: const Text(
                  'Select NID from gallery',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //Crop the images for better results
  Future<File?> cropImage(String filePath) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: filePath,
      //aspectRatio: CropAspectRatio(ratioX: 30, ratioY: 30),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.amberAccent,
          toolbarWidgetColor: Colors.amber,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          hideBottomControls: true,
        ),
        IOSUiSettings(
          title: 'Crop Image',
          aspectRatioLockDimensionSwapEnabled: true,
          aspectRatioLockEnabled: true, // iOS-specific lock
          resetAspectRatioEnabled: false, // Disable reset to original
        ),
      ],
    );

    if (croppedFile != null) {
      return File(croppedFile.path);
    } else {
      return null; // User cancelled
    }
  }

  //Read NID Info
  Future<void> _readNIDFromImage(File imageFile) async {
    try {
      final InputImage inputImage = InputImage.fromFile(imageFile);
      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );

      final String fullText = recognizedText.text;
      print("OCR TEXT: $fullText");

      String nid = '';
      String dob = '';
      String name = '';
      String error = '';

      try {
        final RegExp pNid = RegExp(r'([0-9]{3})\s([0-9]{3})\s([0-9]{4})');
        final RegExp pNid10 = RegExp(r'\b[0-9]{10}\b');
        final RegExp pNidOld = RegExp(r'\b[0-9]{13}\b');
        final RegExp pNidOlder = RegExp(r'\b[0-9]{17}\b');
        final RegExp pDob = RegExp(
          r'\b([0-9]{2})\s([A-Z][a-z]+)\s([0-9]{4})\b',
        );
        final RegExp pName = RegExp(r'(?i)Name:\s*(.+)');

        final matchNid =
            pNid.firstMatch(fullText) ??
            pNid10.firstMatch(fullText) ??
            pNidOld.firstMatch(fullText) ??
            pNidOlder.firstMatch(fullText);

        if (matchNid != null) {
          nid = matchNid.group(0)?.replaceAll(' ', '') ?? '';
        }

        final matchDob = pDob.firstMatch(fullText);
        if (matchDob != null) {
          dob = matchDob.group(0)?.replaceAll(' ', '-') ?? '';
        }

        final matchName = pName.firstMatch(fullText);
        if (matchName != null) {
          name = matchName.group(1)?.trim() ?? '';
        }

        if (nid.isEmpty && dob.isEmpty && name.isEmpty) {
          error = 'Unable to read text';
        }
      } catch (e) {
        error = 'Parsing error';
      }

      textRecognizer.close();
    } catch (e) {
      print('Error reading NID from image: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error reading NID: $e')));
    }
  }

  //take images
  Future<void> _launchCamera() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    } else {
      print('User cancelled or failed to take photo.');
    }
  }
}
