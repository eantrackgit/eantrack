part of 'agency_status_screen.dart';

Color _agencyStatusColor(AgencyDocumentStatus status) => switch (status) {
      AgencyDocumentStatus.approved => AppColors.success,
      AgencyDocumentStatus.pending => AppColors.warning,
      AgencyDocumentStatus.rejected => AppColors.error,
    };

IconData _agencyStatusIcon(AgencyDocumentStatus status) => switch (status) {
      AgencyDocumentStatus.approved => Icons.check_circle,
      AgencyDocumentStatus.pending => Icons.hourglass_bottom,
      AgencyDocumentStatus.rejected => Icons.cancel,
    };

String _agencyStatusLabel(AgencyDocumentStatus status) => switch (status) {
      AgencyDocumentStatus.approved => 'Aprovada',
      AgencyDocumentStatus.pending => 'Aguardando',
      AgencyDocumentStatus.rejected => 'Rejeitada',
    };

Color _ctaColor(AgencyDocumentStatus status, EanTrackTheme et) => switch (status) {
      AgencyDocumentStatus.approved => AppColors.success,
      AgencyDocumentStatus.rejected => AppColors.error,
      AgencyDocumentStatus.pending => et.secondaryText.withValues(alpha: 0.3),
    };

String _documentTitle(String documentType) {
  final normalized = documentType.trim();
  return normalized.isEmpty ? 'Documento' : normalized;
}

String? _formatRepresentativePhone(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return null;

  final digits = text.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 11) {
    return '(${digits.substring(0, 2)}) ${digits.substring(2, 3)} '
        '${digits.substring(3, 7)}-${digits.substring(7)}';
  }

  if (digits.length == 10) {
    return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-'
        '${digits.substring(6)}';
  }

  return text;
}

String _nextStepsText(AgencyDocumentStatus status) => switch (status) {
      AgencyDocumentStatus.approved =>
        'Seu documento foi aprovado com sucesso. Sua agência está liberada para continuar.',
      AgencyDocumentStatus.rejected =>
        'Seu documento foi rejeitado. Você precisa enviar uma nova versão com foto legível para continuar o processo de aprovação.',
      AgencyDocumentStatus.pending =>
        'Recebemos seu documento e ele está em análise. Assim que a verificação for concluída, você será notificado.',
    };

bool _shouldShowRejectionReason(AgencyStatusData data) {
  return data.consolidatedDocumentStatus == AgencyDocumentStatus.rejected &&
      data.rejectionReason?.trim().isNotEmpty == true;
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  final h = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  return '$d/$m/${local.year} $h:$min';
}

TextStyle _cardLabelStyle(EanTrackTheme et) =>
    AppTextStyles.labelSmall.copyWith(
      color: et.secondaryText,
      fontWeight: FontWeight.w600,
    );

TextStyle _cardBodyStyle(EanTrackTheme et) =>
    AppTextStyles.bodyMedium.copyWith(color: et.primaryText);

TextStyle _cardMutedStyle(EanTrackTheme et) =>
    AppTextStyles.bodyMedium.copyWith(color: et.secondaryText);

TextStyle _supportTextStyle(EanTrackTheme et) =>
    AppTextStyles.bodySmall.copyWith(color: et.secondaryText);
