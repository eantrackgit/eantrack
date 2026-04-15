import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/profile_photo_service.dart';

enum _CropDragMode {
  none,
  move,
  topLeft,
  top,
  topRight,
  right,
  bottomRight,
  bottom,
  bottomLeft,
  left,
}

enum _PhotoFilter {
  original(
    label: 'Original',
    matrix: null,
  ),
  natural(
    label: 'Natural',
    matrix: <double>[
      1.04, 0.00, 0.00, 0.00, 4.0,
      0.00, 1.02, 0.00, 0.00, 2.0,
      0.00, 0.00, 0.98, 0.00, -3.0,
      0.00, 0.00, 0.00, 1.00, 0.0,
    ],
  ),
  vibrant(
    label: 'Vibrante',
    matrix: <double>[
      1.12, -0.05, -0.05, 0.00, 6.0,
      -0.04, 1.10, -0.04, 0.00, 4.0,
      -0.03, -0.03, 1.14, 0.00, 5.0,
      0.00, 0.00, 0.00, 1.00, 0.0,
    ],
  ),
  blackAndWhite(
    label: 'Preto & Branco',
    matrix: <double>[
      0.2126, 0.7152, 0.0722, 0.00, 0.0,
      0.2126, 0.7152, 0.0722, 0.00, 0.0,
      0.2126, 0.7152, 0.0722, 0.00, 0.0,
      0.0000, 0.0000, 0.0000, 1.00, 0.0,
    ],
  );

  const _PhotoFilter({
    required this.label,
    required this.matrix,
  });

  final String label;
  final List<double>? matrix;

  ColorFilter? get colorFilter {
    final matrix = this.matrix;
    if (matrix == null) return null;
    return ColorFilter.matrix(matrix);
  }
}

class PhotoCropDialog extends StatefulWidget {
  const PhotoCropDialog({
    super.key,
    required this.photo,
  });

  final PickedProfilePhoto photo;

  static Future<PickedProfilePhoto?> show(
    BuildContext context, {
    required PickedProfilePhoto photo,
  }) {
    return showDialog<PickedProfilePhoto>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.84),
      builder: (_) => PhotoCropDialog(photo: photo),
    );
  }

  @override
  State<PhotoCropDialog> createState() => _PhotoCropDialogState();
}

class _PhotoCropDialogState extends State<PhotoCropDialog> {
  static const double _viewportPadding = 20;
  static const double _handleHitSize = 34;
  static const double _handleVisualSize = 24;
  static const double _minCropSize = 110;

  ui.Image? _decodedImage;
  Rect? _cropRect;
  Rect? _lastImageRect;
  Size? _lastViewport;
  _CropDragMode _dragMode = _CropDragMode.none;
  bool _isProcessing = false;
  int _rotationTurns = 0;
  _PhotoFilter _selectedFilter = _PhotoFilter.original;

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  Future<void> _decodeImage() async {
    ui.Image image;
    try {
      final codec = await ui.instantiateImageCodec(widget.photo.bytes);
      final frame = await codec.getNextFrame();
      image = frame.image;
    } catch (_) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const side = 512.0;
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, side, side),
        Paint()..color = const Color(0xFFBFC5CD),
      );
      final picture = recorder.endRecording();
      image = await picture.toImage(side.toInt(), side.toInt());
    }

    if (!mounted) return;
    setState(() {
      _decodedImage = image;
    });
  }

  Size _displayImageSize(ui.Image image) {
    final isQuarterTurn = _rotationTurns.isOdd;
    return Size(
      isQuarterTurn ? image.height.toDouble() : image.width.toDouble(),
      isQuarterTurn ? image.width.toDouble() : image.height.toDouble(),
    );
  }

  Rect _computeImageRect(Size viewport, ui.Image image) {
    final displaySize = _displayImageSize(image);
    final availableWidth =
        math.max(0.0, viewport.width - (_viewportPadding * 2)).toDouble();
    final availableHeight =
        math.max(0.0, viewport.height - (_viewportPadding * 2)).toDouble();
    final imageAspect = displaySize.width / displaySize.height;
    final viewportAspect = availableWidth / availableHeight;

    late final double width;
    late final double height;

    if (imageAspect > viewportAspect) {
      width = availableWidth;
      height = width / imageAspect;
    } else {
      height = availableHeight;
      width = height * imageAspect;
    }

    return Rect.fromCenter(
      center: Offset(viewport.width / 2, viewport.height / 2),
      width: width,
      height: height,
    );
  }

  Rect _initialCropRect(Rect imageRect) {
    final side = math.max(
      _minCropSize,
      math.min(imageRect.width, imageRect.height) * 0.72,
    );
    return Rect.fromCenter(
      center: imageRect.center,
      width: side,
      height: side,
    );
  }

  _CropDragMode _hitTestCrop(Offset localPosition, Rect cropRect) {
    final handles = <_CropDragMode, Offset>{
      _CropDragMode.topLeft: cropRect.topLeft,
      _CropDragMode.top: cropRect.topCenter,
      _CropDragMode.topRight: cropRect.topRight,
      _CropDragMode.right: cropRect.centerRight,
      _CropDragMode.bottomRight: cropRect.bottomRight,
      _CropDragMode.bottom: cropRect.bottomCenter,
      _CropDragMode.bottomLeft: cropRect.bottomLeft,
      _CropDragMode.left: cropRect.centerLeft,
    };

    for (final entry in handles.entries) {
      final handleRect = Rect.fromCenter(
        center: entry.value,
        width: _handleHitSize,
        height: _handleHitSize,
      );
      if (handleRect.contains(localPosition)) return entry.key;
    }

    if (cropRect.contains(localPosition)) return _CropDragMode.move;
    return _CropDragMode.none;
  }

  Offset _clampToImageRect(Offset position, Rect imageRect) {
    return Offset(
      position.dx.clamp(imageRect.left, imageRect.right).toDouble(),
      position.dy.clamp(imageRect.top, imageRect.bottom).toDouble(),
    );
  }

  Rect _moveCropRect(Rect current, Offset delta, Rect imageRect) {
    var next = current.shift(delta);

    if (next.left < imageRect.left) {
      next = next.shift(Offset(imageRect.left - next.left, 0));
    }
    if (next.top < imageRect.top) {
      next = next.shift(Offset(0, imageRect.top - next.top));
    }
    if (next.right > imageRect.right) {
      next = next.shift(Offset(imageRect.right - next.right, 0));
    }
    if (next.bottom > imageRect.bottom) {
      next = next.shift(Offset(0, imageRect.bottom - next.bottom));
    }

    return next;
  }

  double _horizontalLimitForCenter(double centerX, Rect imageRect) {
    return math.min(
          centerX - imageRect.left,
          imageRect.right - centerX,
        ) *
        2;
  }

  double _verticalLimitForCenter(double centerY, Rect imageRect) {
    return math.min(
          centerY - imageRect.top,
          imageRect.bottom - centerY,
        ) *
        2;
  }

  Rect _resizeCropRect(
    Rect current,
    Offset localPosition,
    Rect imageRect,
    _CropDragMode mode,
  ) {
    final clamped = _clampToImageRect(localPosition, imageRect);
    late final Rect next;

    switch (mode) {
      case _CropDragMode.topLeft:
        final anchor = current.bottomRight;
        final side = math.max(
          _minCropSize,
          math.min(anchor.dx - clamped.dx, anchor.dy - clamped.dy),
        );
        next = Rect.fromLTWH(anchor.dx - side, anchor.dy - side, side, side);
      case _CropDragMode.top:
        final centerX = current.center.dx;
        final bottom = current.bottom;
        final maxSide = math.min(
          _horizontalLimitForCenter(centerX, imageRect),
          bottom - imageRect.top,
        );
        if (maxSide < _minCropSize) return current;
        final side =
            (bottom - clamped.dy).clamp(_minCropSize, maxSide).toDouble();
        next = Rect.fromLTWH(centerX - (side / 2), bottom - side, side, side);
      case _CropDragMode.topRight:
        final anchor = current.bottomLeft;
        final side = math.max(
          _minCropSize,
          math.min(clamped.dx - anchor.dx, anchor.dy - clamped.dy),
        );
        next = Rect.fromLTWH(anchor.dx, anchor.dy - side, side, side);
      case _CropDragMode.right:
        final centerY = current.center.dy;
        final left = current.left;
        final maxSide = math.min(
          imageRect.right - left,
          _verticalLimitForCenter(centerY, imageRect),
        );
        if (maxSide < _minCropSize) return current;
        final side =
            (clamped.dx - left).clamp(_minCropSize, maxSide).toDouble();
        next = Rect.fromLTWH(left, centerY - (side / 2), side, side);
      case _CropDragMode.bottomRight:
        final anchor = current.topLeft;
        final side = math.max(
          _minCropSize,
          math.min(clamped.dx - anchor.dx, clamped.dy - anchor.dy),
        );
        next = Rect.fromLTWH(anchor.dx, anchor.dy, side, side);
      case _CropDragMode.bottom:
        final centerX = current.center.dx;
        final top = current.top;
        final maxSide = math.min(
          _horizontalLimitForCenter(centerX, imageRect),
          imageRect.bottom - top,
        );
        if (maxSide < _minCropSize) return current;
        final side =
            (clamped.dy - top).clamp(_minCropSize, maxSide).toDouble();
        next = Rect.fromLTWH(centerX - (side / 2), top, side, side);
      case _CropDragMode.bottomLeft:
        final anchor = current.topRight;
        final side = math.max(
          _minCropSize,
          math.min(anchor.dx - clamped.dx, clamped.dy - anchor.dy),
        );
        next = Rect.fromLTWH(anchor.dx - side, anchor.dy, side, side);
      case _CropDragMode.left:
        final centerY = current.center.dy;
        final right = current.right;
        final maxSide = math.min(
          right - imageRect.left,
          _verticalLimitForCenter(centerY, imageRect),
        );
        if (maxSide < _minCropSize) return current;
        final side =
            (right - clamped.dx).clamp(_minCropSize, maxSide).toDouble();
        next = Rect.fromLTWH(right - side, centerY - (side / 2), side, side);
      case _CropDragMode.none:
      case _CropDragMode.move:
        return current;
    }

    return Rect.fromLTWH(
      next.left
          .clamp(imageRect.left, imageRect.right - next.width)
          .toDouble(),
      next.top
          .clamp(imageRect.top, imageRect.bottom - next.height)
          .toDouble(),
      math.min(next.width, imageRect.width),
      math.min(next.height, imageRect.height),
    );
  }

  Future<void> _confirmCrop(Rect imageRect) async {
    final image = _decodedImage;
    final cropRect = _cropRect ?? _initialCropRect(imageRect);
    if (image == null || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final displaySize = _displayImageSize(image);
      final renderedWidth = math.max(1, displaySize.width.round());
      final renderedHeight = math.max(1, displaySize.height.round());

      final rotatedRecorder = ui.PictureRecorder();
      final rotatedCanvas = Canvas(rotatedRecorder);
      _paintImageWithRotation(
        rotatedCanvas,
        image: image,
        destRect: Rect.fromLTWH(
          0,
          0,
          renderedWidth.toDouble(),
          renderedHeight.toDouble(),
        ),
        rotationTurns: _rotationTurns,
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
          ..colorFilter = _selectedFilter.colorFilter,
      );

      final picture = recorder.endRecording();
      final rendered = await picture.toImage(
        outputSize.toInt(),
        outputSize.toInt(),
      );
      final byteData = await rendered.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List();

      if (!mounted || bytes == null) {
        if (mounted) setState(() => _isProcessing = false);
        return;
      }

      final croppedPhoto = PickedProfilePhoto(
        file: XFile.fromData(
          bytes,
          name: 'avatar_cropped.png',
          mimeType: 'image/png',
        ),
        bytes: bytes,
        contentType: 'image/png',
      );

      Navigator.of(context).pop(croppedPhoto);
    } catch (_) {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = _decodedImage;

    return Material(
      color: const Color(0xFF050505),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: image == null
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final viewport = Size(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        );
                        _lastViewport = viewport;
                        final imageRect = _computeImageRect(viewport, image);
                        _lastImageRect = imageRect;
                        final cropRect = _cropRect ??= _initialCropRect(imageRect);

                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanStart: (details) {
                            final activeCropRect = _cropRect ?? cropRect;
                            _dragMode = _hitTestCrop(
                              details.localPosition,
                              activeCropRect,
                            );
                          },
                          onPanUpdate: (details) {
                            if (_dragMode == _CropDragMode.none) return;
                            final activeCropRect = _cropRect ?? cropRect;

                            setState(() {
                              if (_dragMode == _CropDragMode.move) {
                                _cropRect = _moveCropRect(
                                  activeCropRect,
                                  details.delta,
                                  imageRect,
                                );
                              } else {
                                _cropRect = _resizeCropRect(
                                  activeCropRect,
                                  details.localPosition,
                                  imageRect,
                                  _dragMode,
                                );
                              }
                            });
                          },
                          onPanEnd: (_) => _dragMode = _CropDragMode.none,
                          onPanCancel: () => _dragMode = _CropDragMode.none,
                          child: SizedBox(
                            width: viewport.width,
                            height: viewport.height,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CustomPaint(
                                  size: viewport,
                                  painter: _PhotoImagePainter(
                                    image: image,
                                    imageRect: imageRect,
                                    rotationTurns: _rotationTurns,
                                    filter: _selectedFilter,
                                  ),
                                ),
                                CustomPaint(
                                  size: viewport,
                                  painter: _CropOverlayPainter(
                                    cropRect: cropRect,
                                  ),
                                ),
                                CustomPaint(
                                  size: viewport,
                                  painter: _CropWindowImagePainter(
                                    image: image,
                                    imageRect: imageRect,
                                    cropRect: cropRect,
                                    rotationTurns: _rotationTurns,
                                    filter: _selectedFilter,
                                  ),
                                ),
                                CustomPaint(
                                  size: viewport,
                                  painter: _CropChromePainter(
                                    cropRect: cropRect,
                                    handleVisualSize: _handleVisualSize,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (image != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
                child: _FilterSelector(
                  imageBytes: widget.photo.bytes,
                  selectedFilter: _selectedFilter,
                  onSelected: _isProcessing
                      ? null
                      : (filter) {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        },
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _isProcessing
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white.withValues(alpha: 0.82),
                        ),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 14),
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                        ),
                        child: IconButton(
                          onPressed: _isProcessing
                              ? null
                              : () {
                                  setState(() {
                                    _rotationTurns = (_rotationTurns + 1) % 4;
                                    _cropRect = null;
                                    _lastImageRect = null;
                                    _dragMode = _CropDragMode.none;
                                  });
                                },
                          icon: const Icon(
                            Icons.rotate_90_degrees_ccw_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      TextButton(
                        onPressed: _isProcessing || image == null
                            ? null
                            : () {
                                final imageRect =
                                    _lastImageRect ??
                                    (_lastViewport == null
                                        ? null
                                        : _computeImageRect(
                                            _lastViewport!,
                                            image,
                                          ));
                                if (imageRect == null) return;
                                _confirmCrop(imageRect);
                              },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF22C55E),
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Color(0xFF22C55E),
                                ),
                              )
                            : const Text('Confirmar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoImagePainter extends CustomPainter {
  const _PhotoImagePainter({
    required this.image,
    required this.imageRect,
    required this.rotationTurns,
    required this.filter,
  });

  final ui.Image image;
  final Rect imageRect;
  final int rotationTurns;
  final _PhotoFilter filter;

  @override
  void paint(Canvas canvas, Size size) {
    _paintImageWithRotation(
      canvas,
      image: image,
      destRect: imageRect,
      rotationTurns: rotationTurns,
      colorFilter: filter.colorFilter,
    );
  }

  @override
  bool shouldRepaint(covariant _PhotoImagePainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.imageRect != imageRect ||
        oldDelegate.rotationTurns != rotationTurns ||
        oldDelegate.filter != filter;
  }
}

class _CropOverlayPainter extends CustomPainter {
  const _CropOverlayPainter({
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
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) {
    return oldDelegate.cropRect != cropRect;
  }
}

class _CropWindowImagePainter extends CustomPainter {
  const _CropWindowImagePainter({
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
  final _PhotoFilter filter;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(cropRect);
    _paintImageWithRotation(
      canvas,
      image: image,
      destRect: imageRect,
      rotationTurns: rotationTurns,
      colorFilter: filter.colorFilter,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CropWindowImagePainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.imageRect != imageRect ||
        oldDelegate.cropRect != cropRect ||
        oldDelegate.rotationTurns != rotationTurns ||
        oldDelegate.filter != filter;
  }
}

class _CropChromePainter extends CustomPainter {
  const _CropChromePainter({
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
  bool shouldRepaint(covariant _CropChromePainter oldDelegate) {
    return oldDelegate.cropRect != cropRect ||
        oldDelegate.handleVisualSize != handleVisualSize;
  }
}

class _FilterSelector extends StatelessWidget {
  const _FilterSelector({
    required this.imageBytes,
    required this.selectedFilter,
    required this.onSelected,
  });

  final Uint8List imageBytes;
  final _PhotoFilter selectedFilter;
  final ValueChanged<_PhotoFilter>? onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 102,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _PhotoFilter.values.map((filter) {
            final isSelected = filter == selectedFilter;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: onSelected == null ? null : () => onSelected!(filter),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 72,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF22C55E)
                          : Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 64,
                          height: 64,
                          child: ColoredBox(
                            color: const Color(0xFF111111),
                            child: filter.colorFilter == null
                                ? Image.memory(
                                    imageBytes,
                                    fit: BoxFit.cover,
                                  )
                                : ColorFiltered(
                                    colorFilter: filter.colorFilter!,
                                    child: Image.memory(
                                      imageBytes,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        filter.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.72),
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

void _paintImageWithRotation(
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
