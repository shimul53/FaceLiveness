import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class NidCaptureScreen extends StatefulWidget {
  const NidCaptureScreen({super.key});

  @override
  State<NidCaptureScreen> createState() => _NidCapturePageState();
}

class _NidCapturePageState extends State<NidCaptureScreen> {
  String? capturedImagePath;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  Uint8List? returnCaptureImage;

  bool isNidInfoFound = false;
  String? frontNidName;
  String? frontNidNum;
  String? frontNidDob;

  String? backNidName;
  String? backNidNum;
  String? backNidDob;

  Uint8List? returnBackCaptureImage;
  bool isBackNidInfoFound = false;
  String? nidBackText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.amberAccent,
        toolbarHeight: 70,
        centerTitle: true,
        title: const Text('Capture NID Step'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Padding(
                padding: const EdgeInsets.only(left: 10, top: 10),

                child: Text(
                  'NID Front Side',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.start,
                ),
              ),
              const SizedBox(height: 10),
              //front nid
              returnCaptureImage != null
                  ? GestureDetector(
                    onTap: () async {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            title: const Text("Select Image Source"),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.camera_alt),
                                  title: const Text("Camera"),
                                  onTap: () {
                                    Navigator.pop(context); // Close dialog
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => TakeCroppedPicture(),
                                      ),
                                    ).then((returnImage) {
                                      if (returnImage != null) {
                                        setState(() {
                                          returnCaptureImage =
                                              Uint8List.fromList(
                                                img.encodeJpg(
                                                  (returnImage as Tuple2).item1,
                                                ),
                                              );
                                          _readFrontNIDFromImage(
                                            returnImage.item2,
                                          );
                                        });
                                      }
                                    });
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.photo_library),
                                  title: const Text("Gallery"),
                                  onTap: () async {
                                    Navigator.pop(context); // Close dialog

                                    final picker = ImagePicker();
                                    final pickedFile = await picker.pickImage(
                                      source: ImageSource.gallery,
                                    );

                                    if (pickedFile != null) {
                                      final imageBytes =
                                          await pickedFile.readAsBytes();

                                      setState(() {
                                        returnCaptureImage = imageBytes;
                                      });

                                      _readFrontNIDFromImage(
                                        pickedFile.path,
                                      ); // Pass file path to OCR
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },

                    child: Container(
                      margin: EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blueGrey),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.memory(
                          width: double.infinity,
                          height: 300,
                          fit: BoxFit.cover,
                          returnCaptureImage!,
                        ),
                      ),
                    ),
                  )
                  : GestureDetector(
                    onTap: () async {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            title: const Text("Select Image Source"),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.camera_alt),
                                  title: const Text("Camera"),
                                  onTap: () {
                                    Navigator.pop(context); // Close dialog
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => TakeCroppedPicture(),
                                      ),
                                    ).then((returnImage) {
                                      if (returnImage != null) {
                                        setState(() {
                                          returnCaptureImage =
                                              Uint8List.fromList(
                                                img.encodeJpg(
                                                  (returnImage as Tuple2).item1,
                                                ),
                                              );
                                          _readFrontNIDFromImage(
                                            returnImage.item2,
                                          );
                                        });
                                      }
                                    });
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.photo_library),
                                  title: const Text("Gallery"),
                                  onTap: () async {
                                    Navigator.pop(context); // Close dialog

                                    final picker = ImagePicker();
                                    final pickedFile = await picker.pickImage(
                                      source: ImageSource.gallery,
                                    );

                                    if (pickedFile != null) {
                                      final imageBytes =
                                          await pickedFile.readAsBytes();

                                      setState(() {
                                        returnCaptureImage = imageBytes;
                                      });

                                      _readFrontNIDFromImage(
                                        pickedFile.path,
                                      ); // Pass file path to OCR
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },

                    child: Container(
                      margin: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blueGrey),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child:
                            returnCaptureImage != null
                                ? Image.memory(
                                  returnCaptureImage!,
                                  width: double.infinity,
                                  height: 300,
                                  fit: BoxFit.cover,
                                )
                                : Container(
                                  width: double.infinity,
                                  height: 300,
                                  color: Colors.grey[300],
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.camera_alt,
                                        size: 60,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Tap to Capture NID',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black54,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                      ),
                    ),
                  ),

              isNidInfoFound
                  ? Padding(
                    padding: const EdgeInsets.only(
                      left: 10,
                      top: 10,
                      right: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Customer Information",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InfoRow(
                                label: "Customer Name",
                                value: frontNidName ?? '',
                              ),
                              SizedBox(height: 8),
                              InfoRow(
                                label: "NID No",
                                value: frontNidNum ?? '',
                              ),
                              SizedBox(height: 8),
                              InfoRow(
                                label: "Date of Birth",
                                value: frontNidDob ?? '',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                  : Container(),
              SizedBox(height: 8),

              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.only(left: 10, top: 10),
                child: Text(
                  'NID Back Side',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 10),
              returnBackCaptureImage != null
                  ? GestureDetector(
                    onTap: () async {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            title: const Text("Select Image Source"),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.camera_alt),
                                  title: const Text("Camera"),
                                  onTap: () {
                                    Navigator.pop(context); // Close dialog
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => TakeCroppedPicture(),
                                      ),
                                    ).then((returnImage) {
                                      if (returnImage != null) {
                                        setState(() {
                                          returnBackCaptureImage =
                                              Uint8List.fromList(
                                                img.encodeJpg(
                                                  (returnImage as Tuple2).item1,
                                                ),
                                              );
                                          _readBackNIDFromImage(
                                            returnImage.item2,
                                          );
                                        });
                                      }
                                    });
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.photo_library),
                                  title: const Text("Gallery"),
                                  onTap: () async {
                                    Navigator.pop(context); // Close dialog

                                    final picker = ImagePicker();
                                    final pickedFile = await picker.pickImage(
                                      source: ImageSource.gallery,
                                    );

                                    if (pickedFile != null) {
                                      final imageBytes =
                                          await pickedFile.readAsBytes();

                                      setState(() {
                                        returnBackCaptureImage = imageBytes;
                                      });

                                      _readBackNIDFromImage(
                                        pickedFile.path,
                                      ); // Pass file path to OCR
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },

                    child: Container(
                      margin: EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blueGrey),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.memory(
                          returnBackCaptureImage!,
                          width: double.infinity,
                          height: 300,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  )
                  : GestureDetector(
                    onTap: () async {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            title: const Text("Select Image Source"),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.camera_alt),
                                  title: const Text("Camera"),
                                  onTap: () {
                                    Navigator.pop(context); // Close dialog
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => TakeCroppedPicture(),
                                      ),
                                    ).then((returnImage) {
                                      if (returnImage != null) {
                                        setState(() {
                                          returnBackCaptureImage =
                                              Uint8List.fromList(
                                                img.encodeJpg(
                                                  (returnImage as Tuple2).item1,
                                                ),
                                              );
                                          _readBackNIDFromImage(
                                            returnImage.item2,
                                          );
                                        });
                                      }
                                    });
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.photo_library),
                                  title: const Text("Gallery"),
                                  onTap: () async {
                                    Navigator.pop(context); // Close dialog

                                    final picker = ImagePicker();
                                    final pickedFile = await picker.pickImage(
                                      source: ImageSource.gallery,
                                    );

                                    if (pickedFile != null) {
                                      final imageBytes =
                                          await pickedFile.readAsBytes();

                                      setState(() {
                                        returnBackCaptureImage = imageBytes;
                                      });

                                      _readBackNIDFromImage(
                                        pickedFile.path,
                                      ); // Pass file path to OCR
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },

                    child: Container(
                      margin: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blueGrey),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Container(
                          width: double.infinity,
                          height: 300,
                          color: Colors.grey[300],
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.camera_alt,
                                size: 60,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tap to Capture NID Back',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

              // isBackNidInfoFound
              //     ? Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: [
              //         Text(
              //           "Customer Information (Back)",
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
              SizedBox(height: 8),
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
          lockAspectRatio: false,
          hideBottomControls: false,
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

  //Read Front NID Info
  Future<void> _readFrontNIDFromImage(String imageFile) async {
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
        frontNidName = name;
        frontNidNum = nid;
        frontNidDob = dob;
        isNidInfoFound = true;
      });
    } catch (e) {
      print('Error reading NID from image: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error reading NID: $e')));
    }
  }

  //Read Front NID Info
  Future<void> _readBackNIDFromImage(String imageFile) async {
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
        backNidName = name;
        backNidNum = nid;
        backNidDob = dob;
        isBackNidInfoFound = true;
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
