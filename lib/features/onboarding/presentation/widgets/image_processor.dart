import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/profile_photo_service.dart';
import 'photo_filter.dart';

Future<ui.Image> decodeImageBytes(
  Uint8List bytes, {
  int? targetWidth,
}) async {
  final codec = await ui.instantiateImageCodec(
    bytes,
    targetWidth: targetWidth,
  );
  final frame = await codec.getNextFrame();
  return frame.image;
}

Future<ui.Image> buildFallbackImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const side = 512.0;
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, side, side),
    Paint()..color = const Color(0xFFBFC5CD),
  );
  final picture = recorder.endRecording();
  return picture.toImage(side.toInt(), side.toInt());
}

Future<PickedProfilePhoto?> confirmCrop({
  required Rect cropRect,
  required Rect imageRect,
  required PickedProfilePhoto photo,
  required Uint8List? sourceBytes,
  required int rotationTurns,
  required PhotoFilter selectedFilter,
}) async {
  try {
    final bytes = sourceBytes ?? await photo.readBytes();
    final image = await decodeImageBytes(bytes);
    final isQuarterTurn = rotationTurns.isOdd;
    final displaySize = Size(
      isQuarterTurn ? image.height.toDouble() : image.width.toDouble(),
      isQuarterTurn ? image.width.toDouble() : image.height.toDouble(),
    );
    final renderedWidth = math.max(1, displaySize.width.round());
    final renderedHeight = math.max(1, displaySize.height.round());

    final rotatedRecorder = ui.PictureRecorder();
    final rotatedCanvas = Canvas(rotatedRecorder);
    paintImageWithRotation(
      rotatedCanvas,
      image: image,
      destRect: Rect.fromLTWH(
        0,
        0,
        renderedWidth.toDouble(),
        renderedHeight.toDouble(),
      ),
      rotationTurns: rotationTurns,
    );
    final rotatedPicture = rotatedRecorder.endRecording();
    final rotatedImage = await rotatedPicture.toImage(
      renderedWidth,
      renderedHeight,
    );

    final scaleX = renderedWidth / imageRect.width;
    final scaleY = renderedHeight / imageRect.height;
    final sourceRect = Rect.fromLTWH(
      (cropRect.left - imageRect.left) * scaleX,
      (cropRect.top - imageRect.top) * scaleY,
      cropRect.width * scaleX,
      cropRect.height * scaleY,
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const outputSize = 1080.0;

    canvas.drawImageRect(
      rotatedImage,
      sourceRect,
      const Rect.fromLTWH(0, 0, outputSize, outputSize),
      Paint()
        ..isAntiAlias = true
        ..colorFilter = selectedFilter.colorFilter,
    );

    final picture = recorder.endRecording();
    final rendered = await picture.toImage(
      outputSize.toInt(),
      outputSize.toInt(),
    );
    final byteData = await rendered.toByteData(format: ui.ImageByteFormat.png);
    final renderedBytes = byteData?.buffer.asUint8List();

    if (renderedBytes == null) {
      return null;
    }

    return PickedProfilePhoto(
      file: XFile.fromData(
        renderedBytes,
        name: 'avatar_cropped.png',
        mimeType: 'image/png',
      ),
      bytes: renderedBytes,
      contentType: 'image/png',
    );
  } catch (_) {
    return null;
  }
}

void paintImageWithRotation(
  Canvas canvas, {
  required ui.Image image,
  required Rect destRect,
  required int rotationTurns,
  ColorFilter? colorFilter,
}) {
  final turns = rotationTurns % 4;
  canvas.save();
  canvas.clipRect(destRect);
  canvas.translate(destRect.center.dx, destRect.center.dy);
  canvas.rotate(turns * math.pi / 2);

  final drawRect = turns.isOdd
      ? Rect.fromCenter(
          center: Offset.zero,
          width: destRect.height,
          height: destRect.width,
        )
      : Rect.fromCenter(
          center: Offset.zero,
          width: destRect.width,
          height: destRect.height,
        );

  final paint = Paint()..isAntiAlias = true;
  if (colorFilter != null) {
    paint.colorFilter = colorFilter;
  }

  canvas.drawImageRect(
    image,
    Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
    drawRect,
    paint,
  );
  canvas.restore();
}
