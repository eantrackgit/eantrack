import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _agencyStatusUnset = Object();
const String _kLoadErrorMsg = 'Não foi possível carregar o status da agência.';

enum AgencyDocumentStatus { pending, approved, rejected }

class AgencyStatusData {
  const AgencyStatusData({
    required this.agencyLegalName,
    required this.statusAgency,
    required this.agencyUpdatedAt,
    required this.representativeName,
    required this.representativeEmail,
    this.representativePhone,
    this.representativeCpf,
    this.documentFrontUrl,
    this.documentBackUrl,
    required this.documentType,
    required this.consolidatedDocumentStatus,
    this.rejectionReason,
  });

  final String agencyLegalName;
  final AgencyDocumentStatus statusAgency;
  final DateTime agencyUpdatedAt;
  final String representativeName;
  final String representativeEmail;
  final String? representativePhone;
  final String? representativeCpf;
  final String? documentFrontUrl;
  final String? documentBackUrl;
  final String documentType;
  final AgencyDocumentStatus consolidatedDocumentStatus;
  final String? rejectionReason;

  AgencyStatusData copyWith({
    String? agencyLegalName,
    DateTime? agencyUpdatedAt,
    AgencyDocumentStatus? statusAgency,
    String? documentType,
    String? representativeName,
    String? representativeEmail,
    String? representativePhone,
    String? representativeCpf,
    String? documentFrontUrl,
    String? documentBackUrl,
    AgencyDocumentStatus? consolidatedDocumentStatus,
    String? rejectionReason,
  }) {
    return AgencyStatusData(
      agencyLegalName: agencyLegalName ?? this.agencyLegalName,
      agencyUpdatedAt: agencyUpdatedAt ?? this.agencyUpdatedAt,
      statusAgency: statusAgency ?? this.statusAgency,
      documentType: documentType ?? this.documentType,
      representativeName: representativeName ?? this.representativeName,
      representativeEmail: representativeEmail ?? this.representativeEmail,
      representativePhone: representativePhone ?? this.representativePhone,
      representativeCpf: representativeCpf ?? this.representativeCpf,
      documentFrontUrl: documentFrontUrl ?? this.documentFrontUrl,
      documentBackUrl: documentBackUrl ?? this.documentBackUrl,
      consolidatedDocumentStatus:
          consolidatedDocumentStatus ?? this.consolidatedDocumentStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  factory AgencyStatusData.fromJson(Map<String, dynamic> json) {
    return AgencyStatusData(
      representativePhone: json['representative_phone'] as String?,
      representativeCpf: json['representative_cpf'] as String?,
      documentFrontUrl: json['document_front_url'] as String?,
      documentBackUrl: json['document_back_url'] as String?,
      agencyLegalName: _readString(json, 'agency_legal_name'),
      statusAgency: _readStatus(json, 'status_agency'),
      agencyUpdatedAt: _readDate(json, 'agency_updated_at'),
      representativeName: _readString(json, 'representative_name'),
      representativeEmail: _readString(json, 'representative_email'),
      documentType: _readString(json, 'document_type'),
      consolidatedDocumentStatus:
          _readStatus(json, 'consolidated_document_status'),
      rejectionReason: _readNullableString(json, 'rejection_reason'),
    );
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

  static DateTime _readDate(Map<String, dynamic> json, String key) {
    final value = json[key] ?? json[_toCamelCase(key)];
    if (value is DateTime) return value.toLocal();
    if (value == null) return DateTime.now();

    return DateTime.tryParse(value.toString())?.toLocal() ?? DateTime.now();
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
  });

  final AgencyStatusLoading status;
  final AgencyStatusData? data;
  final String? error;

  AgencyStatusState copyWith({
    AgencyStatusLoading? status,
    Object? data = _agencyStatusUnset,
    Object? error = _agencyStatusUnset,
  }) {
    return AgencyStatusState(
      status: status ?? this.status,
      data: identical(data, _agencyStatusUnset)
          ? this.data
          : data as AgencyStatusData?,
      error: identical(error, _agencyStatusUnset) ? this.error : error as String?,
    );
  }
}

class AgencyStatusNotifier extends StateNotifier<AgencyStatusState> {
  AgencyStatusNotifier(
    this._supabase, {
    AgencyDocumentStatus? mockStatus,
  })  : _mockStatus = mockStatus ?? AgencyDocumentStatus.pending,
        super(const AgencyStatusState());

  final SupabaseClient _supabase;
  final AgencyDocumentStatus _mockStatus;

  Future<void> load() async {
    state = state.copyWith(
      status: AgencyStatusLoading.loading,
      error: null,
    );

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        state = state.copyWith(
          status: AgencyStatusLoading.success,
            data: AgencyStatusData(
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
      final data = AgencyStatusData.fromJson(response);

      state = state.copyWith(
        status: AgencyStatusLoading.success,
        data: data,
        error: null,
      );
    } on Exception catch (e) {
      debugPrint('[AgencyStatus] Erro ao carregar status: $e');
      state = state.copyWith(
        status: AgencyStatusLoading.error,
        error: _kLoadErrorMsg,
      );
    }
  }

  Future<void> refresh() => load();
}

final agencyStatusProvider =
    StateNotifierProvider.autoDispose
        .family<AgencyStatusNotifier, AgencyStatusState, AgencyDocumentStatus?>(
  (ref, mockStatus) => AgencyStatusNotifier(
    Supabase.instance.client,
    mockStatus: mockStatus,
  ),
);
