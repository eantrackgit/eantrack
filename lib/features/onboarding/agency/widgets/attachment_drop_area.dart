import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';

import '../../../../shared/shared.dart';
import '../models/agency_representative_model.dart';

class AttachmentDropArea extends StatelessWidget {
  const AttachmentDropArea({
    required this.label,
    required this.file,
    required this.copyText,
    required this.acceptsPdfOnly,
    required this.onAttach,
    required this.onDroppedFile,
    required this.onRemove,
  });

  final String label;
  final AgencyRepresentativePickedFile? file;
  final String copyText;
  final bool acceptsPdfOnly;
  final VoidCallback onAttach;
  final void Function(AgencyRepresentativePickedFile) onDroppedFile;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return DragTarget<Object>(
      onWillAcceptWithDetails: (details) =>
          _extractExtensionFromData(details.data) != null,
      onAcceptWithDetails: (details) async {
        final data = details.data;
        final extension = _extractExtensionFromData(data);
        if (extension == null) return;

        XFile? xFile;
        if (data is XFile) {
          xFile = data;
        } else if (data is Uri && data.scheme == 'file') {
          xFile = XFile(data.toFilePath());
        }

        if (xFile == null) return;

        final sizeInBytes = await xFile.length();
        if (sizeInBytes > 5 * 1024 * 1024) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('O arquivo excede o limite de 5MB.'),
              ),
            );
          }
          return;
        }

        final Uint8List bytes = await xFile.readAsBytes();
        if (bytes.isEmpty) return;

        final fileName =
            xFile.name.isNotEmpty ? xFile.name : xFile.path.split('/').last;

        if (!context.mounted) return;

        onDroppedFile(
          AgencyRepresentativePickedFile(
            fileName: fileName,
            bytes: bytes,
            sizeInBytes: sizeInBytes,
            contentType: _contentTypeFromExtension(extension),
          ),
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isDragActive = candidateData.isNotEmpty;
        final hasFile = file != null;
        final et = EanTrackTheme.of(context);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppRadius.smAll,
            onTap: hasFile ? null : onAttach,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: hasFile
                    ? AppColors.success.withValues(alpha: 0.08)
                    : isDragActive
                        ? AppColors.actionBlue.withValues(alpha: 0.06)
                        : et.inputFill,
                borderRadius: AppRadius.smAll,
                border: hasFile
                    ? Border.all(
                        color: AppColors.success.withValues(alpha: 0.28),
                      )
                    : null,
              ),
              child: CustomPaint(
                painter: hasFile
                    ? null
                    : DashedBorderPainter(
                        color: isDragActive
                            ? AppColors.actionBlue
                            : et.inputBorder,
                        radius: AppRadius.sm,
                      ),
                child: hasFile
                    ? AttachmentLoadedState(
                        label: label,
                        file: file!,
                        onRemove: onRemove,
                      )
                    : Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: AttachmentEmptyState(
                          label: label,
                          copyText: copyText,
                          isDragActive: isDragActive,
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  String? _extractExtensionFromData(Object? data) {
    String? pathLike;

    if (data is XFile) {
      pathLike = data.name.isNotEmpty ? data.name : data.path;
    } else if (data is Uri) {
      pathLike = data.path;
    } else if (data is String) {
      pathLike = data;
    }

    if (pathLike == null || pathLike.isEmpty) return null;

    final dotIndex = pathLike.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == pathLike.length - 1) return null;

    final extension = pathLike.substring(dotIndex + 1).toLowerCase();
    if (!_isAcceptedExtension(extension)) return null;
    return extension;
  }

  bool _isAcceptedExtension(String extension) {
    if (acceptsPdfOnly) return extension == 'pdf';
    return extension == 'jpg' ||
        extension == 'jpeg' ||
        extension == 'png' ||
        extension == 'pdf';
  }

  String _contentTypeFromExtension(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }
}

class AttachmentEmptyState extends StatelessWidget {
  const AttachmentEmptyState({
    required this.label,
    required this.copyText,
    required this.isDragActive,
  });

  final String label;
  final String copyText;
  final bool isDragActive;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: et.primaryText,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Icon(
          Icons.upload_file_outlined,
          size: 36,
          color: isDragActive ? AppColors.actionBlue : et.secondaryText,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Arraste ou clique para anexar',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: et.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          copyText,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(
            color: et.secondaryText,
          ),
        ),
      ],
    );
  }
}

class AttachmentLoadedState extends StatelessWidget {
  const AttachmentLoadedState({
    required this.label,
    required this.file,
    required this.onRemove,
  });

  final String label;
  final AgencyRepresentativePickedFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.check_circle_rounded,
            size: 22,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: et.primaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                file.fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: et.primaryText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatFileSize(file.sizeInBytes),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: et.secondaryText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _DestructiveOutlinedButton(
          label: 'Remover',
          onPressed: onRemove,
        ),
      ],
    );
  }

  String _formatFileSize(int sizeInBytes) {
    if (sizeInBytes < 1024 * 1024) {
      final sizeInKb = sizeInBytes / 1024;
      return '${sizeInKb.toStringAsFixed(0)} KB';
    }

    final sizeInMb = sizeInBytes / (1024 * 1024);
    return '${sizeInMb.toStringAsFixed(1)} MB';
  }
}

class _DestructiveOutlinedButton extends StatelessWidget {
  const _DestructiveOutlinedButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: const BorderSide(color: AppColors.error, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColors.error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  const DashedBorderPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );

    const dashWidth = 8.0;
    const dashSpace = 6.0;
    final path = Path()..addRRect(rect);

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final nextDistance = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, nextDistance),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
