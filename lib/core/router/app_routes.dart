/// Central route name and path definitions.
///
/// Usage:
///   context.go(AppRoutes.login)
///   context.push(AppRoutes.register)
abstract final class AppRoutes {
  // --- Splash ---
  static const splash = '/';

  // --- Auth (public) ---
  static const login = '/login';
  static const register = '/register';
  static const emailVerification = '/email-verification';
  static const recoverPassword = '/recover-password';
  static const updatePassword = '/update-password';
  static const passwordRecoveryLinkExpired =
      '/password-recovery-link-expired';

  // --- Onboarding (post-registration) ---
  static const onboarding = '/onboarding';
  static const onboardingIndividual = '/onboarding/individual';
  static const photoProfile = '/onboarding/photo-profile';
  static const onboardingCnpj = '/onboarding/cnpj';
  static const onboardingAgency = '/onboarding/agency';
  static const onboardingLegalRep = '/onboarding/legal-rep';
  static const onboardingOperationalStyle = '/onboarding/operational-style';
  static const onboardingStatus = '/onboarding/status';

  // --- App (protected) ---
  static const flow = '/flow';
  static const home = '/home';
  static const search = '/search';
  static const hub = '/hub';

  // --- Hub modules ---
  static const regions = '/hub/regions';
  static const cities = '/hub/regions/cities';
  static const pdvs = '/hub/pdvs';
  static const registerPdv = '/hub/pdvs/register';
  static const networks = '/hub/networks';
  static const categories = '/hub/categories';
  static const subcategories = '/hub/categories/subcategories';
  static const industries = '/hub/industries';
  static const registerIndustry = '/hub/industries/register';
  static const productMix = '/hub/industries/mix';

  /// Routes that require [AuthFlowState.authenticated].
  /// Add new protected routes here — the redirect guard reads this set.
  static const Set<String> protectedRoutes = {
    hub,
    regions,
    cities,
    pdvs,
    registerPdv,
    networks,
    categories,
    subcategories,
    industries,
    registerIndustry,
    productMix,
  };

  // --- Legal ---
  static const termsOfUse = '/terms-of-use';
  static const privacyPolicy = '/privacy-policy';

  // --- Utilities ---
  static const noConnection = '/no-connection';
}
