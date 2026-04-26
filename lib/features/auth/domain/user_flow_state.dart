/// Tracks the user's onboarding progression.
/// Maps to the `user_flow_state` table in Supabase.
class UserFlowState {
  const UserFlowState({
    required this.userId,
    required this.hasProfile,
    this.userMode,
    this.nome,
    this.agencyId,
    this.agencyStatus,
    this.hasLegalRepresentative,
    this.subscriptionStatus,
  });

  final String userId;
  final bool hasProfile;
  final String? userMode; // 'individual' | 'agencia' | null (not yet chosen)
  final String? nome;
  final String? agencyId;
  final String? agencyStatus;
  final bool? hasLegalRepresentative;
  final String? subscriptionStatus;

  factory UserFlowState.fromJson(Map<String, dynamic> json) {
    return UserFlowState(
      userId: json['user_id'] as String? ?? '',
      hasProfile: json['has_profile'] as bool? ?? false,
      userMode: json['user_mode'] as String?,
      nome: json['nome'] as String?,
      agencyId: json['agency_id'] as String?,
      agencyStatus: json['agency_status'] as String?,
      hasLegalRepresentative: json['has_legal_representative'] as bool?,
      subscriptionStatus: json['subscription_status'] as String?,
    );
  }

  String? get normalizedUserMode {
    final normalized = userMode?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return null;
    if (normalized == 'agencia') return 'agency';
    return normalized;
  }

  /// True when the user has completed the full onboarding flow.
  bool get isOnboardingComplete {
    final mode = normalizedUserMode;
    if (mode == null) return false;
    if (mode == 'agency') {
      final normalizedAgencyStatus = agencyStatus?.trim().toLowerCase();
      return agencyId != null &&
          (normalizedAgencyStatus == 'aprovada' ||
              normalizedAgencyStatus == 'approved');
    }
    return hasProfile;
  }
}
