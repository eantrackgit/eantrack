import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/profile_photo_service.dart';

final profilePhotoServiceProvider = Provider<ProfilePhotoService>((ref) {
  return SupabaseProfilePhotoService(client: Supabase.instance.client);
});

final photoProfileNotifierProvider = StateNotifierProvider.autoDispose<
    PhotoProfileNotifier, PhotoProfileState>((ref) {
  final notifier = PhotoProfileNotifier(ref.watch(profilePhotoServiceProvider));
  unawaited(notifier.load());
  return notifier;
});

class PhotoProfileState {
  const PhotoProfileState({
    this.localImage,
    this.localImageBytes,
    this.imageUrl,
    this.isUploading = false,
  });

  static const _sentinel = Object();

  final XFile? localImage;
  final Uint8List? localImageBytes;
  final String? imageUrl;
  final bool isUploading;

  bool get hasPhoto =>
      localImageBytes != null || (imageUrl?.trim().isNotEmpty ?? false);

  ImageProvider<Object>? get imageProvider {
    if (localImageBytes != null) {
      return MemoryImage(localImageBytes!);
    }

    final url = imageUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return NetworkImage(url);
    }

    return null;
  }

  PhotoProfileState copyWith({
    Object? localImage = _sentinel,
    Object? localImageBytes = _sentinel,
    Object? imageUrl = _sentinel,
    bool? isUploading,
  }) {
    return PhotoProfileState(
      localImage:
          identical(localImage, _sentinel) ? this.localImage : localImage as XFile?,
      localImageBytes: identical(localImageBytes, _sentinel)
          ? this.localImageBytes
          : localImageBytes as Uint8List?,
      imageUrl: identical(imageUrl, _sentinel) ? this.imageUrl : imageUrl as String?,
      isUploading: isUploading ?? this.isUploading,
    );
  }
}

class PhotoProfileNotifier extends StateNotifier<PhotoProfileState> {
  PhotoProfileNotifier(this._service) : super(const PhotoProfileState());

  final ProfilePhotoService _service;

  Future<void> load() async {
    final imageUrl = await _service.loadImageUrl();
    if (!mounted || imageUrl == null || imageUrl.trim().isEmpty) return;
    state = state.copyWith(imageUrl: imageUrl);
  }

  Future<PickedProfilePhoto?> pickFromCamera() async {
    return pickImage(ImageSource.camera);
  }

  Future<PickedProfilePhoto?> pickFromGallery() async {
    return pickImage(ImageSource.gallery);
  }

  Future<PickedProfilePhoto?> pickImage(ImageSource source) async {
    if (state.isUploading) return null;
    try {
      return await _service.pickImage(source);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveCroppedPhoto(PickedProfilePhoto photo) async {
    if (state.isUploading) return;

    final previousImageUrl = state.imageUrl;
    state = state.copyWith(isUploading: true);

    try {
      if (!mounted) return;
      state = state.copyWith(
        localImage: photo.file,
        localImageBytes: photo.bytes,
      );

      final uploadedUrl = await _service.uploadProfilePhoto(photo);
      if (!mounted) return;

      state = state.copyWith(
        imageUrl: uploadedUrl ?? previousImageUrl,
        isUploading: false,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(isUploading: false);
    }
  }

  Future<void> removePhoto() async {
    if (state.isUploading) return;

    state = state.copyWith(
      localImage: null,
      localImageBytes: null,
      imageUrl: null,
      isUploading: true,
    );

    try {
      await _service.removeProfilePhoto();
    } catch (_) {
      // UX silenciosa por requisito.
    } finally {
      if (!mounted) return;
      state = state.copyWith(isUploading: false);
    }
  }
}
