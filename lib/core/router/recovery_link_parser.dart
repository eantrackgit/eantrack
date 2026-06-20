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
  ///
  /// `error=access_denied` by itself is NOT enough: it's the generic OAuth2
  /// error code (e.g. Google login cancelled/denied) and would otherwise
  /// misfire for Google Auth or stale browser-history entries. It only
  /// counts as an expired recovery link when combined with `type=recovery`.
  static bool hasExpiredParams(Uri uri) {
    final params = paramsFromUri(uri);
    final type = (params['type'] ?? '').toLowerCase();
    final error = (params['error'] ?? '').toLowerCase();
    final errorCode = (params['error_code'] ?? '').toLowerCase();
    final description = Uri.decodeComponent(
      params['error_description'] ?? '',
    ).toLowerCase();

    final isOtpExpired = errorCode == 'otp_expired';
    final mentionsExpiredLink = description.contains(_kExpiredLinkMessage) ||
        description.contains('invalid or has expired') ||
        description.contains('already used') ||
        description.contains('already been used');
    final isRecoveryAccessDenied = type == 'recovery' && error == 'access_denied';

    return isOtpExpired || mentionsExpiredLink || isRecoveryAccessDenied;
  }

  /// Checks the current browser URI on startup. Returns the expired-link
  /// route if applicable, or null to proceed normally.
  static String? initialErrorLocation() {
    if (hasExpiredParams(Uri.base)) {
      markExpiredLinkJustified();
      return AppRoutes.passwordRecoveryLinkExpired;
    }
    return null;
  }

  // GoRouter rewrites the browser URL to a clean path right after redirecting
  // to LinkExpired, so re-checking hasExpiredParams on the next redirect pass
  // would no longer find the params and would bounce the user away. This flag
  // remembers, for the lifetime of the app session, that the expired link was
  // genuinely detected, so the screen stays reachable until the user leaves
  // it. It starts false on every fresh load/reload, so a stale history entry
  // or a manually-typed URL with no active error params will not show it.
  static bool _expiredLinkJustified = false;

  static bool get isExpiredLinkJustified => _expiredLinkJustified;

  static void markExpiredLinkJustified() {
    _expiredLinkJustified = true;
  }

  static void clearExpiredLinkJustification() {
    _expiredLinkJustified = false;
  }
}
