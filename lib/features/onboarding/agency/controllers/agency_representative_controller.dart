import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/utils/string_utils.dart';
import '../models/agency_confirm_payload.dart';
import '../models/agency_representative_model.dart';
import '../services/agency_representative_service.dart';

const _agencyRepresentativeUnset = Object();

class AgencyRepresentativeState {
  const AgencyRepresentativeState({
    this.submitted = false,
    this.isLoading = false,
    this.error,
    this.documents = const <AgencyRepresentativePickedFile>[],
    this.cpfValidatedOnBlur = false,
    this.hasCpfBlurred = false,
    this.selectedRole,
    this.selectedDocumentType,
    this.frontFile,
    this.backFile,
    this.attachmentFile,
    this.fullNameText = '',
    this.cpfText = '',
    this.phoneText = '',
    this.emailText = '',
  });

  final bool submitted;
  final bool isLoading;
  final String? error;
  final List<AgencyRepresentativePickedFile> documents;
  final bool cpfValidatedOnBlur;
  final bool hasCpfBlurred;
  final String? selectedRole;
  final AgencyRepresentativeDocumentType? selectedDocumentType;
  final AgencyRepresentativePickedFile? frontFile;
  final AgencyRepresentativePickedFile? backFile;
  final AgencyRepresentativePickedFile? attachmentFile;
  final String fullNameText;
  final String cpfText;
  final String phoneText;
  final String emailText;

  bool get isSubmitting => isLoading;
  String? get errorMessage => error;

  bool get isContractSocialSelected =>
      selectedDocumentType == AgencyRepresentativeDocumentType.contract;

  bool get canAdvance {
    return _normalizedName.isNotEmpty &&
        cpfValidatedOnBlur &&
        (selectedRole?.trim().isNotEmpty ?? false) &&
        _rawPhone.length == 11 &&
        isValidEmail(emailText) &&
        _hasRequiredDocuments;
  }

  String? get fullNameError {
    if (!submitted || _normalizedName.isNotEmpty) return null;
    return 'Informe o nome completo.';
  }

  String? get cpfError {
    if (submitted && _rawCpf.isEmpty) {
      return 'Informe o CPF.';
    }

    final shouldShowInvalidCpfError =
        (submitted || hasCpfBlurred) &&
        !cpfValidatedOnBlur &&
        _rawCpf.length == 11;

    if (shouldShowInvalidCpfError) {
      return 'Informe um CPF vÃ¡lido.';
    }

    return null;
  }

  String? get roleError {
    if (!submitted || (selectedRole?.trim().isNotEmpty ?? false)) return null;
    return 'Selecione o cargo.';
  }

  String? get phoneError {
    if (!submitted) return null;
    if (_rawPhone.isEmpty) return 'Informe o telefone do representante.';
    if (_rawPhone.length != 11) return 'Informe um telefone vÃ¡lido.';
    return null;
  }

  String? get emailError {
    if (!submitted) return null;
    final email = emailText.trim();
    if (email.isEmpty) return 'Informe o e-mail.';
    if (!isValidEmail(email)) return 'Informe um e-mail vÃ¡lido.';
    return null;
  }

  String? get documentTypeError {
    if (!submitted || selectedDocumentType != null) return null;
    return 'Selecione o tipo de documento.';
  }

  String? get documentsError {
    if (!submitted || selectedDocumentType == null || _hasRequiredDocuments) {
      return null;
    }

    if (selectedDocumentType!.requiresFrontAndBack) {
      return 'Anexe a frente e o verso do documento.';
    }

    return 'Anexe o documento solicitado.';
  }

  AgencyRepresentativeState copyWith({
    bool? submitted,
    bool? isLoading,
    Object? error = _agencyRepresentativeUnset,
    Object? documents = _agencyRepresentativeUnset,
    bool? cpfValidatedOnBlur,
    bool? hasCpfBlurred,
    Object? selectedRole = _agencyRepresentativeUnset,
    Object? selectedDocumentType = _agencyRepresentativeUnset,
    Object? frontFile = _agencyRepresentativeUnset,
    Object? backFile = _agencyRepresentativeUnset,
    Object? attachmentFile = _agencyRepresentativeUnset,
    String? fullNameText,
    String? cpfText,
    String? phoneText,
    String? emailText,
  }) {
    return AgencyRepresentativeState(
      submitted: submitted ?? this.submitted,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _agencyRepresentativeUnset)
          ? this.error
          : error as String?,
      documents: identical(documents, _agencyRepresentativeUnset)
          ? this.documents
          : List<AgencyRepresentativePickedFile>.unmodifiable(
              documents as List<AgencyRepresentativePickedFile>,
            ),
      cpfValidatedOnBlur: cpfValidatedOnBlur ?? this.cpfValidatedOnBlur,
      hasCpfBlurred: hasCpfBlurred ?? this.hasCpfBlurred,
      selectedRole: identical(selectedRole, _agencyRepresentativeUnset)
          ? this.selectedRole
          : selectedRole as String?,
      selectedDocumentType:
          identical(selectedDocumentType, _agencyRepresentativeUnset)
              ? this.selectedDocumentType
              : selectedDocumentType as AgencyRepresentativeDocumentType?,
      frontFile: identical(frontFile, _agencyRepresentativeUnset)
          ? this.frontFile
          : frontFile as AgencyRepresentativePickedFile?,
      backFile: identical(backFile, _agencyRepresentativeUnset)
          ? this.backFile
          : backFile as AgencyRepresentativePickedFile?,
      attachmentFile: identical(attachmentFile, _agencyRepresentativeUnset)
          ? this.attachmentFile
          : attachmentFile as AgencyRepresentativePickedFile?,
      fullNameText: fullNameText ?? this.fullNameText,
      cpfText: cpfText ?? this.cpfText,
      phoneText: phoneText ?? this.phoneText,
      emailText: emailText ?? this.emailText,
    );
  }

  bool get _hasRequiredDocuments {
    final type = selectedDocumentType;
    if (type == null) return false;

    if (type.requiresFrontAndBack) {
      return frontFile != null && backFile != null;
    }

    return attachmentFile != null;
  }

  String get _normalizedName => fullNameText.trim();
  String get _rawCpf => onlyDigits(cpfText);
  String get _rawPhone => onlyDigits(phoneText);
}

final agencyRepresentativeProvider = StateNotifierProvider.autoDispose.family<
    AgencyRepresentativeNotifier,
    AgencyRepresentativeState,
    AgencyConfirmPayload>(
  (ref, payload) => AgencyRepresentativeNotifier(payload: payload),
);

class AgencyRepresentativeNotifier
    extends StateNotifier<AgencyRepresentativeState> {
  AgencyRepresentativeNotifier({
    required AgencyConfirmPayload payload,
    AgencyRepresentativeService? service,
  })  : _payload = payload,
        _service = service ?? AgencyRepresentativeService(),
        super(const AgencyRepresentativeState()) {
    fullNameController.addListener(_onFormChanged);
    cpfController.addListener(_onCpfChanged);
    phoneController.addListener(_onFormChanged);
    emailController.addListener(_onFormChanged);
    cpfFocusNode.addListener(_handleCpfFocusChange);
    _syncTextState();
  }

  static const List<String> roles = <String>[
    'SÃ³cio',
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

  String get agencyId => _payload.agencyId;

  void onCpfEditingComplete() {
    onCpfBlur();
  }

  void onCpfBlur() {
    state = state.copyWith(
      hasCpfBlurred: true,
      cpfValidatedOnBlur: _isCpfValid(_rawCpf),
    );
  }

  void updateRole(String? value) {
    state = state.copyWith(error: null, selectedRole: value);
  }

  void selectDocumentType(AgencyRepresentativeDocumentType type) {
    if (state.selectedDocumentType == type) return;

    state = state.copyWith(
      selectedDocumentType: type,
      frontFile: null,
      backFile: null,
      attachmentFile: null,
      documents: const <AgencyRepresentativePickedFile>[],
      error: null,
    );
  }

  Future<void> pickFile(AgencyRepresentativeAttachmentSlot slot) async {
    final type = state.selectedDocumentType;
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
        state = state.copyWith(
          error: 'Este arquivo jÃ¡ foi anexado em outro campo.',
        );
        return;
      }

      _assignFile(slot, pickedFile);
      state = state.copyWith(error: null);
    } on AgencyRepresentativeServiceException catch (e) {
      state = state.copyWith(error: e.message);
    } catch (_) {
      state = state.copyWith(
        error: 'NÃ£o foi possÃ­vel selecionar o arquivo.',
      );
    }
  }

  void receiveDroppedFile(
    AgencyRepresentativeAttachmentSlot slot,
    AgencyRepresentativePickedFile file,
  ) {
    if (_isFileAlreadyAttachedInAnotherSlot(slot, file.fileName)) {
      state = state.copyWith(
        error: 'Este arquivo jÃ¡ foi anexado em outro campo.',
      );
      return;
    }

    _assignFile(slot, file);
    state = state.copyWith(error: null);
  }

  void removeFile(AgencyRepresentativeAttachmentSlot slot) {
    _assignFile(slot, null);
    state = state.copyWith(error: null);
  }

  Future<bool> submit() async {
    state = state.copyWith(submitted: true);
    onCpfBlur();

    if (!state.canAdvance || state.selectedDocumentType == null) {
      return false;
    }

    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      await _service.submit(
        AgencyRepresentativeSubmission(
          agencyId: agencyId,
          name: _normalizedName,
          cpf: _rawCpf,
          role: state.selectedRole!,
          phone: _rawPhone,
          email: emailController.text.trim(),
          documentType: state.selectedDocumentType!,
          frontFile: state.frontFile,
          backFile: state.backFile,
          attachmentFile: state.attachmentFile,
        ),
      );

      state = state.copyWith(isLoading: false);
      return true;
    } on AgencyRepresentativeServiceException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'NÃ£o foi possÃ­vel salvar o representante legal.',
      );
      return false;
    }
  }

  void _handleCpfFocusChange() {
    if (!cpfFocusNode.hasFocus) {
      onCpfBlur();
    }
  }

  void _onCpfChanged() {
    state = state.copyWith(
      cpfValidatedOnBlur: false,
      error: null,
      cpfText: cpfController.text,
    );
  }

  void _onFormChanged() {
    state = state.copyWith(
      error: null,
      fullNameText: fullNameController.text,
      phoneText: phoneController.text,
      emailText: emailController.text,
    );
  }

  void _syncTextState() {
    state = state.copyWith(
      fullNameText: fullNameController.text,
      cpfText: cpfController.text,
      phoneText: phoneController.text,
      emailText: emailController.text,
    );
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

  void _assignFile(
    AgencyRepresentativeAttachmentSlot slot,
    AgencyRepresentativePickedFile? file,
  ) {
    final nextFrontFile = slot == AgencyRepresentativeAttachmentSlot.front
        ? file
        : state.frontFile;
    final nextBackFile = slot == AgencyRepresentativeAttachmentSlot.back
        ? file
        : state.backFile;
    final nextAttachmentFile =
        slot == AgencyRepresentativeAttachmentSlot.attachment
            ? file
            : state.attachmentFile;

    state = state.copyWith(
      frontFile: nextFrontFile,
      backFile: nextBackFile,
      attachmentFile: nextAttachmentFile,
      documents: _buildDocuments(
        frontFile: nextFrontFile,
        backFile: nextBackFile,
        attachmentFile: nextAttachmentFile,
      ),
    );
  }

  List<AgencyRepresentativePickedFile> _buildDocuments({
    AgencyRepresentativePickedFile? frontFile,
    AgencyRepresentativePickedFile? backFile,
    AgencyRepresentativePickedFile? attachmentFile,
  }) {
    return <AgencyRepresentativePickedFile>[
      if (frontFile != null) frontFile,
      if (backFile != null) backFile,
      if (attachmentFile != null) attachmentFile,
    ];
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
      (AgencyRepresentativeAttachmentSlot.front, state.frontFile),
      (AgencyRepresentativeAttachmentSlot.back, state.backFile),
      (AgencyRepresentativeAttachmentSlot.attachment, state.attachmentFile),
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
