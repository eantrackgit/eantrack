import 'package:flutter/material.dart';

import '../../../../shared/shared.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

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
          'Termos de Uso',
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
                    'TERMOS DE USO – EANTRACK',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: et.primaryText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Última atualização: 29 de setembro de 2025',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: et.secondaryText,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ..._sections(et),
                  const SizedBox(height: AppSpacing.xl),
                  _AcceptanceFooter(et: et),
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
        title: 'ACEITAÇÃO E VIGÊNCIA',
        body:
            'Ao criar uma conta, acessar ou utilizar de qualquer forma a plataforma EANTRACK ("Plataforma" ou '
            '"Serviço"), o Usuário declara expressamente ter lido, compreendido integralmente e aceita, de '
            'forma livre e consciente, todos os termos, condições e políticas aqui estabelecidos. Estes '
            'Termos de Uso constituem um contrato vinculante entre o Usuário e a EANTRACK.\n\n'
            'Caso não concorde com qualquer cláusula deste documento, o Usuário deverá interromper '
            'imediatamente o acesso e não utilizar os serviços da Plataforma.',
      ),
      _Section(
        et: et,
        number: '2.',
        title: 'DEFINIÇÕES',
        body: 'Para fins deste documento, aplicam-se as seguintes definições:',
        bullets: const [
          '2.1. Usuário: Pessoa física ou jurídica, devidamente capacitada nos termos da legislação civil brasileira, que realiza cadastro e utiliza os serviços oferecidos pela Plataforma.',
          '2.2. Plataforma ou Serviço: Sistema digital denominado EANTRACK, disponibilizado via aplicativo móvel (iOS e Android) e interface web, destinado à gestão inteligente, automática e integrada de prazos de validade de produtos, acompanhamento de inventário, controle de abastecimento e geração de relatórios analíticos orientados ao varejo e segmentos correlatos.',
          '2.3. Plano: Modalidade de contratação definida e disponibilizada pela EANTRACK mediante assinatura mensal ou anual, contendo funcionalidades, limites de uso, capacidade de armazenamento, integrações, níveis de suporte e outras especificações técnicas detalhadas no site oficial e/ou aplicativo.',
          '2.4. Assinatura: Relação contratual estabelecida mediante pagamento recorrente (mensal ou anual), com renovação automática nos termos deste instrumento, salvo cancelamento expresso pelo Usuário.',
          '2.5. Dados do Usuário: Conjunto de informações pessoais, comerciais, financeiras e operacionais fornecidas, geradas ou coletadas no curso do uso da Plataforma.',
          '2.6. Conteúdo: Toda informação, texto, fotografia, código de barras (EAN), data, relatório, dado cadastral de produto ou qualquer outro elemento inserido, armazenado ou processado na Plataforma.',
        ],
      ),
      _Section(
        et: et,
        number: '3.',
        title: 'OBJETO',
        body:
            'Este instrumento tem por objeto regular e disciplinar as condições de uso, acesso, contratação, '
            'funcionalidades, direitos, obrigações e responsabilidades relacionadas à Plataforma EANTRACK, '
            'garantindo segurança jurídica e transparência nas relações entre Usuário e prestador do Serviço.',
      ),
      _Section(
        et: et,
        number: '4.',
        title: 'CADASTRO, AUTENTICAÇÃO E SEGURANÇA DA CONTA',
        subsections: const [
          _Subsection(
            title: '4.1. Requisitos de Cadastro',
            body:
                'O Usuário compromete-se a fornecer dados verdadeiros, completos, precisos e atualizados no '
                'momento do cadastro, incluindo, mas não se limitando a: nome completo, documento de '
                'identificação (CPF ou CNPJ), e-mail válido, telefone de contato e endereço.',
          ),
          _Subsection(
            title: '4.2. Confidencialidade de Credenciais',
            body: 'O Usuário é exclusivamente responsável por:',
            bullets: [
              'Manter absoluta confidencialidade de suas credenciais de acesso (login, senha, autenticação de dois fatores);',
              'Todas as atividades, transações e ações realizadas em sua conta, inclusive por terceiros não autorizados em virtude de vazamento, compartilhamento ou negligência na guarda de senha.',
            ],
          ),
          _Subsection(
            title: '4.3. Proibição de Compartilhamento',
            body:
                'É terminantemente vedado ao Usuário ceder, transferir, alugar, sublicenciar, emprestar ou de '
                'qualquer modo compartilhar suas credenciais com terceiros, sejam pessoas físicas ou jurídicas, '
                'salvo autorização expressa e por escrito da EANTRACK.',
          ),
          _Subsection(
            title: '4.4. Comunicação de Incidentes',
            body:
                'O Usuário obriga-se a comunicar imediatamente à EANTRACK qualquer uso não autorizado, '
                'suspeita de violação, acesso indevido ou perda de credenciais, por meio dos canais '
                'oficiais de atendimento.',
          ),
          _Subsection(
            title: '4.5. Suspensão e Cancelamento de Conta',
            body:
                'A EANTRACK reserva-se o direito irrevogável e irretratável de, a qualquer momento e sem '
                'necessidade de aviso prévio, suspender temporariamente ou cancelar definitivamente o '
                'acesso de Usuários que:',
            bullets: [
              'Forneçam dados falsos, incompletos ou enganosos;',
              'Pratiquem atos de fraude, abuso, manipulação ou uso indevido da Plataforma;',
              'Violem qualquer disposição destes Termos de Uso, da Política de Privacidade ou da legislação vigente;',
              'Sejam identificados por mecanismos automatizados de segurança como atividade suspeita ou maliciosa.',
            ],
          ),
        ],
      ),
      _Section(
        et: et,
        number: '5.',
        title: 'CONTRATAÇÃO, PLANOS, PAGAMENTO E RENOVAÇÃO',
        subsections: const [
          _Subsection(
            title: '5.1. Modalidades de Contratação',
            body:
                'A contratação é efetivada mediante seleção do Plano (Gratuito, Individual, Profissional, '
                'Empresarial ou customizado) e adesão expressa aos presentes Termos. O Usuário escolhe a '
                'periodicidade (mensal ou anual) e o método de pagamento disponível.',
          ),
          _Subsection(
            title: '5.2. Pagamento Antecipado e Recorrente',
            body:
                'O pagamento é realizado de forma antecipada mediante cartão de crédito, débito em conta, '
                'PIX ou outros meios disponibilizados pela EANTRACK ou por parceiros homologados. O valor '
                'da assinatura será automaticamente cobrado na data de vencimento conforme ciclo contratado.',
          ),
          _Subsection(
            title: '5.3. Renovação Automática',
            body:
                'A assinatura renova-se automaticamente ao término de cada ciclo contratual (mensal ou anual), '
                'salvo cancelamento prévio solicitado pelo Usuário conforme condições descritas neste documento.',
          ),
          _Subsection(
            title: '5.4. Alteração de Preços e Planos',
            body:
                'A EANTRACK poderá, de acordo com condições de mercado, custos operacionais, desenvolvimento '
                'de novas funcionalidades ou outras razões comerciais, alterar preços, estrutura de Planos e '
                'funcionalidades, mediante comunicação prévia de, no mínimo, 30 (trinta) dias corridos, '
                'enviada ao e-mail cadastrado pelo Usuário. O uso contínuo após o período de aviso implica '
                'aceitação das novas condições.',
          ),
          _Subsection(
            title: '5.5. Cancelamento pelo Usuário',
            body:
                'O Usuário poderá cancelar a renovação automática a qualquer momento, por meio da área de '
                'configurações da conta ou solicitação formal via e-mail. O acesso às funcionalidades premium '
                'será mantido até o término do período já pago. Não haverá reembolso proporcional ao período '
                'não utilizado, salvo disposição legal em contrário ou decisão expressa da EANTRACK.',
          ),
          _Subsection(
            title: '5.6. Inadimplência e Suspensão',
            body: 'Em caso de inadimplência, atraso no pagamento ou recusa de cobrança automática:',
            bullets: [
              'O acesso ao Serviço poderá ser imediatamente suspenso ou limitado;',
              'A EANTRACK poderá acionar meios legais de cobrança;',
              'Dados e funcionalidades premium poderão ser bloqueados até regularização;',
              'Taxas, multas e juros moratórios aplicáveis pela legislação vigente serão devidos pelo Usuário.',
            ],
          ),
        ],
      ),
      _Section(
        et: et,
        number: '6.',
        title: 'OBRIGAÇÕES E RESPONSABILIDADES DO USUÁRIO',
        subsections: const [
          _Subsection(
            title: '6.1. Uso Adequado da Plataforma',
            body:
                'O Usuário compromete-se a utilizar o Serviço exclusivamente para os fins legais e legítimos '
                'previstos, observando as instruções, manuais, tutoriais e orientações fornecidas pela EANTRACK.',
          ),
          _Subsection(
            title: '6.2. Proibições Expressas',
            body: 'É vedado ao Usuário:',
            bullets: [
              'Utilizar a Plataforma para fins ilícitos, fraudulentos, abusivos, lesivos ou que violem direitos de terceiros;',
              'Praticar engenharia reversa, descompilação, modificação, adaptação, tradução ou criação de obras derivadas do software, código-fonte ou de qualquer componente da Plataforma;',
              'Empregar robôs, scripts, ferramentas automatizadas (bots), técnicas de scraping, crawlers ou qualquer mecanismo que prejudique o desempenho, disponibilidade ou segurança da Plataforma;',
              'Interferir, sabotar, comprometer ou prejudicar a experiência de outros usuários;',
              'Inserir, transmitir ou disseminar vírus, malware, spyware, ransomware ou qualquer código malicioso;',
              'Violar direitos de propriedade intelectual, privacidade, honra, imagem ou outros direitos de terceiros;',
              'Comercializar, sublicenciar, alugar ou explorar economicamente a Plataforma ou qualquer de suas funcionalidades sem autorização expressa.',
            ],
          ),
          _Subsection(
            title: '6.3. Responsabilidade pelo Conteúdo Inserido',
            body:
                'O Usuário é integral e exclusivamente responsável por todos os dados, informações, códigos EAN, '
                'fotografias, relatórios e demais conteúdos inseridos ou enviados à Plataforma. A EANTRACK não '
                'se responsabiliza por erros, omissões, inconsistências, inexatidões ou quaisquer danos '
                'decorrentes de informações incorretas fornecidas pelo Usuário.',
          ),
          _Subsection(
            title: '6.4. Uso Comercial e Empresarial',
            body:
                'Usuários que utilizem a Plataforma para fins comerciais, industriais ou empresariais devem '
                'cumprir integralmente a legislação aplicável ao seu setor, incluindo regulamentações sanitárias '
                '(ANVISA), de vigilância sanitária, proteção ao consumidor (CDC), metrologia (INMETRO) e outras '
                'normas técnicas pertinentes.',
          ),
        ],
      ),
      _Section(
        et: et,
        number: '7.',
        title: 'PROPRIEDADE INTELECTUAL',
        subsections: const [
          _Subsection(
            title: '7.1. Titularidade da EANTRACK',
            body:
                'Todos os direitos de propriedade intelectual relativos à Plataforma EANTRACK, incluindo, '
                'mas não se limitando a: marca, logotipos, identidade visual, design e elementos gráficos; '
                'código-fonte, algoritmos, arquitetura de software, banco de dados e estrutura tecnológica; '
                'textos, tutoriais, vídeos, documentações, manuais e materiais de marketing; funcionalidades, '
                'inovações, melhorias, processos e metodologias — são de titularidade exclusiva da EANTRACK, '
                'protegidos pelas leis brasileiras (Lei nº 9.609/98, Lei nº 9.610/98, Lei nº 9.279/96) e '
                'tratados internacionais aplicáveis.',
          ),
          _Subsection(
            title: '7.2. Licença de Uso Limitada',
            body:
                'O Usuário recebe uma licença de uso não exclusiva, intransferível, revogável, limitada e '
                'temporária para acessar e utilizar a Plataforma exclusivamente para os fins previstos nestes '
                'Termos e durante a vigência da assinatura.',
          ),
          _Subsection(
            title: '7.3. Proibição de Reprodução e Distribuição',
            body:
                'É expressamente vedado ao Usuário copiar, reproduzir, modificar, distribuir, transmitir, '
                'exibir publicamente, sublicenciar, vender ou explorar comercialmente qualquer elemento da '
                'Plataforma sem autorização expressa e por escrito da EANTRACK.',
          ),
          _Subsection(
            title: '7.4. Cessão de Direitos sobre Conteúdo do Usuário',
            body:
                'Ao inserir Conteúdo na Plataforma, o Usuário concede à EANTRACK licença mundial, gratuita, '
                'perpétua, irrevogável e sublicenciável para utilizar, armazenar, processar, reproduzir, '
                'adaptar e exibir o referido Conteúdo exclusivamente para os fins de: operacionalizar o '
                'Serviço; realizar análises estatísticas, aprimorar funcionalidades e desenvolver novos '
                'produtos; apresentar dados agregados e anonimizados para estudos de mercado e benchmarking.',
          ),
        ],
      ),
      _Section(
        et: et,
        number: '8.',
        title: 'PROTEÇÃO DE DADOS PESSOAIS E PRIVACIDADE',
        subsections: const [
          _Subsection(
            title: '8.1. Conformidade com a LGPD',
            body:
                'O tratamento de dados pessoais pela EANTRACK observa rigorosamente as disposições da Lei '
                'Geral de Proteção de Dados Pessoais (Lei nº 13.709/2018 – LGPD) e demais legislações aplicáveis.',
          ),
          _Subsection(
            title: '8.2. Política de Privacidade',
            body:
                'A coleta, armazenamento, uso, compartilhamento, segurança, retenção e exclusão de dados '
                'pessoais estão integralmente disciplinados na Política de Privacidade, disponível no site '
                'oficial e no aplicativo da EANTRACK, a qual faz parte integrante e indissociável destes '
                'Termos de Uso.',
          ),
          _Subsection(
            title: '8.3. Consentimento do Usuário',
            body:
                'Ao aceitar estes Termos, o Usuário consente livre, informada e inequivocamente com a coleta '
                'e tratamento de seus dados pessoais conforme descrito na Política de Privacidade.',
          ),
          _Subsection(
            title: '8.4. Direitos do Titular de Dados',
            body: 'O Usuário, na qualidade de titular de dados pessoais, possui os seguintes direitos garantidos pela LGPD:',
            bullets: [
              'Confirmação da existência de tratamento;',
              'Acesso aos dados;',
              'Correção de dados incompletos, inexatos ou desatualizados;',
              'Anonimização, bloqueio ou eliminação de dados desnecessários ou tratados em desconformidade;',
              'Portabilidade dos dados;',
              'Eliminação dos dados tratados com consentimento;',
              'Informação sobre compartilhamento de dados;',
              'Revogação do consentimento.',
            ],
          ),
          _Subsection(
            title: '8.5. Segurança da Informação',
            body:
                'A EANTRACK adota medidas técnicas e organizacionais apropriadas e compatíveis com o estado '
                'da arte para proteger os dados pessoais contra acessos não autorizados, destruição, perda, '
                'alteração, divulgação ou qualquer forma de tratamento inadequado ou ilícito.',
          ),
        ],
      ),
      _Section(
        et: et,
        number: '9.',
        title: 'LIMITAÇÃO DE RESPONSABILIDADE',
        subsections: const [
          _Subsection(
            title: '9.1. Disponibilidade do Serviço',
            body:
                'A EANTRACK envidará seus melhores esforços para garantir a disponibilidade contínua da '
                'Plataforma. Contudo, não garante que o Serviço estará disponível de forma ininterrupta, '
                'sem falhas, erros, interrupções ou indisponibilidades decorrentes de: manutenções '
                'programadas ou emergenciais; atualizações de sistema, segurança ou infraestrutura; falhas '
                'de terceiros (provedores de internet, servidores, serviços de nuvem, sistemas de '
                'pagamento); caso fortuito ou força maior.',
          ),
          _Subsection(
            title: '9.2. Isenção de Garantias Implícitas',
            body:
                'O Serviço é fornecido "no estado em que se encontra" (as is) e "conforme disponível" '
                '(as available), sem garantias expressas ou implícitas de qualquer natureza, incluindo, '
                'mas não se limitando a: adequação a finalidade específica, comercialização, precisão, '
                'completude, continuidade, segurança absoluta ou ausência de vírus.',
          ),
          _Subsection(
            title: '9.3. Exclusão de Responsabilidade por Danos Indiretos',
            body: 'Em nenhuma hipótese a EANTRACK será responsável por:',
            bullets: [
              'Danos indiretos, incidentais, consequenciais, punitivos, especiais ou exemplares;',
              'Lucros cessantes, perda de faturamento, perda de oportunidade de negócio, perda de dados, danos à reputação ou perda de clientes;',
              'Decisões, atos, omissões ou estratégias tomadas pelo Usuário com base nas informações, relatórios ou funcionalidades da Plataforma;',
              'Prejuízos decorrentes de uso inadequado, negligente, imprudente ou em desconformidade com estes Termos.',
            ],
          ),
          _Subsection(
            title: '9.4. Limitação de Responsabilidade Financeira',
            body:
                'A responsabilidade total e agregada da EANTRACK por quaisquer danos, perdas ou prejuízos '
                'decorrentes ou relacionados a estes Termos, ao Serviço ou ao uso da Plataforma ficará '
                'limitada ao valor total efetivamente pago pelo Usuário à EANTRACK nos 12 (doze) meses '
                'imediatamente anteriores ao evento que deu origem à reclamação.',
          ),
          _Subsection(
            title: '9.5. Decisões do Usuário',
            body:
                'O Usuário reconhece e concorda expressamente que a EANTRACK não se responsabiliza por '
                'quaisquer decisões comerciais, operacionais, estratégicas ou gerenciais tomadas com base '
                'em dados, relatórios, alertas, notificações ou informações fornecidas pela Plataforma. '
                'A utilização do Serviço não substitui a diligência, análise crítica e responsabilidade '
                'profissional do Usuário.',
          ),
        ],
      ),
      _Section(
        et: et,
        number: '10.',
        title: 'MODIFICAÇÕES DOS TERMOS DE USO',
        subsections: const [
          _Subsection(
            title: '10.1. Direito de Alteração',
            body:
                'A EANTRACK reserva-se o direito de modificar, atualizar, revisar ou substituir, a qualquer '
                'tempo e a seu exclusivo critério, total ou parcialmente, estes Termos de Uso, para refletir '
                'mudanças na legislação aplicável, aprimoramentos tecnológicos, novas práticas de mercado '
                'ou adequações à segurança e conformidade regulatória.',
          ),
          _Subsection(
            title: '10.2. Comunicação de Alterações',
            body: 'O Usuário será notificado sobre qualquer alteração substancial destes Termos por meio de:',
            bullets: [
              'E-mail enviado ao endereço cadastrado;',
              'Notificação in-app (push notification ou banner);',
              'Aviso destacado no site oficial ou aplicativo.',
            ],
          ),
          _Subsection(
            title: '10.3. Vigência e Aceitação',
            body:
                'As alterações entrarão em vigor 15 (quinze) dias corridos após a comunicação. O uso '
                'contínuo da Plataforma após esse prazo implica aceitação tácita e integral das novas '
                'condições. Caso o Usuário não concorde com as modificações, deverá cancelar sua '
                'assinatura e interromper imediatamente o uso do Serviço.',
          ),
        ],
      ),
      _Section(
        et: et,
        number: '11.',
        title: 'RESCISÃO E CANCELAMENTO',
        subsections: const [
          _Subsection(
            title: '11.1. Rescisão pelo Usuário',
            body:
                'O Usuário poderá rescindir este contrato e cancelar sua assinatura a qualquer momento, '
                'mediante acesso à área de configurações da conta ou solicitação formal via e-mail aos '
                'canais de atendimento oficiais. Após o cancelamento, o acesso às funcionalidades premium '
                'será mantido até o final do período já pago. Não haverá devolução ou reembolso '
                'proporcional de valores pagos, salvo disposição legal ou decisão expressa da EANTRACK.',
          ),
          _Subsection(
            title: '11.2. Rescisão pela EANTRACK',
            body:
                'A EANTRACK poderá, a qualquer tempo, sem aviso prévio e sem qualquer ônus ou indenização, '
                'suspender, bloquear ou cancelar definitivamente o acesso do Usuário nas seguintes hipóteses:',
            bullets: [
              'Violação de qualquer cláusula destes Termos de Uso;',
              'Violação da Política de Privacidade;',
              'Prática de atos ilícitos, fraudulentos, abusivos ou lesivos;',
              'Fornecimento de informações falsas, incompletas ou enganosas;',
              'Inadimplência superior a 15 (quinze) dias corridos;',
              'Decisão judicial, administrativa ou regulatória que determine o bloqueio ou exclusão;',
              'Identificação de atividade suspeita, maliciosa ou que comprometa a segurança da Plataforma.',
            ],
          ),
          _Subsection(
            title: '11.3. Efeitos da Rescisão',
            body: 'Após a rescisão ou cancelamento:',
            bullets: [
              'O Usuário perderá imediatamente o acesso à Plataforma e a todas as funcionalidades;',
              'Dados e conteúdos armazenados poderão ser excluídos conforme Política de Retenção de Dados;',
              'Obrigações financeiras vencidas e não pagas permanecerão exigíveis;',
              'Cláusulas de natureza perene (propriedade intelectual, limitação de responsabilidade, confidencialidade, foro) continuarão em vigor.',
            ],
          ),
        ],
      ),
      _Section(
        et: et,
        number: '12.',
        title: 'CONFIDENCIALIDADE',
        subsections: const [
          _Subsection(
            title: '12.1. Informações Confidenciais',
            body:
                'O Usuário reconhece que, no curso do uso da Plataforma, poderá ter acesso a informações '
                'técnicas, comerciais, estratégicas, operacionais ou proprietárias da EANTRACK, consideradas '
                'confidenciais e de alto valor competitivo.',
          ),
          _Subsection(
            title: '12.2. Obrigação de Sigilo',
            body: 'O Usuário compromete-se a:',
            bullets: [
              'Manter absoluto sigilo sobre todas as informações confidenciais;',
              'Não divulgar, reproduzir, compartilhar ou utilizar tais informações para finalidade diversa do uso legítimo da Plataforma;',
              'Proteger as informações com o mesmo nível de cuidado aplicado às suas próprias informações confidenciais.',
            ],
          ),
          _Subsection(
            title: '12.3. Exceções',
            body: 'Não se aplicam as obrigações de confidencialidade às informações que:',
            bullets: [
              'Sejam ou se tornem públicas sem violação destes Termos;',
              'Sejam legitimamente obtidas de terceiros sem restrições de confidencialidade;',
              'Sejam desenvolvidas independentemente pelo Usuário sem uso das informações confidenciais;',
              'Devam ser divulgadas por força de lei, ordem judicial ou requisição de autoridade competente.',
            ],
          ),
        ],
      ),
      _Section(
        et: et,
        number: '13.',
        title: 'DISPOSIÇÕES GERAIS',
        subsections: const [
          _Subsection(
            title: '13.1. Independência das Cláusulas',
            body:
                'Caso qualquer disposição destes Termos seja considerada inválida, ilegal ou inexequível '
                'por autoridade judicial ou administrativa competente, tal invalidade não afetará as demais '
                'cláusulas, que permanecerão em pleno vigor e efeito.',
          ),
          _Subsection(
            title: '13.2. Não Renúncia de Direitos',
            body:
                'O não exercício, atraso ou tolerância da EANTRACK em exigir o cumprimento de qualquer '
                'disposição destes Termos não constituirá renúncia, novação ou precedente, podendo a '
                'EANTRACK exigir o cumprimento a qualquer tempo.',
          ),
          _Subsection(
            title: '13.3. Integralidade do Acordo',
            body:
                'Estes Termos de Uso, juntamente com a Política de Privacidade e demais documentos neles '
                'referenciados, constituem o acordo integral entre o Usuário e a EANTRACK, substituindo e '
                'prevalecendo sobre quaisquer entendimentos, negociações, propostas ou acordos anteriores, '
                'verbais ou escritos.',
          ),
          _Subsection(
            title: '13.4. Cessão',
            body:
                'O Usuário não poderá ceder, transferir, sublicenciar ou de qualquer forma dispor de seus '
                'direitos e obrigações decorrentes destes Termos sem prévia e expressa autorização por '
                'escrito da EANTRACK. A EANTRACK poderá livremente ceder este contrato a terceiros, '
                'mediante notificação ao Usuário.',
          ),
          _Subsection(
            title: '13.5. Notificações',
            body:
                'Todas as comunicações, notificações e avisos previstos nestes Termos serão considerados '
                'válidos e eficazes quando enviados ao e-mail cadastrado pelo Usuário ou exibidos na '
                'Plataforma (banner, pop-up ou notificação in-app).',
          ),
          _Subsection(
            title: '13.6. Idioma',
            body:
                'Estes Termos são redigidos em língua portuguesa (Brasil). Eventuais traduções para outros '
                'idiomas têm caráter meramente informativo, prevalecendo sempre a versão em português '
                'em caso de divergência.',
          ),
        ],
      ),
      _Section(
        et: et,
        number: '14.',
        title: 'LEGISLAÇÃO APLICÁVEL E FORO',
        subsections: const [
          _Subsection(
            title: '14.1. Lei Brasileira',
            body: 'Estes Termos de Uso são regidos e interpretados de acordo com as leis da República Federativa do Brasil, em especial:',
            bullets: [
              'Lei nº 13.709/2018 (LGPD – Lei Geral de Proteção de Dados Pessoais);',
              'Lei nº 8.078/1990 (CDC – Código de Defesa do Consumidor);',
              'Lei nº 12.965/2014 (Marco Civil da Internet);',
              'Lei nº 10.406/2002 (Código Civil);',
              'Demais legislações aplicáveis.',
            ],
          ),
          _Subsection(
            title: '14.2. Foro Competente',
            body:
                'As partes elegem, de comum acordo, o foro da comarca da sede da EANTRACK, com exclusão '
                'de qualquer outro, por mais privilegiado que seja, para dirimir quaisquer controvérsias, '
                'litígios ou questões decorrentes ou relacionadas a estes Termos de Uso.',
          ),
          _Subsection(
            title: '14.3. Ressalva para Consumidores',
            body:
                'Nos termos do art. 101, I, do Código de Defesa do Consumidor, em se tratando de relação '
                'de consumo, o Usuário pessoa física consumidora poderá optar pelo foro de seu domicílio '
                'para ajuizamento de ação.',
          ),
        ],
      ),
      _Section(
        et: et,
        number: '15.',
        title: 'CONTATO',
        body:
            'Para dúvidas, solicitações, sugestões, exercício de direitos relativos a dados pessoais ou '
            'qualquer outra comunicação relacionada a estes Termos de Uso ou à Plataforma EANTRACK, o '
            'Usuário poderá entrar em contato pelos seguintes canais:\n\n'
            'E-mail: suporte@eantrack.com.br\n'
            'Site: www.eantrack.com.br',
      ),
    ];
  }
}

class _AcceptanceFooter extends StatelessWidget {
  const _AcceptanceFooter({required this.et});

  final EanTrackTheme et;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: et.surface.withValues(alpha: 0.6),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: et.surfaceBorder),
      ),
      child: Text(
        'Ao utilizar a Plataforma EANTRACK, o Usuário declara ter lido, compreendido e aceito '
        'integralmente os presentes Termos de Uso.',
        textAlign: TextAlign.center,
        style: AppTextStyles.bodySmall.copyWith(
          color: et.secondaryText,
          height: 1.6,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets internos
// ---------------------------------------------------------------------------

class _Subsection {
  const _Subsection({
    required this.title,
    required this.body,
    this.bullets = const [],
  });

  final String title;
  final String body;
  final List<String> bullets;
}

class _Section extends StatelessWidget {
  const _Section({
    required this.et,
    required this.number,
    required this.title,
    this.body = '',
    this.bullets = const [],
    this.subsections = const [],
  });

  final EanTrackTheme et;
  final String number;
  final String title;
  final String body;
  final List<String> bullets;
  final List<_Subsection> subsections;

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
          if (body.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              body,
              style: AppTextStyles.bodyMedium.copyWith(
                color: et.secondaryText,
                height: 1.6,
              ),
            ),
          ],
          if (bullets.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            ..._buildBullets(bullets, et),
          ],
          if (subsections.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            ...subsections.map((s) => _SubsectionWidget(et: et, sub: s)),
          ],
        ],
      ),
    );
  }
}

class _SubsectionWidget extends StatelessWidget {
  const _SubsectionWidget({required this.et, required this.sub});

  final EanTrackTheme et;
  final _Subsection sub;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            sub.title,
            style: AppTextStyles.bodyMedium.copyWith(
              color: et.primaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (sub.body.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              sub.body,
              style: AppTextStyles.bodyMedium.copyWith(
                color: et.secondaryText,
                height: 1.6,
              ),
            ),
          ],
          if (sub.bullets.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            ..._buildBullets(sub.bullets, et),
          ],
        ],
      ),
    );
  }
}

List<Widget> _buildBullets(List<String> bullets, EanTrackTheme et) {
  return bullets
      .map(
        (b) => Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 7, left: 4),
                child: Container(
                  width: 4,
                  height: 4,
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
      )
      .toList();
}
