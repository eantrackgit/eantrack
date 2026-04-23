import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'image_processor.dart';
import 'photo_filter.dart';

class PhotoImagePainter extends CustomPainter {
  const PhotoImagePainter({
    required this.image,
    required this.imageRect,
    required this.rotationTurns,
    required this.filter,
  });

  final ui.Image image;
  final Rect imageRect;
  final int rotationTurns;
  final PhotoFilter filter;

  @override
  void paint(Canvas canvas, Size size) {
    paintImageWithRotation(
      canvas,
      image: image,
      destRect: imageRect,
      rotationTurns: rotationTurns,
      colorFilter: filter.colorFilter,
    );
  }

  @override
  bool shouldRepaint(covariant PhotoImagePainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.imageRect != imageRect ||
        oldDelegate.rotationTurns != rotationTurns ||
        oldDelegate.filter != filter;
  }
}

class CropOverlayPainter extends CustomPainter {
  const CropOverlayPainter({
    required this.cropRect,
  });

  final Rect cropRect;

  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Offset.zero & size;
    final fullPath = Path()..addRect(fullRect);
    final cropPath = Path()..addRect(cropRect);
    final overlayPath = Path.combine(
      PathOperation.difference,
      fullPath,
      cropPath,
    );
    final overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.58)
      ..isAntiAlias = false;
    canvas.drawPath(overlayPath, overlayPaint);
  }

  @override
  bool shouldRepaint(covariant CropOverlayPainter oldDelegate) {
    return oldDelegate.cropRect != cropRect;
  }
}

class CropWindowImagePainter extends CustomPainter {
  const CropWindowImagePainter({
    required this.image,
    required this.imageRect,
    required this.cropRect,
    required this.rotationTurns,
    required this.filter,
  });

  final ui.Image image;
  final Rect imageRect;
  final Rect cropRect;
  final int rotationTurns;
  final PhotoFilter filter;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(cropRect);
    paintImageWithRotation(
      canvas,
      image: image,
      destRect: imageRect,
      rotationTurns: rotationTurns,
      colorFilter: filter.colorFilter,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CropWindowImagePainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.imageRect != imageRect ||
        oldDelegate.cropRect != cropRect ||
        oldDelegate.rotationTurns != rotationTurns ||
        oldDelegate.filter != filter;
  }
}

class CropChromePainter extends CustomPainter {
  const CropChromePainter({
    required this.cropRect,
    required this.handleVisualSize,
  });

  final Rect cropRect;
  final double handleVisualSize;

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(cropRect, borderPaint);

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.32)
      ..strokeWidth = 1;
    final thirdWidth = cropRect.width / 3;
    final thirdHeight = cropRect.height / 3;

    for (var i = 1; i < 3; i++) {
      final dx = cropRect.left + (thirdWidth * i);
      final dy = cropRect.top + (thirdHeight * i);
      canvas.drawLine(
        Offset(dx, cropRect.top),
        Offset(dx, cropRect.bottom),
        gridPaint,
      );
      canvas.drawLine(
        Offset(cropRect.left, dy),
        Offset(cropRect.right, dy),
        gridPaint,
      );
    }

    final handlePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final edgeTick = handleVisualSize * 0.78;

    void drawCorner(Offset pivot, double dx, double dy) {
      canvas.drawLine(
        pivot,
        Offset(pivot.dx + (dx * handleVisualSize), pivot.dy),
        handlePaint,
      );
      canvas.drawLine(
        pivot,
        Offset(pivot.dx, pivot.dy + (dy * handleVisualSize)),
        handlePaint,
      );
    }

    drawCorner(cropRect.topLeft, 1, 1);
    drawCorner(cropRect.topRight, -1, 1);
    drawCorner(cropRect.bottomRight, -1, -1);
    drawCorner(cropRect.bottomLeft, 1, -1);

    canvas.drawLine(
      Offset(cropRect.topCenter.dx - edgeTick / 2, cropRect.topCenter.dy),
      Offset(cropRect.topCenter.dx + edgeTick / 2, cropRect.topCenter.dy),
      handlePaint,
    );
    canvas.drawLine(
      Offset(
        cropRect.bottomCenter.dx - edgeTick / 2,
        cropRect.bottomCenter.dy,
      ),
      Offset(
        cropRect.bottomCenter.dx + edgeTick / 2,
        cropRect.bottomCenter.dy,
      ),
      handlePaint,
    );
    canvas.drawLine(
      Offset(cropRect.centerLeft.dx, cropRect.centerLeft.dy - edgeTick / 2),
      Offset(cropRect.centerLeft.dx, cropRect.centerLeft.dy + edgeTick / 2),
      handlePaint,
    );
    canvas.drawLine(
      Offset(cropRect.centerRight.dx, cropRect.centerRight.dy - edgeTick / 2),
      Offset(cropRect.centerRight.dx, cropRect.centerRight.dy + edgeTick / 2),
      handlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CropChromePainter oldDelegate) {
    return oldDelegate.cropRect != cropRect ||
        oldDelegate.handleVisualSize != handleVisualSize;
  }
}
