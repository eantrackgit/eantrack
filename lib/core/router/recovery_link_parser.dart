import 'app_routes.dart';

// Supabase error message — atualizar se backend mudar
const _kExpiredLinkMessage = 'email link is invalid or has expired';

/// Parses Supabase password-recovery deep-link parameters and detects
/// expired/invalid links.
class RecoveryLinkParser {
  RecoveryLinkParser._();

  /// Extracts all relevant query params from the URI, handling both plain
  /// query strings and fragment-encoded params (Supabase web callback format).
  static Map<String, String> paramsFromUri(Uri uri) {
    final params = <String, String>{...uri.queryParameters};
    final fragment = uri.fragment;

    if (fragment.isEmpty) return params;

    if (fragment.startsWith('error=')) {
      params.addAll(Uri.splitQueryString(fragment));
      return params;
    }

    final queryIndex = fragment.indexOf('?');
    if (queryIndex >= 0 && queryIndex < fragment.length - 1) {
      final fragmentQuery = fragment.substring(queryIndex + 1);
      params.addAll(Uri.splitQueryString(fragmentQuery));
    }

    return params;
  }

  /// Returns true if the URI carries params that indicate an expired or
  /// already-used password-recovery link.
  static bool hasExpiredParams(Uri uri) {
    final params = paramsFromUri(uri);
    final error = (params['error'] ?? '').toLowerCase();
    final errorCode = (params['error_code'] ?? '').toLowerCase();
    final description = Uri.decodeComponent(
      params['error_description'] ?? '',
    ).toLowerCase();

    return error == 'access_denied' ||
        errorCode == 'otp_expired' ||
        description.contains(_kExpiredLinkMessage) ||
        description.contains('invalid or has expired') ||
        description.contains('already used') ||
        description.contains('already been used');
  }

  /// Checks the current browser URI on startup. Returns the expired-link
  /// route if applicable, or null to proceed normally.
  static String? initialErrorLocation() {
    if (hasExpiredParams(Uri.base)) {
      return AppRoutes.passwordRecoveryLinkExpired;
    }
    return null;
  }
}
