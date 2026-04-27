import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/agency_status_repository.dart';

const _agencyStatusUnset = Object();
const String _kLoadErrorMsg = 'Não foi possível carregar o status da agência.';
const String _kAcceptTermsErrorMsg =
    'Não foi possível registrar o aceite dos termos.';

enum AgencyDocumentStatus { pending, approved, rejected }

class AgencyStatusData {
  const AgencyStatusData({
    required this.agencyId,
    required this.agencyLegalName,
    required this.statusAgency,
    required this.agencyUpdatedAt,
    required this.representativeName,
    required this.representativeEmail,
    this.legalRepresentativeId,
    this.representativePhone,
    this.representativeCpf,
    this.representativeRole,
    this.documentFrontUrl,
    this.documentBackUrl,
    required this.documentType,
    required this.consolidatedDocumentStatus,
    this.rejectionReason,
    this.termsAccepted = false,
    this.termsAcceptedAt,
    this.termsVersion,
  });

  final String agencyId;
  final String agencyLegalName;
  final AgencyDocumentStatus statusAgency;
  final DateTime agencyUpdatedAt;
  final String representativeName;
  final String representativeEmail;
  final String? legalRepresentativeId;
  final String? representativePhone;
  final String? representativeCpf;
  final String? representativeRole;
  final String? documentFrontUrl;
  final String? documentBackUrl;
  final String documentType;
  final AgencyDocumentStatus consolidatedDocumentStatus;
  final String? rejectionReason;
  final bool termsAccepted;
  final DateTime? termsAcceptedAt;
  final String? termsVersion;

  AgencyStatusData copyWith({
    String? agencyId,
    String? agencyLegalName,
    DateTime? agencyUpdatedAt,
    AgencyDocumentStatus? statusAgency,
    String? documentType,
    String? representativeName,
    String? representativeEmail,
    String? legalRepresentativeId,
    String? representativePhone,
    String? representativeCpf,
    String? representativeRole,
    String? documentFrontUrl,
    String? documentBackUrl,
    AgencyDocumentStatus? consolidatedDocumentStatus,
    String? rejectionReason,
    bool? termsAccepted,
    DateTime? termsAcceptedAt,
    String? termsVersion,
  }) {
    return AgencyStatusData(
      agencyId: agencyId ?? this.agencyId,
      agencyLegalName: agencyLegalName ?? this.agencyLegalName,
      agencyUpdatedAt: agencyUpdatedAt ?? this.agencyUpdatedAt,
      statusAgency: statusAgency ?? this.statusAgency,
      documentType: documentType ?? this.documentType,
      representativeName: representativeName ?? this.representativeName,
      representativeEmail: representativeEmail ?? this.representativeEmail,
      legalRepresentativeId: legalRepresentativeId ?? this.legalRepresentativeId,
      representativePhone: representativePhone ?? this.representativePhone,
      representativeCpf: representativeCpf ?? this.representativeCpf,
      representativeRole: representativeRole ?? this.representativeRole,
      documentFrontUrl: documentFrontUrl ?? this.documentFrontUrl,
      documentBackUrl: documentBackUrl ?? this.documentBackUrl,
      consolidatedDocumentStatus:
          consolidatedDocumentStatus ?? this.consolidatedDocumentStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      termsAcceptedAt: termsAcceptedAt ?? this.termsAcceptedAt,
      termsVersion: termsVersion ?? this.termsVersion,
    );
  }

  factory AgencyStatusData.fromJson(Map<String, dynamic> json) {
    final agencyStatus = _readStatusFromAny(json, const [
      'status_agency',
      'agency_status',
    ]);
    final latestStatus = _readStatusFromAny(json, const [
      'consolidated_document_status',
      'document_status',
      'status_document',
      'status',
    ]);

    return AgencyStatusData(
      agencyId: _readString(json, 'agency_id'),
      legalRepresentativeId: _readNullableStringFromAny(json, const [
        'legal_representative_id',
        'representative_id',
      ]),
      representativePhone: json['representative_phone'] as String?,
      representativeCpf: json['representative_cpf'] as String?,
      representativeRole: _readNullableString(json, 'representative_role'),
      documentFrontUrl: json['document_front_url'] as String?,
      documentBackUrl: json['document_back_url'] as String?,
      agencyLegalName: _readString(json, 'agency_legal_name'),
      statusAgency: agencyStatus,
      agencyUpdatedAt: _readDateFromAny(json, const [
        'agency_updated_at',
        'document_updated_at',
        'latest_document_updated_at',
        'updated_at',
      ]),
      representativeName: _readString(json, 'representative_name'),
      representativeEmail: _readString(json, 'representative_email'),
      documentType: _readString(json, 'document_type'),
      consolidatedDocumentStatus: latestStatus,
      rejectionReason: latestStatus == AgencyDocumentStatus.rejected
          ? _readNullableString(json, 'rejection_reason')
          : null,
      termsAccepted: _readBool(json, 'terms_accepted'),
      termsAcceptedAt: _readNullableDate(json, 'terms_accepted_at'),
      termsVersion: _readNullableString(json, 'terms_version'),
    );
  }

  static bool _readBool(Map<String, dynamic> json, String key) {
    final value = json[key] ?? json[_toCamelCase(key)];
    if (value is bool) return value;
    if (value == null) return false;

    return value.toString().trim().toLowerCase() == 'true';
  }

  static String _readString(
    Map<String, dynamic> json,
    String key, {
    String fallback = '',
  }) {
    final value = json[key] ?? json[_toCamelCase(key)];
    if (value == null) return fallback;
    return value.toString();
  }

  static String? _readNullableString(Map<String, dynamic> json, String key) {
    final value = json[key] ?? json[_toCamelCase(key)];
    if (value == null) return null;

    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static String? _readNullableStringFromAny(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = _readNullableString(json, key);
      if (value != null) return value;
    }

    return null;
  }

  static AgencyDocumentStatus _readStatus(Map<String, dynamic> json, String key) {
    final status = _readString(json, key, fallback: 'pending')
        .trim()
        .toLowerCase();

    switch (status) {
      case 'approved':
        return AgencyDocumentStatus.approved;
      case 'rejected':
        return AgencyDocumentStatus.rejected;
      case 'pending':
      default:
        return AgencyDocumentStatus.pending;
    }
  }

  static AgencyDocumentStatus _readStatusFromAny(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key] ?? json[_toCamelCase(key)];
      if (value == null) continue;

      return _readStatus(<String, dynamic>{key: value}, key);
    }

    return AgencyDocumentStatus.pending;
  }

  static DateTime _readDate(Map<String, dynamic> json, String key) {
    final value = json[key] ?? json[_toCamelCase(key)];
    if (value is DateTime) return value.toLocal();
    if (value == null) return DateTime.now();

    return DateTime.tryParse(value.toString())?.toLocal() ?? DateTime.now();
  }

  static DateTime? _readNullableDate(Map<String, dynamic> json, String key) {
    final value = json[key] ?? json[_toCamelCase(key)];
    if (value is DateTime) return value.toLocal();
    if (value == null) return null;

    return DateTime.tryParse(value.toString())?.toLocal();
  }

  static DateTime _readDateFromAny(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key] ?? json[_toCamelCase(key)];
      if (value == null) continue;

      return _readDate(<String, dynamic>{key: value}, key);
    }

    return DateTime.now();
  }

  static String _toCamelCase(String value) {
    final parts = value.split('_');
    if (parts.isEmpty) return value;

    return parts.first +
        parts.skip(1).map((part) {
          if (part.isEmpty) return part;
          return part[0].toUpperCase() + part.substring(1);
        }).join();
  }
}

enum AgencyStatusLoading { idle, loading, success, error }

class AgencyStatusState {
  const AgencyStatusState({
    this.status = AgencyStatusLoading.idle,
    this.data,
    this.error,
    this.isAcceptingTerms = false,
  });

  final AgencyStatusLoading status;
  final AgencyStatusData? data;
  final String? error;
  final bool isAcceptingTerms;

  AgencyStatusState copyWith({
    AgencyStatusLoading? status,
    Object? data = _agencyStatusUnset,
    Object? error = _agencyStatusUnset,
    bool? isAcceptingTerms,
  }) {
    return AgencyStatusState(
      status: status ?? this.status,
      data: identical(data, _agencyStatusUnset)
          ? this.data
          : data as AgencyStatusData?,
      error: identical(error, _agencyStatusUnset) ? this.error : error as String?,
      isAcceptingTerms: isAcceptingTerms ?? this.isAcceptingTerms,
    );
  }
}

class AgencyStatusNotifier extends StateNotifier<AgencyStatusState> {
  AgencyStatusNotifier(
    SupabaseClient supabase, {
    AgencyStatusRepository? repository,
    AgencyDocumentStatus? mockStatus,
  })  : _supabase = supabase,
        _repository = repository ??
            AgencyStatusRepository(supabaseClient: supabase),
        _mockStatus = mockStatus ?? AgencyDocumentStatus.pending,
        super(const AgencyStatusState());

  final SupabaseClient _supabase;
  final AgencyStatusRepository _repository;
  final AgencyDocumentStatus _mockStatus;
  int _loadRequestId = 0;

  Future<void> load() async {
    final requestId = ++_loadRequestId;
    state = state.copyWith(
      status: AgencyStatusLoading.loading,
      error: null,
      isAcceptingTerms: false,
    );

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        if (requestId != _loadRequestId) return;
        state = state.copyWith(
          status: AgencyStatusLoading.success,
          data: AgencyStatusData(
            agencyId: '',
            representativePhone: null,
            representativeCpf: null,
            documentFrontUrl: null,
            documentBackUrl: null,
            agencyLegalName: 'Agência não vinculada',
            statusAgency: _mockStatus,
            agencyUpdatedAt: DateTime.now(),
            representativeName: 'Representante não informado',
            representativeEmail: 'Não informado',
            documentType: 'Documento com foto',
            consolidatedDocumentStatus: _mockStatus,
            termsAccepted: false,
          ),
          error: null,
        );
        return;
      }

      final response = await _supabase
          .from('v_user_agency_onboarding_context')
          .select()
          .eq('user_id', userId)
          .single();
      final agencyId = AgencyStatusData._readString(response, 'agency_id');
      if (agencyId.isEmpty) {
        throw StateError('AgencyStatusData sem agency_id.');
      }

      final latestDocumentStatus = await _supabase
          .from('v_agency_latest_document_status')
          .select()
          .eq('agency_id', agencyId)
          .maybeSingle();
      final data = AgencyStatusData.fromJson({
        ...response,
        ...(latestDocumentStatus ??
            const <String, dynamic>{
              'consolidated_document_status': 'pending',
              'rejection_reason': null,
            }),
      });

      if (requestId != _loadRequestId) return;
      state = state.copyWith(
        status: AgencyStatusLoading.success,
        data: data,
        error: null,
      );
    } on Exception catch (e) {
      debugPrint('[AgencyStatus] Erro ao carregar status: $e');
      if (requestId != _loadRequestId) return;
      state = state.copyWith(
        status: AgencyStatusLoading.error,
        error: _kLoadErrorMsg,
      );
    }
  }

  Future<void> refresh() async {
    await load();
  }

  Future<bool> acceptTermsAndContinue({
    String termsVersion = AgencyStatusRepository.currentTermsVersion,
  }) async {
    final currentData = state.data;
    if (currentData == null || currentData.agencyId.isEmpty) {
      state = state.copyWith(error: _kAcceptTermsErrorMsg);
      return false;
    }

    if (currentData.termsAccepted) return true;

    state = state.copyWith(isAcceptingTerms: true, error: null);

    try {
      final acceptance = await _repository.acceptAgencyTerms(
        currentData.agencyId,
        termsVersion,
      );
      if (!acceptance.accepted) {
        throw StateError('Aceite de termos não confirmado.');
      }

      state = state.copyWith(
        status: AgencyStatusLoading.success,
        data: currentData.copyWith(
          termsAccepted: acceptance.accepted,
          termsAcceptedAt: acceptance.acceptedAt ?? DateTime.now(),
          termsVersion: acceptance.version ?? termsVersion,
        ),
        error: null,
        isAcceptingTerms: false,
      );
      return true;
    } on Exception catch (e) {
      debugPrint('[AgencyStatus] Erro ao aceitar termos: $e');
      state = state.copyWith(
        error: _kAcceptTermsErrorMsg,
        isAcceptingTerms: false,
      );
      return false;
    }
  }
}

final agencyStatusProvider =
    StateNotifierProvider.autoDispose
        .family<AgencyStatusNotifier, AgencyStatusState, AgencyDocumentStatus?>(
  (ref, mockStatus) {
    return AgencyStatusNotifier(
      Supabase.instance.client,
      repository: ref.watch(agencyStatusRepositoryProvider),
      mockStatus: mockStatus,
    );
  },
);
