import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/agency_representative_model.dart';

/// Serviço responsável por validação local, upload e persistência do representante.
class AgencyRepresentativeService {
  AgencyRepresentativeService({
    SupabaseClient? supabaseClient,
  }) : _supabaseClient = supabaseClient ?? Supabase.instance.client;

  static const String _bucketName = 'doc_legal_representatives';
  static const int _maxFileSizeInBytes = 5 * 1024 * 1024;

  final SupabaseClient _supabaseClient;

  /// Valida e constrói um [AgencyRepresentativePickedFile] a partir de um
  /// [PlatformFile] obtido via FilePicker.
  ///
  /// Lança [AgencyRepresentativeServiceException] se o formato ou tamanho forem
  /// inválidos, ou se não for possível ler os bytes do arquivo.
  AgencyRepresentativePickedFile buildPickedFile(
    PlatformFile file, {
    required bool pdfOnly,
  }) {
    final fileName = file.name.trim();
    final extension = _extractExtension(fileName);

    if (!_isAcceptedExtension(extension)) {
      throw const AgencyRepresentativeServiceException(
        'Formato inválido. Envie um arquivo JPG, PNG ou PDF.',
      );
    }

    if (pdfOnly && extension != 'pdf') {
      throw const AgencyRepresentativeServiceException(
        'Para C. Social, envie apenas um arquivo PDF.',
      );
    }

    if (file.size > _maxFileSizeInBytes) {
      throw const AgencyRepresentativeServiceException(
        'O arquivo excede o limite de 5MB.',
      );
    }

    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw const AgencyRepresentativeServiceException(
        'Não foi possível ler o arquivo selecionado.',
      );
    }

    return AgencyRepresentativePickedFile(
      fileName: fileName,
      bytes: bytes,
      sizeInBytes: file.size,
      contentType: _contentTypeFromExtension(extension),
    );
  }

  /// Abre o seletor local e retorna um arquivo válido para upload posterior.
  Future<AgencyRepresentativePickedFile?> pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result == null || result.files.isEmpty) return null;

    return buildPickedFile(result.files.single, pdfOnly: false);
  }

  /// Envia os documentos ao Storage e salva o registro do representante.
  Future<void> submit(AgencyRepresentativeSubmission submission) async {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw const AgencyRepresentativeServiceException(
        'Usuário não autenticado.',
      );
    }

    final uploadedPaths = <String>[];
    String? legalRepresentativeId;

    try {
      try {
        final existing = await _supabaseClient
            .from('legal_documents')
            .select('front_url, back_url')
            .eq('agency_id', submission.agencyId)
            .maybeSingle();

        final pathsToDelete = <String>[];
        if (existing?['front_url'] != null) {
          pathsToDelete.add(_extractPath(existing!['front_url'] as String));
        }
        if (existing?['back_url'] != null) {
          pathsToDelete.add(_extractPath(existing!['back_url'] as String));
        }

        if (pathsToDelete.isNotEmpty) {
          await _supabaseClient.storage.from(_bucketName).remove(pathsToDelete);
        }
      } catch (e) {
        debugPrint('Failed to clean previous legal documents: $e');
      }

      final frontFile = submission.frontFileForUpload;
      if (frontFile == null) {
        throw const AgencyRepresentativeServiceException(
          'Documento da frente não informado.',
        );
      }

      final frontPath = await _uploadDocument(
        agencyId: submission.agencyId,
        documentType: submission.documentType,
        file: frontFile,
        slot: AgencyRepresentativeAttachmentSlot.front,
      );
      uploadedPaths.add(frontPath);

      String? backPath;
      final backFile = submission.backFileForUpload;
      if (backFile != null) {
        backPath = await _uploadDocument(
          agencyId: submission.agencyId,
          documentType: submission.documentType,
          file: backFile,
          slot: AgencyRepresentativeAttachmentSlot.back,
        );
        uploadedPaths.add(backPath);
      }

      final bucket = _supabaseClient.storage.from(_bucketName);
      final frontUrl = bucket.getPublicUrl(frontPath);
      final backUrl = backPath == null ? null : bucket.getPublicUrl(backPath);

      final insertedRepresentative = await _supabaseClient
          .from('legal_representatives')
          .insert({
            'agency_id': submission.agencyId,
            'user_id': userId,
            'full_name': submission.name.trim(),
            'email': submission.email.trim(),
            'phone': submission.phone,
            'role': submission.role.trim(),
            'cpf': submission.cpf,
          })
          .select('id')
          .single();

      legalRepresentativeId = insertedRepresentative['id']?.toString();
      if (legalRepresentativeId == null || legalRepresentativeId.isEmpty) {
        throw const AgencyRepresentativeServiceException(
          'Não foi possível identificar o representante legal salvo.',
        );
      }

      await _supabaseClient.from('legal_documents').insert({
        'agency_id': submission.agencyId,
        'legal_representative_id': legalRepresentativeId,
        'document_type': submission.documentType.databaseValue,
        'front_url': frontUrl,
        'back_url': backUrl,
      });
    } on StorageException catch (e) {
      await _rollbackUploads(uploadedPaths);
      throw AgencyRepresentativeServiceException(
        'Falha no upload do documento. ${e.message}',
      );
    } on PostgrestException catch (e) {
      await _rollbackRepresentative(legalRepresentativeId);
      await _rollbackUploads(uploadedPaths);
      throw AgencyRepresentativeServiceException(
        'Não foi possível salvar o representante legal. (${e.code})',
      );
    } on AgencyRepresentativeServiceException {
      await _rollbackRepresentative(legalRepresentativeId);
      await _rollbackUploads(uploadedPaths);
      rethrow;
    } catch (_) {
      await _rollbackRepresentative(legalRepresentativeId);
      await _rollbackUploads(uploadedPaths);
      throw const AgencyRepresentativeServiceException(
        'Não foi possível salvar o representante legal.',
      );
    }
  }

  Future<String> _uploadDocument({
    required String agencyId,
    required AgencyRepresentativeDocumentType documentType,
    required AgencyRepresentativePickedFile file,
    required AgencyRepresentativeAttachmentSlot slot,
  }) async {
    final sanitizedName = _sanitizeFileName(file.fileName);
    final storageFileName = '${slot.filePrefix}_$sanitizedName';
    final path =
        '${agencyId.trim()}/${documentType.storageFolder}/$storageFileName';
    final bucket = _supabaseClient.storage.from(_bucketName);

    await bucket.uploadBinary(
      path,
      file.bytes,
      fileOptions: FileOptions(
        upsert: true,
        contentType: file.contentType,
      ),
    );

    return path;
  }

  Future<void> _rollbackUploads(List<String> uploadedPaths) async {
    if (uploadedPaths.isEmpty) return;

    try {
      await _supabaseClient.storage.from(_bucketName).remove(uploadedPaths);
    } catch (_) {
      // Rollback de storage é best effort; preservamos o erro original.
    }
  }

  Future<void> _rollbackRepresentative(String? legalRepresentativeId) async {
    if (legalRepresentativeId == null || legalRepresentativeId.isEmpty) {
      return;
    }

    try {
      await _supabaseClient
          .from('legal_documents')
          .delete()
          .eq('legal_representative_id', legalRepresentativeId);
      await _supabaseClient
          .from('legal_representatives')
          .delete()
          .eq('id', legalRepresentativeId);
    } catch (_) {
      // Rollback de banco também é best effort; preservamos o erro original.
    }
  }

  String _extractPath(String publicUrl) {
    final marker = '/$_bucketName/';
    final markerIndex = publicUrl.indexOf(marker);
    if (markerIndex == -1) return publicUrl;

    return publicUrl.substring(markerIndex + marker.length);
  }

  bool _isAcceptedExtension(String extension) {
    return extension == 'jpg' ||
        extension == 'jpeg' ||
        extension == 'png' ||
        extension == 'pdf';
  }

  String _extractExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == fileName.length - 1) {
      return '';
    }
    return fileName.substring(dotIndex + 1).toLowerCase();
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

  String _sanitizeFileName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'documento';
    }

    final dotIndex = trimmed.lastIndexOf('.');
    final hasExtension = dotIndex > 0 && dotIndex < trimmed.length - 1;
    final rawName = hasExtension ? trimmed.substring(0, dotIndex) : trimmed;
    final rawExtension = hasExtension ? trimmed.substring(dotIndex + 1) : '';

    final normalizedName = rawName
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^A-Za-z0-9_]'), '')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    final safeName = normalizedName.isEmpty ? 'documento' : normalizedName;
    if (rawExtension.isEmpty) {
      return safeName;
    }

    return '$safeName.$rawExtension';
  }
}

/// Exceção base usada pelo fluxo de representante legal.
class AgencyRepresentativeServiceException implements Exception {
  const AgencyRepresentativeServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
