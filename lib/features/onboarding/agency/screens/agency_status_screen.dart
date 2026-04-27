import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../hub/presentation/widgets/menu_hub_sidebar.dart';
import '../../../../shared/shared.dart';
import '../controllers/agency_status_notifier.dart';

part 'agency_status_actions.dart';
part 'agency_status_cards.dart';
part 'agency_status_formatters.dart';
part 'agency_status_helpers.dart';
part 'agency_status_layouts.dart';
part 'agency_status_terms_dialog.dart';

class AgencyStatusScreen extends ConsumerWidget {
  const AgencyStatusScreen({super.key, this.debugStatus});

  final AgencyDocumentStatus? debugStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final et = EanTrackTheme.of(context);
    final isDesktop = Breakpoints.isDesktop(context);
    final provider = agencyStatusProvider(debugStatus);
    final state = ref.watch(provider);
    final authState = ref.watch(authNotifierProvider);
    final isLoading = state.status == AgencyStatusLoading.loading;
    final data = state.data;
    final userName = _resolveUserName(authState);
    final userRole = _resolveUserRole(authState);

    if (state.status == AgencyStatusLoading.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ref.read(provider.notifier).load();
      });
    }

    final content = SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: data == null
              ? _InitialState(state: state, debugStatus: debugStatus)
              : _StatusContent(
                  data: data,
                  debugStatus: debugStatus,
                  isLoading: isLoading,
                ),
        ),
      ),
    );

    if (isDesktop) {
      return Scaffold(
        backgroundColor: et.sidebarSurface,
        body: Row(
          children: [
            MenuHubSidebar(
              userName: userName,
              userRole: userRole,
              agencyName: data?.agencyLegalName ?? '',
              agencyHandle: '',
              agencyStatus: data?.consolidatedDocumentStatus ??
                  AgencyDocumentStatus.pending,
              onSignOut: () => _confirmSignOutFromStatus(context, ref),
            ),
            Expanded(
              child: data == null
                  ? content
                  : _DesktopLayout(
                      data: data,
                      debugStatus: debugStatus,
                      isLoading: isLoading,
                    ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: et.scaffoldOuter,
      appBar: AppBar(
        backgroundColor: et.scaffoldOuter,
        foregroundColor: et.primaryText,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.secondaryBackground,
          ),
          onPressed: () => _confirmSignOutFromStatus(context, ref),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: isLoading
                ? const _AppBarLoadingIndicator()
                : IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () => ref.read(provider.notifier).refresh(),
                  ),
          ),
        ],
      ),
      body: content,
    );
  }
}

Future<void> _confirmSignOutFromStatus(BuildContext context, WidgetRef ref) async {
  final et = EanTrackTheme.of(context);
  final shouldSignOut = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: et.cardSurface,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
            title: Text(
              'Deseja sair da conta?',
              style: AppTextStyles.titleMedium.copyWith(
                color: et.primaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              'Sua solicitação continuará salva. Para acompanhar o status novamente, você precisará entrar na conta.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: et.secondaryText,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Sair'),
              ),
            ],
          );
        },
      ) ??
      false;

  if (!shouldSignOut || !context.mounted) return;
  await ref.read(authNotifierProvider.notifier).signOut();
  if (!context.mounted) return;
  context.go(AppRoutes.login);
}

String _resolveUserName(AuthState authState) {
  if (authState is! AuthAuthenticated) return '';

  final flowName = authState.flowState?.nome?.trim();
  if (flowName != null && flowName.isNotEmpty) return flowName;

  final metadataName = _firstMetadataValue(authState.user.userMetadata, const [
    'nome',
    'name',
    'full_name',
    'display_name',
  ]);
  if (metadataName != null) return metadataName;

  final email = authState.user.email?.trim();
  if (email == null || email.isEmpty) return '';

  final separatorIndex = email.indexOf('@');
  if (separatorIndex <= 0) return email;
  return email.substring(0, separatorIndex);
}

String _resolveUserRole(AuthState authState) {
  if (authState is! AuthAuthenticated) return '';

  return _firstMetadataValue(authState.user.userMetadata, const [
        'role',
        'user_role',
        'cargo',
      ]) ??
      '';
}

String? _firstMetadataValue(
  Map<String, dynamic>? metadata,
  List<String> keys,
) {
  if (metadata == null) return null;

  for (final key in keys) {
    final value = metadata[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }

  return null;
}
