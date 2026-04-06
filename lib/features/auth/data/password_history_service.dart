import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_exception.dart';
import 'password_reuse_parser.dart';

class PasswordHistoryService {
  const PasswordHistoryService(this._client);

  final SupabaseClient _client;

  Future<void> ensureNewPasswordCanBeUsed(String newPassword) async {
    late final dynamic response;
    try {
      response = await _client.rpc(
        'check_password_reuse_current_user',
        params: {
          'p_new_password': newPassword,
          'p_history_limit': 3,
        },
      );
    } on PostgrestException {
      throw const PasswordReuseCheckException();
    } catch (_) {
      throw const PasswordReuseCheckException();
    }

    final result = PasswordReuseCheckResult.fromRpcResponse(response);
    if (result == null) throw const PasswordReuseCheckException();
    if (!result.allowed) throw const PasswordReusedException();
  }

  Future<void> registerPasswordHistory(String newPassword) async {
    try {
      await _client.rpc(
        'register_password_history_current_user',
        params: {
          'p_password': newPassword,
          'p_keep_last': 3,
        },
      );
    } on PostgrestException {
      throw const PasswordHistoryRegisterException();
    } catch (_) {
      throw const PasswordHistoryRegisterException();
    }
  }
}
