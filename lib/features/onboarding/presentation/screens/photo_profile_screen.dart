import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/shared.dart';
import '../providers/photo_profile_provider.dart';
import '../widgets/comp_camera_or_gallery.dart';
import '../widgets/photo_crop_dialog.dart';

class PagPhotoProfile extends ConsumerWidget {
  const PagPhotoProfile({super.key});

  Future<void> _pickCropAndUpload(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    final notifier = ref.read(photoProfileNotifierProvider.notifier);
    final pickedPhoto = await notifier.pickImage(source);
    if (pickedPhoto == null || !context.mounted) return;

    final croppedPhoto = await PhotoCropDialog.show(
      context,
      photo: pickedPhoto,
    );
    if (croppedPhoto == null) return;

    await notifier.saveCroppedPhoto(croppedPhoto);
  }

  Future<void> _showPhotoActions(
    BuildContext context,
    WidgetRef ref,
    PhotoProfileState state,
  ) async {
    if (state.isUploading) return;

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return CompCameraOrGallery(
          hasPhoto: state.hasPhoto,
          onCamera: () async {
            Navigator.of(sheetContext).pop();
            await _pickCropAndUpload(context, ref, ImageSource.camera);
          },
          onGallery: () async {
            Navigator.of(sheetContext).pop();
            await _pickCropAndUpload(context, ref, ImageSource.gallery);
          },
          onClose: () => Navigator.of(sheetContext).pop(),
          onRemovePhoto: () async {
            await ref.read(photoProfileNotifierProvider.notifier).removePhoto();
            if (sheetContext.mounted) {
              Navigator.of(sheetContext).pop();
            }
          },
        );
      },
    );
  }

  Future<void> _showPhotoPreview(
    BuildContext context,
    WidgetRef ref,
    PhotoProfileState state,
  ) async {
    final imageProvider = state.imageProvider;
    if (state.isUploading || imageProvider == null) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (dialogContext) {
        return _PhotoPreviewDialog(
          imageProvider: imageProvider,
          onEdit: () async {
            Navigator.of(dialogContext).pop();
            await _showPhotoActions(context, ref, state);
          },
        );
      },
    );
  }

  void _closeScreen(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final et = EanTrackTheme.of(context);
    final state = ref.watch(photoProfileNotifierProvider);

    return AuthScaffold(
      padding: const EdgeInsets.all(AppSpacing.xl),
      showVersionBadge: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Foto do perfil ',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: et.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: '(opcional)',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: et.secondaryText,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Personalize seu perfil agora ou faça isso depois.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: et.secondaryText,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Column(
              children: [
                SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        key: const Key('photo-profile-avatar'),
                        onTap: state.isUploading
                            ? null
                            : () {
                                if (state.hasPhoto &&
                                    state.imageProvider != null) {
                                  _showPhotoPreview(context, ref, state);
                                  return;
                                }
                                _showPhotoActions(context, ref, state);
                              },
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 6,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.10),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: ColoredBox(
                              color: const Color(0xFF666B70),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                child: state.imageProvider != null
                                    ? SizedBox.expand(
                                        key: ValueKey(state.imageProvider),
                                        child: Image(
                                          image: state.imageProvider!,
                                          fit: BoxFit.cover,
                                          alignment: Alignment.center,
                                          errorBuilder: (_, __, ___) {
                                            return const _EmptyAvatarContent();
                                          },
                                        ),
                                      )
                                    : const _EmptyAvatarContent(),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 6,
                        bottom: 10,
                        child: _PhotoOverlayButton(
                          hasPhoto: state.hasPhoto,
                          isBusy: state.isUploading,
                          onTap: () => _showPhotoActions(context, ref, state),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  state.hasPhoto
                      ? 'Toque para editar'
                      : 'Toque para adicionar uma imagem',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: et.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl + AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppButton.secondary(
                  'Pular',
                  onPressed:
                      state.isUploading ? null : () => _closeScreen(context),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton.primary(
                'Salvar  ✓',
                  onPressed:
                      state.isUploading ? null : () => _closeScreen(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyAvatarContent extends StatelessWidget {
  const _EmptyAvatarContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.person_rounded,
        size: 128,
        color: Colors.white.withValues(alpha: 0.94),
      ),
    );
  }
}

class _PhotoOverlayButton extends StatelessWidget {
  const _PhotoOverlayButton({
    required this.onTap,
    required this.isBusy,
    required this.hasPhoto,
  });

  final VoidCallback onTap;
  final bool isBusy;
  final bool hasPhoto;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('photo-profile-action-button'),
        onTap: isBusy ? null : onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hasPhoto
                ? AppColors.success
                : Colors.white.withValues(alpha: 0.96),
            border: Border.all(
              color: hasPhoto ? Colors.white : const Color(0xFFF0F2F6),
              width: hasPhoto ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: hasPhoto ? const _PhotoOverlayCheck() : const _PhotoOverlayCamera(),
        ),
      ),
    );
  }
}

class _PhotoOverlayCamera extends StatelessWidget {
  const _PhotoOverlayCamera();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 30,
        height: 30,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Center(
              child: Icon(
                Icons.photo_camera_outlined,
                size: 28,
                color: Color(0xFFD6DAE3),
              ),
            ),
            Positioned(
              top: -1,
              left: -1,
              child: Container(
                width: 15,
                height: 15,
                decoration: const BoxDecoration(
                  color: Color(0xFFE9EDF5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  size: 11,
                  color: Color(0xFFD6DAE3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoOverlayCheck extends StatelessWidget {
  const _PhotoOverlayCheck();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
                      Icons.edit_rounded,
        size: 28,
        color: Colors.white,
      ),
    );
  }
}

class _PhotoPreviewDialog extends StatelessWidget {
  const _PhotoPreviewDialog({
    required this.imageProvider,
    required this.onEdit,
  });

  final ImageProvider<Object> imageProvider;
  final Future<void> Function() onEdit;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.opaque,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.modalOverlayBase.withValues(alpha: 0.88),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.actionBlue.withValues(alpha: 0.10),
                      Colors.black.withValues(alpha: 0.08),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    splashRadius: 20,
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withValues(alpha: 0.78),
                      size: 26,
                    ),
                  ),
                ),
                Center(
                  child: GestureDetector(
                    onTap: () {},
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 28,
                      ),
                      child: Image(
                        image: imageProvider,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) {
                          return const _EmptyAvatarContent();
                        },
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 24,
                  bottom: 24,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.14),
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: onEdit,
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
