/*
 * Created on Tue Jul 15 2025
 *
 * Created by Arifur Rahaman
 */

import 'package:flutter/material.dart';

class CustomPainterMain extends CustomPainter {
  final double width;
  CustomPainterMain(this.width);

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.5) // Darken outside
          ..style = PaintingStyle.fill;

    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);

    final frameWidth = width - 32;
    final frameHeight = (frameWidth * 2) / 3;

    final left = (size.width - frameWidth) / 2;
    final top = (size.height - frameHeight) / 2;

    final frameRect = Rect.fromLTWH(left, top, frameWidth, frameHeight);

    final cutout =
        Path()
          ..addRect(fullRect)
          ..addRRect(RRect.fromRectXY(frameRect, 10, 10))
          ..fillType = PathFillType.evenOdd;

    // Darken everything outside the frame
    canvas.drawPath(cutout, overlayPaint);

    // Optional: White border around the frame
    final borderPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    canvas.drawRRect(RRect.fromRectXY(frameRect, 10, 10), borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
