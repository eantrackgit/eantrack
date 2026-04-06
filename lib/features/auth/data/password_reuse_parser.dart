class PasswordReuseCheckResult {
  const PasswordReuseCheckResult({required this.allowed});

  final bool allowed;

  static PasswordReuseCheckResult? fromRpcResponse(dynamic response) {
    if (response == null) return null;
    if (response is bool) {
      return PasswordReuseCheckResult(allowed: response);
    }
    if (response is num) {
      return PasswordReuseCheckResult(allowed: response != 0);
    }
    if (response is Map) {
      return _fromMap(Map<String, dynamic>.from(response));
    }
    if (response is List && response.isNotEmpty && response.first is Map) {
      return _fromMap(Map<String, dynamic>.from(response.first as Map));
    }
    return null;
  }

  static PasswordReuseCheckResult? _fromMap(Map<String, dynamic> map) {
    final allowed = _parseAllowed(map['allowed']);
    return allowed == null ? null : PasswordReuseCheckResult(allowed: allowed);
  }

  static bool? _parseAllowed(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }
    return null;
  }
}
