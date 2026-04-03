/// Ponto de importação único para a camada shared do EANTrack.
///
/// Uso em qualquer tela:
///   import '../../../shared/shared.dart';   // ajustar nível relativo
///
/// Inclui: tema, widgets base, mixins de formulário, async action, breakpoints.

// --- Tema ---
export 'theme/app_colors.dart';
export 'theme/app_spacing.dart';
export 'theme/app_text_styles.dart';
export 'theme/app_theme.dart';

// --- Widgets base ---
export 'widgets/app_button.dart';
export 'widgets/app_card.dart';
export 'widgets/app_empty_state.dart';
export 'widgets/app_loading_overlay.dart';
export 'widgets/app_text_field.dart';
export 'widgets/auth_scaffold.dart'; // AuthScaffold + AppErrorBox + PasswordRuleRow

// --- Widgets de layout ---
export 'widgets/app_bottom_nav.dart';
export 'widgets/app_sidebar.dart';

// --- Layout ---
export 'layout/breakpoints.dart';

// --- Mixins ---
export 'mixins/form_state_mixin.dart'; // FormStateMixin

// --- Utils ---
export 'utils/async_action.dart';      // AsyncAction<T> + ActionIdle/Loading/Success/Failure
export 'utils/async_value.dart';       // AsyncValue<T> + DataIdle/Loading/Success/Empty/Failure
export 'utils/password_validator.dart'; // PasswordValidator (hasUppercase, hasSymbol, isValid...)
