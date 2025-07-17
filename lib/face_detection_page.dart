import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:camera/camera.dart';

class FaceDetectionPage extends StatefulWidget {
  const FaceDetectionPage({super.key});

  @override
  _FaceDetectionPageState createState() => _FaceDetectionPageState();
}

class _FaceDetectionPageState extends State<FaceDetectionPage> {
  Future<String?> captureImage() async {
    try {
      final XFile file = await cameraController.takePicture();
      return file.path;
    } catch (e) {
      debugPrint('Error capturing image: $e');
      return null;
    }
  }

  final FaceDetector faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      minFaceSize: 0.3,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  late CameraController cameraController;
  bool isCameraInitialized = false;
  bool isDetecting = false;
  bool isFrontCamera = true;
  final List<String> allActions = ['smile', 'blink', 'lookRight', 'lookLeft'];
  late List<String> challengeActions;
  int currentActionIndex = 0;
  bool waitingForNeutral = false;

  double? smilingProbability;
  double? leftEyeOpenProbability;
  double? rightEyeOpenProbability;
  double? headEulerAngleY;

  final List<List<Color>> actionGradients = [
    [Colors.blue.shade700, Colors.lightBlueAccent],
    [Colors.orange.shade700, Colors.orangeAccent],
    [Colors.teal.shade700, Colors.tealAccent],
    [Colors.teal.shade700, Colors.tealAccent],
  ];

  int gradientIndex = 0;

  @override
  void initState() {
    super.initState();

    // Custom logic to pick 2 random from ['lookRight', 'lookLeft']
    final List<String> directionalActions = ['lookRight', 'lookLeft'];
    directionalActions.shuffle();
    final List<String> selectedDirectionals =
        directionalActions.take(2).toList();

    // Pick 1 random from ['smile', 'blink']
    final List<String> expressionActions = ['smile', 'blink'];
    expressionActions.shuffle();
    final String selectedExpression = expressionActions.first;

    // Combine them into the final challenge list
    challengeActions = [...selectedDirectionals, selectedExpression];

    initializeCamera();
  }

  // Initialize the camera controller
  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );
    cameraController = CameraController(
      frontCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await cameraController.initialize();
    if (mounted) {
      setState(() {
        isCameraInitialized = true;
      });
      startFaceDetection();
    }
  }

  // Start face detection on the camera image stream
  void startFaceDetection() {
    if (isCameraInitialized) {
      cameraController.startImageStream((CameraImage image) {
        if (!isDetecting) {
          isDetecting = true;
          detectFaces(image).then((_) {
            isDetecting = false;
          });
        }
      });
    }
  }

  // Detect faces in the camera image
  Future<void> detectFaces(CameraImage image) async {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      //android start

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation270deg,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      //android end

      //ios start

      // InputImageRotation rotation =
      //     InputImageRotationValue.fromRawValue(
      //       cameraController.description.sensorOrientation,
      //     ) ??
      //     InputImageRotation.rotation0deg;

      // InputImageFormat format =
      //     InputImageFormatValue.fromRawValue(image.format.raw) ??
      //     InputImageFormat.nv21; // fallback if unknown

      // final inputImage = InputImage.fromBytes(
      //   bytes: bytes,
      //   metadata: InputImageMetadata(
      //     size: Size(image.width.toDouble(), image.height.toDouble()),
      //     rotation: rotation,
      //     format: format,
      //     bytesPerRow: image.planes[0].bytesPerRow,
      //   ),
      // );

      //ios end

      final faces = await faceDetector.processImage(inputImage);

      if (!mounted) return;

      if (faces.isNotEmpty) {
        final face = faces.first;
        setState(() {
          smilingProbability = face.smilingProbability;
          leftEyeOpenProbability = face.leftEyeOpenProbability;
          rightEyeOpenProbability = face.rightEyeOpenProbability;
          headEulerAngleY = face.headEulerAngleY;
        });
        checkChallenge(face);
      }
    } catch (e) {
      debugPrint('Error in face detection: $e');
    }
  }

  // Check if the face is performing the current challenge action
  void checkChallenge(Face face) async {
    if (waitingForNeutral) {
      if (isNeutralPosition(face)) {
        waitingForNeutral = false;
      } else {
        return;
      }
    }

    String currentAction = challengeActions[currentActionIndex];
    bool actionCompleted = false;

    switch (currentAction) {
      case 'smile':
        actionCompleted =
            face.smilingProbability != null && face.smilingProbability! > 0.5;
        break;
      case 'blink':
        actionCompleted =
            (face.leftEyeOpenProbability != null &&
                face.leftEyeOpenProbability! < 0.3) ||
            (face.rightEyeOpenProbability != null &&
                face.rightEyeOpenProbability! < 0.3);
        break;
      case 'lookRight':
        actionCompleted =
            face.headEulerAngleY != null && face.headEulerAngleY! < -10;
        break;
      case 'lookLeft':
        actionCompleted =
            face.headEulerAngleY != null && face.headEulerAngleY! > 10;
        break;
    }

    if (actionCompleted) {
      currentActionIndex++;
      setState(() {
        gradientIndex = (gradientIndex + 1) % actionGradients.length;
      });
      if (currentActionIndex >= challengeActions.length) {
        currentActionIndex = 0;
        final imagePath = await captureImage();
        if (mounted) {
          Navigator.pop(context, imagePath);
        }
      } else {
        waitingForNeutral = true;
      }
    }
  }

  // Check if the face is in a neutral position
  bool isNeutralPosition(Face face) {
    return (face.smilingProbability == null ||
            face.smilingProbability! < 0.1) &&
        (face.leftEyeOpenProbability == null ||
            face.leftEyeOpenProbability! > 0.7) &&
        (face.rightEyeOpenProbability == null ||
            face.rightEyeOpenProbability! > 0.7) &&
        (face.headEulerAngleY == null ||
            (face.headEulerAngleY! > -10 && face.headEulerAngleY! < 10));
  }

  @override
  void dispose() {
    cameraController.stopImageStream();
    faceDetector.close();
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amberAccent,
        toolbarHeight: 70,
        centerTitle: true,
        title: const Text("Verify Your Identity"),
      ),
      body:
          isCameraInitialized
              ? Stack(
                children: [
                  Positioned.fill(child: CameraPreview(cameraController)),
                  CustomPaint(painter: HeadMaskPainter(), child: Container()),
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: actionGradients[gradientIndex],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),

                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Please ${getActionDescription(challengeActions[currentActionIndex])}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Step ${currentActionIndex + 1} of ${challengeActions.length}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Positioned(
                  //   bottom: 16,
                  //   left: 16,
                  //   child: Container(
                  //     padding: const EdgeInsets.all(8),
                  //     color: Colors.black54,
                  //     child: Column(
                  //       crossAxisAlignment: CrossAxisAlignment.start,
                  //       children: [
                  //         Text(
                  //           'Smile: ${smilingProbability != null ? (smilingProbability! * 100).toStringAsFixed(2) : 'N/A'}%',
                  //           style: const TextStyle(color: Colors.white),
                  //         ),
                  //         Text(
                  //           'Blink: ${leftEyeOpenProbability != null && rightEyeOpenProbability != null ? (((leftEyeOpenProbability! + rightEyeOpenProbability!) / 2) * 100).toStringAsFixed(2) : 'N/A'}%',
                  //           style: const TextStyle(color: Colors.white),
                  //         ),
                  //         Text(
                  //           'Look: ${headEulerAngleY != null ? headEulerAngleY!.toStringAsFixed(2) : 'N/A'}°',
                  //           style: const TextStyle(color: Colors.white),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                ],
              )
              : const Center(child: CircularProgressIndicator()),
    );
  }

  // Get the description of the current challenge action
  String getActionDescription(String action) {
    switch (action) {
      case 'smile':
        return 'smile';
      case 'blink':
        return 'blink';
      case 'lookRight':
        return 'look right';
      case 'lookLeft':
        return 'look left';
      default:
        return '';
    }
  }
}

// Custom painter for head mask
class HeadMaskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.black.withOpacity(0.5)
          ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    final path =
        Path()
          ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
          ..addOval(Rect.fromCircle(center: center, radius: radius))
          ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
