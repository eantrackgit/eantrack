import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/auth_scaffold.dart';

/// Tela de confirmação dos dados da empresa (pré-preenchidos via consulta CNPJ).
///
/// Exibe os dados em modo leitura. O usuário confirma e avança.
/// Integração real com a API de CNPJ será feita em tarefa futura.
class CompanyDataScreen extends StatelessWidget {
  const CompanyDataScreen({super.key});

  // Mock — será substituído por dados reais da consulta CNPJ
  static const _mockData = {
    'Razão Social': 'EMPRESA EXEMPLO COMERCIAL LTDA',
    'Nome Fantasia': 'Exemplo Comercial',
    'CNPJ': '12.345.678/0001-99',
    'Situação': 'Ativa',
    'Endereço': 'Rua das Flores, 100',
    'Bairro': 'Centro',
    'Cidade / UF': 'Belo Horizonte / MG',
    'CEP': '30.100-000',
  };

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Dados da Empresa',
      subtitle: 'Confirme os dados da sua empresa antes de continuar.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ..._mockData.entries.map(
            (e) => _DataRow(label: e.key, value: e.value),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: AppButton.secondary(
                  '← Voltar',
                  onPressed: () => context.go(AppRoutes.onboardingCnpj),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton.primary(
                  'Confirmar →',
                  onPressed: () => context.go(AppRoutes.onboardingLegalRep),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primaryText,
            ),
          ),
          const Divider(height: AppSpacing.md),
        ],
      ),
    );
  }
}
