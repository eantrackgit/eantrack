import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../shared/utils/string_utils.dart';
import '../models/agency_confirm_payload.dart';
import '../models/agency_representative_model.dart';
import '../services/agency_representative_service.dart';

/// Controller da tela de cadastro do representante legal da agência.
class AgencyRepresentativeController extends ChangeNotifier {
  AgencyRepresentativeController({
    required AgencyConfirmPayload payload,
    AgencyRepresentativeService? service,
  })  : _payload = payload,
        _service = service ?? AgencyRepresentativeService() {
    fullNameController.addListener(_onFormChanged);
    cpfController.addListener(_onCpfChanged);
    phoneController.addListener(_onFormChanged);
    emailController.addListener(_onFormChanged);
    cpfFocusNode.addListener(_handleCpfFocusChange);
  }

  static const List<String> roles = <String>[
    'Sócio',
    'Diretor',
    'Administrador',
    'Procurador',
    'Outro',
  ];

  final AgencyConfirmPayload _payload;
  final AgencyRepresentativeService _service;

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController cpfController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final FocusNode cpfFocusNode = FocusNode();

  bool _submitted = false;
  bool _isSubmitting = false;
  bool _cpfValidatedOnBlur = false;
  bool _hasCpfBlurred = false;
  String? _selectedRole;
  String? _errorMessage;
  AgencyRepresentativeDocumentType? _selectedDocumentType;
  AgencyRepresentativePickedFile? _frontFile;
  AgencyRepresentativePickedFile? _backFile;
  AgencyRepresentativePickedFile? _attachmentFile;

  String get agencyId => _payload.agencyId;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String? get selectedRole => _selectedRole;
  AgencyRepresentativeDocumentType? get selectedDocumentType =>
      _selectedDocumentType;
  AgencyRepresentativePickedFile? get frontFile => _frontFile;
  AgencyRepresentativePickedFile? get backFile => _backFile;
  AgencyRepresentativePickedFile? get attachmentFile => _attachmentFile;

  bool get isContractSocialSelected =>
      _selectedDocumentType == AgencyRepresentativeDocumentType.contract;

  bool get canAdvance {
    return _normalizedName.isNotEmpty &&
        _cpfValidatedOnBlur &&
        (_selectedRole?.trim().isNotEmpty ?? false) &&
        _rawPhone.length == 11 &&
        isValidEmail(emailController.text) &&
        _hasRequiredDocuments;
  }

  String? get fullNameError {
    if (!_submitted || _normalizedName.isNotEmpty) return null;
    return 'Informe o nome completo.';
  }

  String? get cpfError {
    if (_submitted && _rawCpf.isEmpty) {
      return 'Informe o CPF.';
    }

    final shouldShowInvalidCpfError =
        (_submitted || _hasCpfBlurred) &&
        !_cpfValidatedOnBlur &&
        _rawCpf.length == 11;

    if (shouldShowInvalidCpfError) {
      return 'Informe um CPF válido.';
    }

    return null;
  }

  String? get roleError {
    if (!_submitted || (_selectedRole?.trim().isNotEmpty ?? false)) return null;
    return 'Selecione o cargo.';
  }

  String? get phoneError {
    if (!_submitted) return null;
    if (_rawPhone.isEmpty) return 'Informe o telefone do representante.';
    if (_rawPhone.length != 11) return 'Informe um telefone válido.';
    return null;
  }

  String? get emailError {
    if (!_submitted) return null;
    final email = emailController.text.trim();
    if (email.isEmpty) return 'Informe o e-mail.';
    if (!isValidEmail(email)) return 'Informe um e-mail válido.';
    return null;
  }

  String? get documentTypeError {
    if (!_submitted || _selectedDocumentType != null) return null;
    return 'Selecione o tipo de documento.';
  }

  String? get documentsError {
    if (!_submitted || _selectedDocumentType == null || _hasRequiredDocuments) {
      return null;
    }

    if (_selectedDocumentType!.requiresFrontAndBack) {
      return 'Anexe a frente e o verso do documento.';
    }

    return 'Anexe o documento solicitado.';
  }

  void onCpfEditingComplete() {
    onCpfBlur();
  }

  void onCpfBlur() {
    _hasCpfBlurred = true;
    _cpfValidatedOnBlur = _isCpfValid(_rawCpf);
    notifyListeners();
  }

  void updateRole(String? value) {
    _selectedRole = value;
    _clearErrorMessage();
    notifyListeners();
  }

  void selectDocumentType(AgencyRepresentativeDocumentType type) {
    if (_selectedDocumentType == type) return;

    _selectedDocumentType = type;
    _frontFile = null;
    _backFile = null;
    _attachmentFile = null;
    _clearErrorMessage();
    notifyListeners();
  }

  Future<void> pickFile(AgencyRepresentativeAttachmentSlot slot) async {
    final type = _selectedDocumentType;
    if (type == null) return;

    final allowedExtensions = type.requiresSingleAttachment
        ? const <String>['pdf']
        : const <String>['jpg', 'jpeg', 'png', 'pdf'];

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: true,
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
      );

      if (result == null || result.files.isEmpty) return;

      final pickedFile = _service.buildPickedFile(
        result.files.single,
        pdfOnly: type.requiresSingleAttachment,
      );

      if (_isFileAlreadyAttachedInAnotherSlot(slot, pickedFile.fileName)) {
        _errorMessage = 'Este arquivo já foi anexado em outro campo.';
        notifyListeners();
        return;
      }

      _assignFile(slot, pickedFile);
      _clearErrorMessage();
      notifyListeners();
    } on AgencyRepresentativeServiceException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Não foi possível selecionar o arquivo.';
      notifyListeners();
    }
  }

  /// Aceita um arquivo obtido via drag & drop e o atribui ao [slot] indicado.
  void receiveDroppedFile(
    AgencyRepresentativeAttachmentSlot slot,
    AgencyRepresentativePickedFile file,
  ) {
    if (_isFileAlreadyAttachedInAnotherSlot(slot, file.fileName)) {
      _errorMessage = 'Este arquivo já foi anexado em outro campo.';
      notifyListeners();
      return;
    }

    _assignFile(slot, file);
    _clearErrorMessage();
    notifyListeners();
  }

  void removeFile(AgencyRepresentativeAttachmentSlot slot) {
    _assignFile(slot, null);
    _clearErrorMessage();
    notifyListeners();
  }

  /// Valida o formulário, envia os documentos e persiste o representante legal.
  ///
  /// Retorna `true` em sucesso. Em caso de falha, [errorMessage] é preenchido
  /// com a mensagem correspondente para exibição na UI.
  Future<bool> submit() async {
    _submitted = true;
    onCpfBlur();

    if (!canAdvance || _selectedDocumentType == null) {
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.submit(
        AgencyRepresentativeSubmission(
          agencyId: agencyId,
          name: _normalizedName,
          cpf: _rawCpf,
          role: _selectedRole!,
          phone: _rawPhone,
          email: emailController.text.trim(),
          documentType: _selectedDocumentType!,
          frontFile: _frontFile,
          backFile: _backFile,
          attachmentFile: _attachmentFile,
        ),
      );

      _isSubmitting = false;
      notifyListeners();
      return true;
    } on AgencyRepresentativeServiceException catch (e) {
      _isSubmitting = false;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _isSubmitting = false;
      _errorMessage = 'Não foi possível salvar o representante legal.';
      notifyListeners();
      return false;
    }
  }

  void _handleCpfFocusChange() {
    if (!cpfFocusNode.hasFocus) {
      onCpfBlur();
    }
  }

  void _onCpfChanged() {
    _cpfValidatedOnBlur = false;
    _clearErrorMessage();
    notifyListeners();
  }

  void _onFormChanged() {
    _clearErrorMessage();
    notifyListeners();
  }

  void _clearErrorMessage() {
    if (_errorMessage == null) return;
    _errorMessage = null;
  }

  bool _isCpfValid(String value) {
    if (value.length != 11) return false;
    if (RegExp(r'^(\d)\1{10}$').hasMatch(value)) return false;

    final numbers = value.split('').map(int.parse).toList(growable: false);
    final firstDigit = _calculateCpfDigit(numbers, 9);
    final secondDigit = _calculateCpfDigit(numbers, 10);

    return numbers[9] == firstDigit && numbers[10] == secondDigit;
  }

  int _calculateCpfDigit(List<int> numbers, int length) {
    var sum = 0;
    for (var i = 0; i < length; i++) {
      sum += numbers[i] * ((length + 1) - i);
    }

    final remainder = sum % 11;
    return remainder < 2 ? 0 : 11 - remainder;
  }

  bool get _hasRequiredDocuments {
    final type = _selectedDocumentType;
    if (type == null) return false;

    if (type.requiresFrontAndBack) {
      return _frontFile != null && _backFile != null;
    }

    return _attachmentFile != null;
  }

  void _assignFile(
    AgencyRepresentativeAttachmentSlot slot,
    AgencyRepresentativePickedFile? file,
  ) {
    switch (slot) {
      case AgencyRepresentativeAttachmentSlot.front:
        _frontFile = file;
      case AgencyRepresentativeAttachmentSlot.back:
        _backFile = file;
      case AgencyRepresentativeAttachmentSlot.attachment:
        _attachmentFile = file;
    }
  }

  bool _isFileAlreadyAttachedInAnotherSlot(
    AgencyRepresentativeAttachmentSlot slot,
    String fileName,
  ) {
    final normalized = fileName.trim().toLowerCase();

    for (final entry in <(
      AgencyRepresentativeAttachmentSlot,
      AgencyRepresentativePickedFile?
    )>[
      (AgencyRepresentativeAttachmentSlot.front, _frontFile),
      (AgencyRepresentativeAttachmentSlot.back, _backFile),
      (AgencyRepresentativeAttachmentSlot.attachment, _attachmentFile),
    ]) {
      final entrySlot = entry.$1;
      final pickedFile = entry.$2;

      if (entrySlot == slot || pickedFile == null) continue;

      if (pickedFile.fileName.trim().toLowerCase() == normalized) return true;
    }

    return false;
  }

  String get _normalizedName => fullNameController.text.trim();
  String get _rawCpf => onlyDigits(cpfController.text);
  String get _rawPhone => onlyDigits(phoneController.text);

  @override
  void dispose() {
    fullNameController.removeListener(_onFormChanged);
    cpfController.removeListener(_onCpfChanged);
    phoneController.removeListener(_onFormChanged);
    emailController.removeListener(_onFormChanged);
    cpfFocusNode.removeListener(_handleCpfFocusChange);
    fullNameController.dispose();
    cpfController.dispose();
    phoneController.dispose();
    emailController.dispose();
    cpfFocusNode.dispose();
    super.dispose();
  }
}
