# Design System

This document records the shared EANTrack UI tokens and component rules.

## Color Tokens

All product colors live in `lib/shared/theme/app_colors.dart`.

`AppColors` tokens:

- Brand: `primary`, `secondary`, `tertiary`, `alternate`, `brandRed`
- Text: `primaryText`, `secondaryText`
- Backgrounds: `scaffoldBackground`, `cardBackground`, `primaryBackground`,
  `secondaryBackground`, `modalOverlayBase`, `modalOverlayMid`,
  `modalOverlayGlow`
- Action: `actionBlue`
- Informational balloons: `balloonBorder`, `balloonBackground`,
  `balloonIconAction`, `balloonIconInfo`, `balloonTitle`
- Accents: `accent1`, `accent2`, `accent3`, `accent4`
- Semantic: `success`, `warning`, `error`, `info`

Rule: do not use `Color(0xFF...)` outside `app_colors.dart`. Add a named token
first, then consume it through `AppColors` or `EanTrackTheme`.

## Spacing And Radius Tokens

Spacing and radius live in `lib/shared/theme/app_spacing.dart`.

`AppSpacing` tokens:

- `xs` = 4
- `sm` = 8
- `md` = 16
- `lg` = 24
- `xl` = 32

`AppRadius` tokens:

- `sm` = 8
- `md` = 16
- `lg` = 24
- `full` = 9999
- `smAll`
- `mdAll`
- `lgAll`

`AppShadows` tokens:

- `sm`
- `md`
- `lg`
- `xl`

## Typography Tokens

Typography lives in `lib/shared/theme/app_text_styles.dart`.

`AppTextStyles` tokens:

- Display: `displayLarge`, `displayMedium`, `displaySmall`
- Headline: `headlineLarge`, `headlineMedium`, `headlineSmall`
- Title: `titleLarge`, `titleMedium`, `titleSmall`
- Label: `labelLarge`, `labelMedium`, `labelSmall`
- Body: `bodyLarge`, `bodyMedium`, `bodySmall`

Rule: do not create inline `TextStyle(...)` in screens or widgets. Start from an
`AppTextStyles` token and use `copyWith` for local color, weight, or small
contextual adjustments.

## Components

Use shared components before creating local UI.

- `AppButton`: standard button with `primary`, `secondary`, `outlined`,
  `action`, and `social` constructors.
- `AppCard`: base card with optional selection, tap handling, padding, color,
  and border.
- `SectionCard`: onboarding section container with title and subtle border.
- `AppErrorBox`: animated error feedback box.
- `_BalloonCard`: local status-screen support card used for guidance and help
  callouts. If the pattern is needed outside that screen, promote it to
  `lib/shared/widgets` before reusing.

## Adding A New Token

1. Check whether an existing token already expresses the intended role.
2. Add the token to the correct shared file:
   `app_colors.dart`, `app_spacing.dart`, or `app_text_styles.dart`.
3. Name the token by semantic role, not by one-off location.
4. Update this document in the same change.
5. Replace local literals with the new token.

New tokens should make repeated UI decisions easier. Do not add a token for a
single accidental value unless it represents a durable design rule.
