import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_liveness_app/nid_capture_screen.dart';
import 'package:flutter_liveness_app/take_cropped_picture.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tuple/tuple.dart';
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

  bool isNidInfoFound = false;
  String? nidName;
  String? nidNum;
  String? nidDob;

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
                        const SnackBar(
                          content: Text('Verification Successful!'),
                        ),
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
              SizedBox(height: 20),
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
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => TakeCroppedPicture(),
                  //   ),
                  // ).then((returnImage) {
                  //   setState(() {
                  //     returnCaptureImage = Uint8List.fromList(
                  //       img.encodeJpg((returnImage as Tuple2).item1),
                  //     );
                  //     _readNIDFromImage(returnImage.item2);
                  //   });
                  // });
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NidCaptureScreen()),
                  );
                },
                child: const Text(
                  'Capture NID',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),

              // returnCaptureImage != null
              //     ? GestureDetector(
              //       onTap: () {
              //         Navigator.push(
              //           context,
              //           MaterialPageRoute(
              //             builder: (context) => TakeCroppedPicture(),
              //           ),
              //         ).then((returnImage) {
              //           setState(() {
              //             returnCaptureImage = Uint8List.fromList(
              //               img.encodeJpg((returnImage as Tuple2).item1),
              //             );
              //             _readNIDFromImage(returnImage.item2);
              //           });
              //         });
              //       },
              //       child: Container(
              //         margin: EdgeInsets.all(8.0),
              //         decoration: BoxDecoration(
              //           border: Border.all(color: Colors.blueGrey),
              //           borderRadius: BorderRadius.circular(8.0),
              //         ),
              //         child: ClipRRect(
              //           borderRadius: BorderRadius.circular(8.0),
              //           child: Image.memory(
              //             width: double.infinity,
              //             height: 300,
              //             fit: BoxFit.cover,
              //             returnCaptureImage!,
              //           ),
              //         ),
              //       ),
              //     )
              //     : GestureDetector(
              //       onTap: () {
              //         Navigator.push(
              //           context,
              //           MaterialPageRoute(
              //             builder: (context) => TakeCroppedPicture(),
              //           ),
              //         ).then((returnImage) {
              //           setState(() {
              //             returnCaptureImage = Uint8List.fromList(
              //               img.encodeJpg((returnImage as Tuple2).item1),
              //             );
              //             _readNIDFromImage(returnImage.item2);
              //           });
              //         });
              //       },
              //       child: Container(
              //         margin: const EdgeInsets.all(8.0),
              //         decoration: BoxDecoration(
              //           border: Border.all(color: Colors.blueGrey),
              //           borderRadius: BorderRadius.circular(8.0),
              //         ),
              //         child: ClipRRect(
              //           borderRadius: BorderRadius.circular(8.0),
              //           child:
              //               returnCaptureImage != null
              //                   ? Image.memory(
              //                     returnCaptureImage!,
              //                     width: double.infinity,
              //                     height: 300,
              //                     fit: BoxFit.cover,
              //                   )
              //                   : Container(
              //                     width: double.infinity,
              //                     height: 300,
              //                     color: Colors.grey[300],
              //                     alignment: Alignment.center,
              //                     child: Column(
              //                       mainAxisAlignment: MainAxisAlignment.center,
              //                       children: const [
              //                         Icon(
              //                           Icons.camera_alt,
              //                           size: 60,
              //                           color: Colors.grey,
              //                         ),
              //                         SizedBox(height: 8),
              //                         Text(
              //                           'Tap to Capture NID',
              //                           style: TextStyle(
              //                             fontSize: 16,
              //                             color: Colors.black54,
              //                             fontWeight: FontWeight.w500,
              //                           ),
              //                         ),
              //                       ],
              //                     ),
              //                   ),
              //         ),
              //       ),
              //     ),

              // isNidInfoFound
              //     ? Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: [
              //         Text(
              //           "Customer Information",
              //           style: TextStyle(
              //             fontSize: 18,
              //             fontWeight: FontWeight.bold,
              //           ),
              //         ),
              //         SizedBox(height: 12),
              //         Container(
              //           padding: EdgeInsets.all(16),
              //           decoration: BoxDecoration(
              //             color: Colors.grey[100],
              //             borderRadius: BorderRadius.circular(12),
              //             boxShadow: [
              //               BoxShadow(
              //                 color: Colors.black12,
              //                 blurRadius: 6,
              //                 offset: Offset(0, 2),
              //               ),
              //             ],
              //           ),
              //           child: Column(
              //             crossAxisAlignment: CrossAxisAlignment.start,
              //             children: [
              //               InfoRow(
              //                 label: "Customer Name",
              //                 value: nidName ?? '',
              //               ),
              //               SizedBox(height: 8),
              //               InfoRow(label: "NID No", value: nidNum ?? ''),
              //               SizedBox(height: 8),
              //               InfoRow(
              //                 label: "Date of Birth",
              //                 value: nidDob ?? '',
              //               ),
              //             ],
              //           ),
              //         ),
              //       ],
              //     )
              //     : Container(),
              SizedBox(height: 20),
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
                        _readNIDFromImage(croppedFile!.path);
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
  Future<void> _readNIDFromImage(String imageFile) async {
    try {
      final InputImage inputImage = InputImage.fromFilePath(imageFile);
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
        final pNid = RegExp(r'([0-9]{3})\s([0-9]{3})\s([0-9]{4})');
        final pNid10 = RegExp(r'([0-9]{10})');
        final pNidOld = RegExp(r'([0-9]{13})');
        final pNidOlder = RegExp(r'([0-9]{17})');
        final pDob = RegExp(r'([0-9]{2})\s([A-Za-z]+)\s([0-9]{4})');
        final pName = RegExp(r'Name:\s*(.+)', caseSensitive: false);

        final m = pNid.firstMatch(fullText);
        if (m != null) {
          nid = m.group(0)!;
        }

        final mOld10 = pNid10.firstMatch(fullText);
        if (mOld10 != null) {
          nid = mOld10.group(0)!;
        }

        final mOld = pNidOld.firstMatch(fullText);
        if (mOld != null) {
          nid = mOld.group(0)!;
        }

        final mOlder = pNidOlder.firstMatch(fullText);
        if (mOlder != null) {
          nid = mOlder.group(0)!;
        }

        final mDob = pDob.firstMatch(fullText);
        if (mDob != null) {
          dob = mDob.group(0)!;
        }

        final mName = pName.firstMatch(fullText);
        if (mName != null) {
          name = mName.group(1)!;
        }
        print("Name : $name , NID : $nid , DOB : $dob");
      } catch (e) {
        print(e.toString());
      }

      textRecognizer.close();
      setState(() {
        nidName = name;
        nidNum = nid;
        nidDob = dob;
        isNidInfoFound = true;
      });
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

class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          "$label: ",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: Colors.black),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
