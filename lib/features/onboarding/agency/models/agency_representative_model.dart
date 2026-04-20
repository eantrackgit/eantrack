import 'dart:typed_data';

/// Tipos de documento aceitos para identificacao do representante legal.
enum AgencyRepresentativeDocumentType {
  rg(
    label: 'RG',
    storageFolder: 'RG',
    databaseValue: 'RG',
  ),
  cnh(
    label: 'CNH',
    storageFolder: 'CNH',
    databaseValue: 'CNH',
  ),
  contract(
    label: 'C. Social',
    storageFolder: 'CONTRATO_SOCIAL',
    databaseValue: 'CONTRATO_SOCIAL',
  );

  const AgencyRepresentativeDocumentType({
    required this.label,
    required this.storageFolder,
    required this.databaseValue,
  });

  /// Rotulo exibido na interface para selecao do documento.
  final String label;

  /// Pasta usada no storage para organizar uploads desse documento.
  final String storageFolder;

  /// Valor persistido na tabela `legal_documents`.
  final String databaseValue;

  /// Indica se o documento exige upload de frente e verso.
  bool get requiresFrontAndBack => this == rg || this == cnh;

  /// Indica se o documento usa um unico anexo no fluxo.
  bool get requiresSingleAttachment => this == contract;
}

/// Slots de anexos exibidos conforme o tipo de documento selecionado.
enum AgencyRepresentativeAttachmentSlot {
  front(label: 'FRENTE', filePrefix: 'frente'),
  back(label: 'VERSO', filePrefix: 'verso'),
  attachment(label: 'ANEXO', filePrefix: 'frente');

  const AgencyRepresentativeAttachmentSlot({
    required this.label,
    required this.filePrefix,
  });

  /// Rotulo exibido na area de upload.
  final String label;

  /// Prefixo aplicado ao nome salvo no storage.
  final String filePrefix;
}

/// Arquivo selecionado localmente e mantido em memoria ate o submit.
class AgencyRepresentativePickedFile {
  const AgencyRepresentativePickedFile({
    required this.fileName,
    required this.bytes,
    required this.sizeInBytes,
    required this.contentType,
  });

  /// Nome original exibido para o usuario e reutilizado no upload.
  final String fileName;

  /// Conteudo binario carregado em memoria para envio ao storage.
  final Uint8List bytes;

  /// Tamanho do arquivo em bytes para validacao e exibicao.
  final int sizeInBytes;

  /// MIME type enviado ao storage durante o upload.
  final String contentType;
}

/// Payload enviado ao servico apos validacao local do formulario.
/// Consolida dados textuais e anexos do representante para persistencia.
class AgencyRepresentativeSubmission {
  const AgencyRepresentativeSubmission({
    required this.agencyId,
    required this.name,
    required this.cpf,
    required this.role,
    required this.phone,
    required this.email,
    required this.documentType,
    this.frontFile,
    this.backFile,
    this.attachmentFile,
  });

  /// Identificador da agência criado nas etapas anteriores do onboarding.
  final String agencyId;

  /// Nome completo normalizado do representante legal.
  final String name;

  /// CPF enviado apenas com digitos.
  final String cpf;

  /// Cargo informado para comprovar a funcao do representante.
  final String role;

  /// Telefone enviado apenas com digitos.
  final String phone;

  /// E-mail de contato do representante legal.
  final String email;

  /// Tipo de documento usado para comprovacao.
  final AgencyRepresentativeDocumentType documentType;

  /// Arquivo da frente para RG ou CNH.
  final AgencyRepresentativePickedFile? frontFile;

  /// Arquivo do verso para RG ou CNH.
  final AgencyRepresentativePickedFile? backFile;

  /// Anexo unico usado para contrato social.
  final AgencyRepresentativePickedFile? attachmentFile;

  /// Retorna o arquivo que deve preencher `front_url` no banco.
  /// Para contrato social, o anexo unico ocupa esse campo.
  AgencyRepresentativePickedFile? get frontFileForUpload {
    if (documentType.requiresSingleAttachment) {
      return attachmentFile;
    }
    return frontFile;
  }

  /// Retorna o arquivo que deve preencher `back_url` quando aplicavel.
  AgencyRepresentativePickedFile? get backFileForUpload {
    if (!documentType.requiresFrontAndBack) {
      return null;
    }
    return backFile;
  }
}
