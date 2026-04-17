import 'package:flutter/material.dart';

import '../../../../shared/shared.dart';

class CompCameraOrGallery extends StatefulWidget {
  const CompCameraOrGallery({
    super.key,
    required this.hasPhoto,
    required this.onCamera,
    required this.onGallery,
    required this.onClose,
    this.onRemovePhoto,
  });

  final bool hasPhoto;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onClose;
  final Future<void> Function()? onRemovePhoto;

  @override
  State<CompCameraOrGallery> createState() => _CompCameraOrGalleryState();
}

class _CompCameraOrGalleryState extends State<CompCameraOrGallery> {
  bool _isRemoving = false;

  Future<void> _handleRemove() async {
    if (_isRemoving || widget.onRemovePhoto == null) return;

    setState(() => _isRemoving = true);
    try {
      await widget.onRemovePhoto!.call();
    } finally {
      if (mounted) {
        setState(() => _isRemoving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: et.cardSurface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: et.surfaceBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetActionTile(
              icon: Icons.photo_camera,
              label: 'Câmera',
              onTap: widget.onCamera,
            ),
            Divider(height: 1, color: et.surfaceBorder),
            _SheetActionTile(
              icon: Icons.photo_library_outlined,
              label: 'Escolher nas Fotos',
              onTap: widget.onGallery,
            ),
            Divider(height: 1, color: et.surfaceBorder),
            _SheetActionTile(
              icon: widget.hasPhoto ? Icons.delete_outline : Icons.close,
              label: widget.hasPhoto ? 'Remover foto' : 'Cancelar',
              onTap: widget.hasPhoto ? _handleRemove : widget.onClose,
              foregroundColor: widget.hasPhoto ? AppColors.error : et.primaryText,
              isLoading: _isRemoving,
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetActionTile extends StatelessWidget {
  const _SheetActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.foregroundColor,
    this.isLoading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? foregroundColor;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    final color = foregroundColor ?? et.primaryText;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: color,
                  ),
                )
              else
                Icon(icon, color: color, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
