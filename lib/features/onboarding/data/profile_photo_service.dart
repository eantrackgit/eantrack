import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PickedProfilePhoto {
  const PickedProfilePhoto({
    required this.file,
    required this.contentType,
    this.bytes,
  });

  final XFile file;
  final String contentType;
  final Uint8List? bytes;

  Future<Uint8List> readBytes() async {
    if (bytes != null) return bytes!;
    return await file.readAsBytes();
  }
}

abstract class ProfilePhotoService {
  Future<String?> loadImageUrl();
  Future<PickedProfilePhoto?> pickImage(ImageSource source);
  Future<String?> uploadProfilePhoto(PickedProfilePhoto photo);
  Future<void> removeProfilePhoto();
}

class SupabaseProfilePhotoService implements ProfilePhotoService {
  SupabaseProfilePhotoService({
    required SupabaseClient client,
    ImagePicker? picker,
  })  : _client = client,
        _picker = picker ?? ImagePicker();

  static const _bucketName = 'profile-photos';
  static const _profileTable = 'tab_cadastroauxiliar';
  static const _photoColumn = 'photourl';

  final SupabaseClient _client;
  final ImagePicker _picker;

  @override
  Future<String?> loadImageUrl() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _client
          .from(_profileTable)
          .select(_photoColumn)
          .eq('user_id', userId)
          .maybeSingle();

      return response?[_photoColumn] as String?;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<PickedProfilePhoto?> pickImage(ImageSource source) async {
    final file = await _picker.pickImage(source: source);
    if (file == null) return null;

    return PickedProfilePhoto(
      file: file,
      contentType: file.mimeType ?? _inferContentType(file.name),
    );
  }

  @override
  Future<String?> uploadProfilePhoto(PickedProfilePhoto photo) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    final bytes = await photo.readBytes();

    final path = _storagePathForUser(userId, photo.contentType);

    try {
      await _ensureBucketExists();
      await _removeKnownProfileFiles(userId);
      await _client.storage.from(_bucketName).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: photo.contentType,
            ),
          );

      final publicUrl = _client.storage.from(_bucketName).getPublicUrl(path);
      await _persistImageUrl(userId, publicUrl);
      return publicUrl;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> removeProfilePhoto() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _removeKnownProfileFiles(userId);
    } catch (_) {}

    try {
      await _persistImageUrl(userId, null);
    } catch (_) {}
  }

  Future<void> _ensureBucketExists() async {
    try {
      final bucket = await _client.storage.getBucket(_bucketName);
      if (bucket.public) return;

      await _client.storage.updateBucket(
        _bucketName,
        const BucketOptions(
          public: true,
          fileSizeLimit: '5MB',
          allowedMimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
        ),
      );
    } on StorageException {
      try {
        await _client.storage.createBucket(
          _bucketName,
          const BucketOptions(
            public: true,
            fileSizeLimit: '5MB',
            allowedMimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
          ),
        );
      } on StorageException catch (error) {
        final message = error.message.toLowerCase();
        if (!message.contains('already exists')) {
          rethrow;
        }
      }
    }
  }

  Future<void> _persistImageUrl(String userId, String? imageUrl) async {
    final existingProfile = await _client
        .from(_profileTable)
        .select('user_id')
        .eq('user_id', userId)
        .maybeSingle();

    if (existingProfile == null) {
      await _client.from(_profileTable).insert({
        'user_id': userId,
        _photoColumn: imageUrl,
      });
      return;
    }

    await _client
        .from(_profileTable)
        .update({_photoColumn: imageUrl}).eq('user_id', userId);
  }

  Future<void> _removeKnownProfileFiles(String userId) async {
    await _client.storage.from(_bucketName).remove([
      '$userId/avatar.jpg',
      '$userId/avatar.jpeg',
      '$userId/avatar.png',
      '$userId/avatar.webp',
    ]);
  }

  String _storagePathForUser(String userId, String contentType) {
    if (contentType == 'image/png') {
      return '$userId/avatar.png';
    }
    if (contentType == 'image/webp') {
      return '$userId/avatar.webp';
    }
    return '$userId/avatar.jpg';
  }

  String _inferContentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
