bool hasAuthCallbackParams(Uri uri) {
  final query = uri.queryParameters;
  const callbackKeys = <String>{
    'access_token',
    'code',
    'error',
    'error_code',
    'refresh_token',
    'token_hash',
  };

  if (callbackKeys.any(query.containsKey)) return true;

  final type = query['type']?.trim();
  if (type != null && type.isNotEmpty) return true;

  final fragment = uri.fragment.toLowerCase();
  return fragment.contains('access_token=') ||
      fragment.contains('code=') ||
      fragment.contains('error=') ||
      fragment.contains('refresh_token=') ||
      fragment.contains('type=');
}
