/*
 * Created on Tue Jul 15 2025
 *
 * Crated by Arifur Rahaman
 */

import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_liveness_app/custom_painter.dart';
import 'package:image/image.dart' as img;
import 'package:tuple/tuple.dart';

class TakeCroppedPicture extends StatefulWidget {
  TakeCroppedPicture({super.key});

  @override
  State<TakeCroppedPicture> createState() => _TakeCroppedPictureState();
}

class _TakeCroppedPictureState extends State<TakeCroppedPicture> {
  List<CameraDescription> _cameras = [];

  CameraController? _controller;

  Future<void> _initializeCamera() async {
    // Get available cameras
    _cameras = await availableCameras();

    // Choose a camera (usually back camera)
    final CameraDescription camera = _cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
    );

    _controller = CameraController(
      camera,
      ResolutionPreset.high, // You can choose low, medium, high, etc.
      enableAudio: false, // Set to true if you want to record videos
    );

    try {
      await _controller!.initialize();
      // Add a tiny delay to smooth UI transition
      // await Future.delayed(const Duration(milliseconds: 1000));
      setState(() {}); // Refresh the UI once initialized
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller != null && _controller!.value.isInitialized
        ? Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  CameraPreview(_controller!),

                  CustomPaint(
                    size: MediaQuery.of(context).size,
                    painter: CustomPainterMain(
                      MediaQuery.of(context).size.width,
                    ),
                  ), // Fullscreen preview
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _captureImage,
              child: const Text("Capture"),
            ),
          ],
        )
        : Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
              Text(
                "Initializing ...",
                style: TextStyle(fontSize: 14, color: Colors.black),
              ),
            ],
          ),
        );
  }

  Future<void> _captureImage() async {
    if (!_controller!.value.isInitialized) {
      print("Camera not initialized");
      return;
    }

    try {
      // Ensure the camera is not taking another picture
      if (_controller!.value.isTakingPicture) return;

      final XFile imageFile = await _controller!.takePicture();

      print("Image captured at: ${imageFile.path}");

      // Optionally crop the image to match the frame (as we discussed)
      // await _cropToFrame(imageFile);
      cropImage(imageFile);

      // Do something with the image (e.g. display, save, upload)
    } catch (e) {
      print("Error capturing image: $e");
    }
  }

  //Programitically Crop
  Future<void> cropImage(XFile imageFile) async {
    final Uint8List imageBytes = await imageFile.readAsBytes();
    final capturedImage = img.decodeImage(imageBytes);
    final screenSize = MediaQuery.of(context).size;
    // print("Screen Height : ")

    // Define frame size and position
    final frameWidth = MediaQuery.of(context).size.width + 50;
    final frameHeight = ((frameWidth * 2) / 3) + 20;
    final offsetX = (screenSize.width - frameWidth) ~/ 2;
    final offsetY = (screenSize.height - (frameHeight - 130)) ~/ 2;

    print("offsetX: $offsetX offsetY : $offsetY");

    // Scale from screen size to actual image size
    final scaleX = capturedImage!.width / screenSize.width;
    final scaleY = capturedImage.height / screenSize.height;

    print("scaleX : $scaleX , scaleY : $scaleY");

    final cropX = (offsetX * scaleX).toInt();
    final cropY = (offsetY * scaleY).toInt();
    final cropWidth = (frameWidth * scaleX).toInt();
    final cropHeight = (frameHeight * scaleY).toInt();

    print(
      "cropX : $cropX , cropY : $cropY , cropWidth : $cropWidth , cropHeight : $cropHeight",
    );

    final cropped = img.copyCrop(
      capturedImage,
      x: cropX,
      y: cropY,
      width: cropWidth,
      height: cropHeight,
    );

    Navigator.pop(context, Tuple2(cropped, imageFile.path));
  }
}
