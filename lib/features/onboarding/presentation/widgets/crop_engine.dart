import 'dart:math' as math;
import 'dart:ui';

const double _handleHitSize = 34;
const double _minCropSize = 110;

enum CropDragMode {
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

CropDragMode hitTestCrop(Offset localPosition, Rect cropRect) {
  final handles = <CropDragMode, Offset>{
    CropDragMode.topLeft: cropRect.topLeft,
    CropDragMode.top: cropRect.topCenter,
    CropDragMode.topRight: cropRect.topRight,
    CropDragMode.right: cropRect.centerRight,
    CropDragMode.bottomRight: cropRect.bottomRight,
    CropDragMode.bottom: cropRect.bottomCenter,
    CropDragMode.bottomLeft: cropRect.bottomLeft,
    CropDragMode.left: cropRect.centerLeft,
  };

  for (final entry in handles.entries) {
    final handleRect = Rect.fromCenter(
      center: entry.value,
      width: _handleHitSize,
      height: _handleHitSize,
    );
    if (handleRect.contains(localPosition)) return entry.key;
  }

  if (cropRect.contains(localPosition)) return CropDragMode.move;
  return CropDragMode.none;
}

Offset clampToImageRect(Offset position, Rect imageRect) {
  return Offset(
    position.dx.clamp(imageRect.left, imageRect.right).toDouble(),
    position.dy.clamp(imageRect.top, imageRect.bottom).toDouble(),
  );
}

Rect moveCropRect(Rect current, Offset delta, Rect imageRect) {
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

double horizontalLimitForCenter(double centerX, Rect imageRect) {
  return math.min(
        centerX - imageRect.left,
        imageRect.right - centerX,
      ) *
      2;
}

double verticalLimitForCenter(double centerY, Rect imageRect) {
  return math.min(
        centerY - imageRect.top,
        imageRect.bottom - centerY,
      ) *
      2;
}

Rect resizeCropRect(
  Rect current,
  Offset localPosition,
  Rect imageRect,
  CropDragMode mode,
) {
  final clamped = clampToImageRect(localPosition, imageRect);
  late final Rect next;

  switch (mode) {
    case CropDragMode.topLeft:
      final anchor = current.bottomRight;
      final side = math.max(
        _minCropSize,
        math.min(anchor.dx - clamped.dx, anchor.dy - clamped.dy),
      );
      next = Rect.fromLTWH(anchor.dx - side, anchor.dy - side, side, side);
    case CropDragMode.top:
      final centerX = current.center.dx;
      final bottom = current.bottom;
      final maxSide = math.min(
        horizontalLimitForCenter(centerX, imageRect),
        bottom - imageRect.top,
      );
      if (maxSide < _minCropSize) return current;
      final side =
          (bottom - clamped.dy).clamp(_minCropSize, maxSide).toDouble();
      next = Rect.fromLTWH(centerX - (side / 2), bottom - side, side, side);
    case CropDragMode.topRight:
      final anchor = current.bottomLeft;
      final side = math.max(
        _minCropSize,
        math.min(clamped.dx - anchor.dx, anchor.dy - clamped.dy),
      );
      next = Rect.fromLTWH(anchor.dx, anchor.dy - side, side, side);
    case CropDragMode.right:
      final centerY = current.center.dy;
      final left = current.left;
      final maxSide = math.min(
        imageRect.right - left,
        verticalLimitForCenter(centerY, imageRect),
      );
      if (maxSide < _minCropSize) return current;
      final side = (clamped.dx - left).clamp(_minCropSize, maxSide).toDouble();
      next = Rect.fromLTWH(left, centerY - (side / 2), side, side);
    case CropDragMode.bottomRight:
      final anchor = current.topLeft;
      final side = math.max(
        _minCropSize,
        math.min(clamped.dx - anchor.dx, clamped.dy - anchor.dy),
      );
      next = Rect.fromLTWH(anchor.dx, anchor.dy, side, side);
    case CropDragMode.bottom:
      final centerX = current.center.dx;
      final top = current.top;
      final maxSide = math.min(
        horizontalLimitForCenter(centerX, imageRect),
        imageRect.bottom - top,
      );
      if (maxSide < _minCropSize) return current;
      final side = (clamped.dy - top).clamp(_minCropSize, maxSide).toDouble();
      next = Rect.fromLTWH(centerX - (side / 2), top, side, side);
    case CropDragMode.bottomLeft:
      final anchor = current.topRight;
      final side = math.max(
        _minCropSize,
        math.min(anchor.dx - clamped.dx, clamped.dy - anchor.dy),
      );
      next = Rect.fromLTWH(anchor.dx - side, anchor.dy, side, side);
    case CropDragMode.left:
      final centerY = current.center.dy;
      final right = current.right;
      final maxSide = math.min(
        right - imageRect.left,
        verticalLimitForCenter(centerY, imageRect),
      );
      if (maxSide < _minCropSize) return current;
      final side =
          (right - clamped.dx).clamp(_minCropSize, maxSide).toDouble();
      next = Rect.fromLTWH(right - side, centerY - (side / 2), side, side);
    case CropDragMode.none:
    case CropDragMode.move:
      return current;
  }

  return Rect.fromLTWH(
    next.left.clamp(imageRect.left, imageRect.right - next.width).toDouble(),
    next.top.clamp(imageRect.top, imageRect.bottom - next.height).toDouble(),
    math.min(next.width, imageRect.width),
    math.min(next.height, imageRect.height),
  );
}
