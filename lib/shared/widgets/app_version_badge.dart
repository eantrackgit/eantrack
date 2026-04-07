import 'package:flutter/material.dart';

import '../../core/config/app_version.dart';

/// Exibição discreta da versão do app.
///
/// Texto simples, fonte 11, cinza — sem destaque visual.
/// Usado como rodapé fixo em telas de auth e no fundo da sidebar/hub.
class AppVersionBadge extends StatelessWidget {
  const AppVersionBadge({
    super.key,
    this.alignment = Alignment.center,
  });

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Text(
        AppVersion.label,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF8E8D8D),
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
