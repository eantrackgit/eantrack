import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_exception.dart';

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
  Future<String> uploadProfilePhoto(PickedProfilePhoto photo);
  Future<void> removeProfilePhoto();
}

class SupabaseProfilePhotoService implements ProfilePhotoService {
  SupabaseProfilePhotoService({
    required SupabaseClient client,
    ImagePicker? picker,
  })  : _client = client,
        _picker = picker ?? ImagePicker();

  static const _bucketName = 'urlperfiluser';
  static const _profileTable = 'tab_cadastroauxiliar';
  static const _photoColumn = 'photourl';
  static const _thumbColumn = 'thumburl';
  static const _storedImageContentType = 'image/webp';
  static const _originalPath = 'original.webp';
  static const _thumbPath = 'thumb.webp';
  static const _originalSize = 500;
  static const _thumbSize = 120;

  final SupabaseClient _client;
  final ImagePicker _picker;

  @override
  Future<String?> loadImageUrl() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _client
          .from(_profileTable)
          .select('$_photoColumn,$_thumbColumn')
          .eq('user_id', userId)
          .maybeSingle();

      return response?[_photoColumn] as String? ??
          response?[_thumbColumn] as String?;
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
  Future<String> uploadProfilePhoto(PickedProfilePhoto photo) async {
    final userId = _requireUserId();
    final rawBytes = await photo.readBytes();
    final originalBytes = await _encodeWebP(rawBytes, _originalSize);
    final thumbBytes = await _encodeWebP(rawBytes, _thumbSize);
    final storage = _client.storage.from(_bucketName);

    try {
      await storage.uploadBinary(
        _storagePathForUser(userId, _originalPath),
        originalBytes,
        fileOptions: const FileOptions(
          upsert: true,
          contentType: _storedImageContentType,
        ),
      );
      await storage.uploadBinary(
        _storagePathForUser(userId, _thumbPath),
        thumbBytes,
        fileOptions: const FileOptions(
          upsert: true,
          contentType: _storedImageContentType,
        ),
      );
    } on StorageException catch (e) {
      throw ServerException(
        'Nao foi possivel salvar a foto de perfil. ${e.message}',
      );
    }

    final photoUrl =
        _client.storage.from(_bucketName).getPublicUrl(_storagePathForUser(userId, _originalPath));
    final thumbUrl =
        _client.storage.from(_bucketName).getPublicUrl(_storagePathForUser(userId, _thumbPath));

    try {
      await _persistImageUrls(
        userId,
        photoUrl: photoUrl,
        thumbUrl: thumbUrl,
      );
    } on PostgrestException catch (e) {
      throw ServerException(
        'Nao foi possivel salvar a foto de perfil. (${e.code})',
      );
    }

    return photoUrl;
  }

  @override
  Future<void> removeProfilePhoto() async {
    final userId = _requireUserId();
    try {
      await _removeKnownProfileFiles(userId);
    } on StorageException catch (e) {
      throw ServerException(
        'Nao foi possivel remover a foto de perfil. ${e.message}',
      );
    }

    try {
      await _persistImageUrls(userId, photoUrl: null, thumbUrl: null);
    } on PostgrestException catch (e) {
      throw ServerException(
        'Nao foi possivel remover a foto de perfil. (${e.code})',
      );
    }
  }

  Future<void> _persistImageUrls(
    String userId, {
    required String? photoUrl,
    required String? thumbUrl,
  }) async {
    final updatedProfile = await _client
        .from(_profileTable)
        .update({
          _photoColumn: photoUrl,
          _thumbColumn: thumbUrl,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('user_id', userId)
        .select('user_id')
        .maybeSingle();

    if (updatedProfile == null) {
      throw const ServerException(
        'Cadastro complementar nao encontrado para salvar a foto.',
      );
    }
  }

  Future<void> _removeKnownProfileFiles(String userId) async {
    await _client.storage.from(_bucketName).remove([
      _storagePathForUser(userId, _originalPath),
      _storagePathForUser(userId, _thumbPath),
      '$userId/original.jpg',
      '$userId/original.png',
      '$userId/thumb.jpg',
      '$userId/thumb.png',
      '$userId/avatar.jpg',
      '$userId/avatar.jpeg',
      '$userId/avatar.png',
      '$userId/avatar.webp',
    ]);
  }

  String _storagePathForUser(String userId, String fileName) {
    return '$userId/$fileName';
  }

  Future<Uint8List> _encodeWebP(Uint8List sourceBytes, int size) async {
    final result = await FlutterImageCompress.compressWithList(
      sourceBytes,
      minWidth: size,
      minHeight: size,
      quality: size >= _originalSize ? 88 : 80,
      format: CompressFormat.webp,
      keepExif: false,
    );
    if (result.isEmpty) {
      throw const ServerException(
        'Nao foi possivel processar a imagem de perfil.',
      );
    }
    return result;
  }

  String _inferContentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const ServerException('Usuario nao autenticado.');
    }
    return userId;
  }
}
