import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';

/// Ponte entre o estado de auth do Riverpod e o refresh do GoRouter.
///
/// Usado **apenas** como `refreshListenable` do GoRouter: quando
/// [authFlowStateProvider] muda — ou quando [refresh] é chamado em reação a
/// mudanças do `agencyStatusProvider` — notifica o GoRouter para reexecutar
/// seu `redirect`.
///
/// A regra de redirecionamento tem **fonte única**: a função `_redirect` em
/// `app_router.dart`. Este guard não decide rota; só dispara a reavaliação.
class RouterRedirectGuard extends ChangeNotifier {
  RouterRedirectGuard(Ref ref) {
    ref.listen(authFlowStateProvider, (_, __) => notifyListeners());
  }

  /// Alias semântico de [notifyListeners], usado pelo `appRouterProvider` ao
  /// reagir a mudanças do `agencyStatusProvider`.
  void refresh() => notifyListeners();
}
