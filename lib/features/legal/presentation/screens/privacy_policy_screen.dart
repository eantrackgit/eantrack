import 'package:flutter/material.dart';

import '../../../../shared/shared.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);

    return Scaffold(
      backgroundColor: et.scaffoldOuter,
      appBar: AppBar(
        backgroundColor: et.scaffoldOuter,
        foregroundColor: et.primaryText,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Política de Privacidade',
          style: AppTextStyles.titleMedium.copyWith(color: et.primaryText),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Política de Privacidade — EANTrack 2025',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: et.primaryText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ..._sections(et),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _sections(EanTrackTheme et) {
    return [
      _Section(
        et: et,
        number: '1.',
        title: 'Introdução',
        body:
            'A EANTrack valoriza sua privacidade e está comprometida em proteger os seus dados pessoais. '
            'Esta Política de Privacidade esclarece como coletamos, usamos, armazenamos e protegemos suas '
            'informações, em conformidade com a Lei Geral de Proteção de Dados (Lei nº 13.709/2018 – LGPD) '
            'e demais legislações aplicáveis.',
      ),
      _Section(
        et: et,
        number: '2.',
        title: 'Definições',
        body: '',
        bullets: const [
          'Dados Pessoais: qualquer informação relacionada a pessoa natural identificada ou identificável, incluindo dados sensíveis.',
          'Usuário: pessoa física ou jurídica que utiliza os serviços da EANTrack.',
          'Tratamento de Dados: toda operação realizada com dados pessoais, como coleta, uso, armazenamento, compartilhamento e exclusão.',
        ],
      ),
      _Section(
        et: et,
        number: '3.',
        title: 'Dados que Coletamos',
        body: '',
        bullets: const [
          'Dados pessoais que você fornece, como nome, e-mail, telefone e dados de pagamento.',
          'Dados técnicos capturados automaticamente, tais como informações de dispositivos, endereço IP, cookies e logs, para aprimorar a experiência e segurança.',
          'Dados relacionados ao uso dos serviços, para personalização e melhoria contínua.',
        ],
      ),
      _Section(
        et: et,
        number: '4.',
        title: 'Finalidades do Tratamento',
        body: '',
        bullets: const [
          'Gerenciar sua conta e assinatura, incluindo faturamento e suporte.',
          'Personalizar a experiência e entregar funcionalidades essenciais.',
          'Enviar comunicações relacionadas aos serviços, marketing autorizado e avisos importantes.',
          'Cumprir obrigações legais, regulatórias e contratos.',
        ],
      ),
      _Section(
        et: et,
        number: '5.',
        title: 'Compartilhamento de Dados',
        body: '',
        bullets: const [
          'Seus dados não são vendidos a terceiros.',
          'Podemos compartilhar dados com parceiros confiáveis (provedores de pagamento, hospedagem, suporte), que estão obrigados a manter a confidencialidade.',
          'Compartilhamento ocorre estritamente para cumprimento das finalidades descritas.',
        ],
      ),
      _Section(
        et: et,
        number: '6.',
        title: 'Segurança e Retenção',
        body: '',
        bullets: const [
          'Aplicamos medidas técnicas e administrativas rigorosas para proteger seus dados contra acessos não autorizados, perdas ou alterações indevidas.',
          'Utilizamos criptografia, firewalls e monitoramento constante.',
          'Reteremos seus dados apenas pelo tempo necessário para atender aos propósitos ou exigências legais.',
        ],
      ),
      _Section(
        et: et,
        number: '7.',
        title: 'Seus Direitos',
        body: '',
        bullets: const [
          'Acesso, correção, exclusão, portabilidade e limitação do tratamento dos seus dados.',
          'Revogação do consentimento e apresentação de reclamação à Autoridade Nacional de Proteção de Dados (ANPD).',
          'Solicitações devem ser enviadas ao Encarregado de Proteção de Dados (DPO) pelo e-mail: privacidade@eantrack.com.',
        ],
      ),
      _Section(
        et: et,
        number: '8.',
        title: 'Cookies e Tecnologias Semelhantes',
        body: '',
        bullets: const [
          'Usamos cookies para personalizar conteúdo, analisar uso e melhorar serviços.',
          'Você pode configurar seu navegador para rejeitar cookies, porém isso pode afetar funcionalidades.',
        ],
      ),
      _Section(
        et: et,
        number: '9.',
        title: 'Atualizações nesta Política',
        body: '',
        bullets: const [
          'Nossa Política de Privacidade pode ser atualizada periodicamente para refletir mudanças legais ou melhorias.',
          'Comunicaremos quaisquer alterações por meio do aplicativo ou e-mail.',
        ],
      ),
      _Section(
        et: et,
        number: '10.',
        title: 'Contato',
        body:
            'Para dúvidas ou exercício dos direitos relacionados a esta política, entre em contato com o '
            'Encarregado de Proteção de Dados (DPO) via privacidade@eantrack.com.',
      ),
      _Section(
        et: et,
        number: '11.',
        title: 'Disposições Gerais',
        body: 'O uso contínuo da plataforma implica aceitação desta Política.',
      ),
    ];
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.et,
    required this.number,
    required this.title,
    required this.body,
    this.bullets = const [],
  });

  final EanTrackTheme et;
  final String number;
  final String title;
  final String body;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                number,
                style: AppTextStyles.titleMedium.copyWith(
                  color: et.primaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: et.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (body.isNotEmpty)
            Text(
              body,
              style: AppTextStyles.bodyMedium.copyWith(
                color: et.secondaryText,
                height: 1.6,
              ),
            ),
          if (bullets.isNotEmpty)
            ...bullets.map(
              (b) => Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: et.secondaryText,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        b,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: et.secondaryText,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
