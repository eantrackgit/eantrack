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
    this.draftPhoto,
    this.draftImageBytes,
    this.imageUrl,
    this.isUploading = false,
  });

  static const _sentinel = Object();

  final PickedProfilePhoto? draftPhoto;
  final Uint8List? draftImageBytes;
  final String? imageUrl;
  final bool isUploading;

  bool get hasPhoto =>
      draftImageBytes != null || (imageUrl?.trim().isNotEmpty ?? false);

  ImageProvider<Object>? get imageProvider {
    if (draftImageBytes != null) {
      return MemoryImage(draftImageBytes!);
    }

    final url = imageUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return NetworkImage(url);
    }

    return null;
  }

  PhotoProfileState copyWith({
    Object? draftPhoto = _sentinel,
    Object? draftImageBytes = _sentinel,
    Object? imageUrl = _sentinel,
    bool? isUploading,
  }) {
    return PhotoProfileState(
      draftPhoto: identical(draftPhoto, _sentinel)
          ? this.draftPhoto
          : draftPhoto as PickedProfilePhoto?,
      draftImageBytes: identical(draftImageBytes, _sentinel)
          ? this.draftImageBytes
          : draftImageBytes as Uint8List?,
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

    final photoBytes = await photo.readBytes();
    if (!mounted) return;

    state = state.copyWith(
      draftPhoto: PickedProfilePhoto(
        file: photo.file,
        bytes: photoBytes,
        contentType: photo.contentType,
      ),
      draftImageBytes: photoBytes,
    );
  }

  Future<void> persistPhoto() async {
    if (state.isUploading) return;

    final draftPhoto = state.draftPhoto;
    if (draftPhoto == null) return;

    state = state.copyWith(isUploading: true);

    try {
      final uploadedUrl = await _service.uploadProfilePhoto(draftPhoto);
      if (!mounted) return;
      state = state.copyWith(
        imageUrl: uploadedUrl,
        isUploading: false,
      );
    } catch (_) {
      if (!mounted) rethrow;
      state = state.copyWith(isUploading: false);
      rethrow;
    }
  }

  Future<void> removePhoto() async {
    if (state.isUploading) return;

    final previousDraftPhoto = state.draftPhoto;
    final previousDraftBytes = state.draftImageBytes;
    final previousImageUrl = state.imageUrl;
    final hasPersistedPhoto = previousImageUrl?.trim().isNotEmpty ?? false;

    state = state.copyWith(
      draftPhoto: null,
      draftImageBytes: null,
      imageUrl: null,
      isUploading: hasPersistedPhoto,
    );

    if (!hasPersistedPhoto) return;

    try {
      await _service.removeProfilePhoto();
      if (!mounted) return;
      state = state.copyWith(isUploading: false);
    } catch (_) {
      if (!mounted) rethrow;
      state = state.copyWith(
        draftPhoto: previousDraftPhoto,
        draftImageBytes: previousDraftBytes,
        imageUrl: previousImageUrl,
        isUploading: false,
      );
      rethrow;
    }
  }
}
