import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../data/profile_photo_service.dart';
import 'crop_engine.dart';
import 'crop_painters.dart';
import 'image_processor.dart';
import 'photo_filter.dart';

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
      builder: (_) => PhotoCropDialog(
        key: ValueKey(Object.hash(photo.file.path, photo.bytes, photo.contentType)),
        photo: photo,
      ),
    );
  }

  @override
  State<PhotoCropDialog> createState() => _PhotoCropDialogState();
}

class _PhotoCropDialogState extends State<PhotoCropDialog> {
  static const int _previewDecodeTargetWidth = 1440;
  static const double _viewportPadding = 20;
  static const double _handleVisualSize = 24;
  static const double _minCropSize = 110;

  ui.Image? _decodedImage;
  Size? _decodedImageSize;
  Uint8List? _sourceBytes;
  Rect? _cropRect;
  Rect? _lastImageRect;
  Size? _lastViewport;
  CropDragMode _dragMode = CropDragMode.none;
  bool _isProcessing = false;
  bool _hasUserAdjustedCrop = false;
  int _rotationTurns = 0;
  PhotoFilter _selectedFilter = PhotoFilter.original;
  int _decodeRequestId = 0;

  @override
  void initState() {
    super.initState();
    _resetEditorState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _decodePreviewImage();
    });
  }

  @override
  void didUpdateWidget(covariant PhotoCropDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photo.file.path == widget.photo.file.path &&
        oldWidget.photo.bytes == widget.photo.bytes &&
        oldWidget.photo.contentType == widget.photo.contentType) {
      return;
    }

    _resetEditorState();
    _decodePreviewImage();
  }

  void _resetEditorState() {
    _decodedImage = null;
    _decodedImageSize = null;
    _sourceBytes = null;
    _cropRect = null;
    _lastImageRect = null;
    _lastViewport = null;
    _dragMode = CropDragMode.none;
    _isProcessing = false;
    _hasUserAdjustedCrop = false;
    _rotationTurns = 0;
    _selectedFilter = PhotoFilter.original;
  }

  Future<void> _decodePreviewImage() async {
    final requestId = ++_decodeRequestId;
    ui.Image image;
    Size imageSize;
    Uint8List? sourceBytes;
    try {
      sourceBytes = await widget.photo.readBytes();
      final originalImage = await decodeImageFromList(sourceBytes);
      imageSize = Size(
        originalImage.width.toDouble(),
        originalImage.height.toDouble(),
      );

      if (originalImage.width > _previewDecodeTargetWidth) {
        image = await decodeImageBytes(
          sourceBytes,
          targetWidth: _previewDecodeTargetWidth,
        );
      } else {
        image = originalImage;
      }
    } catch (_) {
      image = await buildFallbackImage();
      imageSize = Size(image.width.toDouble(), image.height.toDouble());
    }

    if (!mounted || requestId != _decodeRequestId) return;
    setState(() {
      _decodedImage = image;
      _decodedImageSize = imageSize;
      _sourceBytes = sourceBytes;
    });
  }

  Size _displayImageSize(Size imageSize) {
    final isQuarterTurn = _rotationTurns.isOdd;
    return Size(
      isQuarterTurn ? imageSize.height : imageSize.width,
      isQuarterTurn ? imageSize.width : imageSize.height,
    );
  }

  Rect _computeImageRect(Size viewport, Size imageSize) {
    final displaySize = _displayImageSize(imageSize);
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

  @override
  Widget build(BuildContext context) {
    final image = _decodedImage;
    final imageSize = _decodedImageSize;

    return Material(
      color: const Color(0xFF050505),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: image == null
                  || imageSize == null
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final previousImageRect = _lastImageRect;
                        final viewport = Size(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        );
                        _lastViewport = viewport;
                        final imageRect = _computeImageRect(viewport, imageSize);
                        final shouldResetCropRect =
                            _cropRect == null ||
                            (!_hasUserAdjustedCrop &&
                                previousImageRect != null &&
                                previousImageRect != imageRect);
                        if (shouldResetCropRect) {
                          _cropRect = _initialCropRect(imageRect);
                        }
                        _lastImageRect = imageRect;
                        final cropRect = _cropRect!;

                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanStart: (details) {
                            final activeCropRect = _cropRect ?? cropRect;
                            _dragMode = hitTestCrop(
                              details.localPosition,
                              activeCropRect,
                            );
                          },
                          onPanUpdate: (details) {
                            if (_dragMode == CropDragMode.none) return;
                            final activeCropRect = _cropRect ?? cropRect;

                            setState(() {
                              _hasUserAdjustedCrop = true;
                              if (_dragMode == CropDragMode.move) {
                                _cropRect = moveCropRect(
                                  activeCropRect,
                                  details.delta,
                                  imageRect,
                                );
                              } else {
                                _cropRect = resizeCropRect(
                                  activeCropRect,
                                  details.localPosition,
                                  imageRect,
                                  _dragMode,
                                );
                              }
                            });
                          },
                          onPanEnd: (_) => _dragMode = CropDragMode.none,
                          onPanCancel: () => _dragMode = CropDragMode.none,
                          child: SizedBox(
                            width: viewport.width,
                            height: viewport.height,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CustomPaint(
                                  size: viewport,
                                  painter: PhotoImagePainter(
                                    image: image,
                                    imageRect: imageRect,
                                    rotationTurns: _rotationTurns,
                                    filter: _selectedFilter,
                                  ),
                                ),
                                CustomPaint(
                                  size: viewport,
                                  painter: CropOverlayPainter(
                                    cropRect: cropRect,
                                  ),
                                ),
                                CustomPaint(
                                  size: viewport,
                                  painter: CropWindowImagePainter(
                                    image: image,
                                    imageRect: imageRect,
                                    cropRect: cropRect,
                                    rotationTurns: _rotationTurns,
                                    filter: _selectedFilter,
                                  ),
                                ),
                                CustomPaint(
                                  size: viewport,
                                  painter: CropChromePainter(
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
                child: FilterSelector(
                  photoBytes: _sourceBytes,
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
                                    _dragMode = CropDragMode.none;
                                    _hasUserAdjustedCrop = false;
                                  });
                                },
                          icon: const Icon(
                            Icons.rotate_90_degrees_ccw,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      TextButton(
                        onPressed: _isProcessing || image == null
                            ? null
                            : () async {
                                final imageRect =
                                    _lastImageRect ??
                                    (_lastViewport == null || imageSize == null
                                        ? null
                                        : _computeImageRect(
                                            _lastViewport!,
                                            imageSize,
                                          ));
                                if (imageRect == null) return;
                                final cropRect =
                                    _cropRect ?? _initialCropRect(imageRect);
                                if (_decodedImage == null || _isProcessing) {
                                  return;
                                }

                                setState(() => _isProcessing = true);
                                final croppedPhoto = await confirmCrop(
                                  cropRect: cropRect,
                                  imageRect: imageRect,
                                  photo: widget.photo,
                                  sourceBytes: _sourceBytes,
                                  rotationTurns: _rotationTurns,
                                  selectedFilter: _selectedFilter,
                                );

                                if (!mounted) return;
                                if (croppedPhoto == null) {
                                  setState(() => _isProcessing = false);
                                  return;
                                }

                                Navigator.of(context).pop(croppedPhoto);
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
