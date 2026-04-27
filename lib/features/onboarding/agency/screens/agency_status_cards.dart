part of 'agency_status_screen.dart';

class _AgencyInfoCard extends StatelessWidget {
  const _AgencyInfoCard({required this.data, required this.isLoading});

  final AgencyStatusData data;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return _StatusSectionCard(
      title: 'Dados da agência',
      titleIcon: Icons.people_alt_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InfoRow(
            label: 'AGÊNCIA',
            value: data.agencyLegalName,
            valueChild:
                isLoading ? const AppSkeleton(height: 16, width: 200) : null,
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(
            label: 'ÚLTIMA ATUALIZAÇÃO',
            value: _formatDateTime(data.agencyUpdatedAt),
            valueChild:
                isLoading ? const AppSkeleton(height: 14, width: 140) : null,
          ),
          const SizedBox(height: AppSpacing.md),
          _StatusInfoRow(status: data.statusAgency, isLoading: isLoading),
        ],
      ),
    );
  }
}

class _DocumentStatusCard extends StatelessWidget {
  const _DocumentStatusCard({required this.data, required this.isLoading});

  final AgencyStatusData data;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return _StatusSectionCard(
      title: 'Status do documento',
      titleIcon: Icons.description_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DocumentTypeTag(
            documentType: data.documentType,
            isLoading: isLoading,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _RepresentativeInfoRow(
                  name: data.representativeName,
                  role: data.representativeRole,
                  isLoading: isLoading,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _ContactInfoRow(
                  email: data.representativeEmail,
                  phone: _formatRepresentativePhone(data.representativePhone),
                  isLoading: isLoading,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _StatusInfoRow(
            status: data.consolidatedDocumentStatus,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }
}

class _DocumentTypeTag extends StatelessWidget {
  const _DocumentTypeTag({
    required this.documentType,
    required this.isLoading,
  });

  final String documentType;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading)
          const AppSkeleton(height: 22, width: 130, radius: 6)
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.actionBlue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppColors.actionBlue.withValues(alpha: 0.22),
              ),
            ),
            child: Text(
              _documentTitle(documentType),
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.actionBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _RepresentativeInfoRow extends StatelessWidget {
  const _RepresentativeInfoRow({
    required this.name,
    required this.role,
    required this.isLoading,
  });

  final String name;
  final String? role;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    final trimmedName = name.trim();
    final trimmedRole = role?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('REPRESENTANTE LEGAL', style: _cardLabelStyle(et)),
        const SizedBox(height: AppSpacing.xs),
        if (isLoading) ...[
          const AppSkeleton(height: 16, width: 150),
          const SizedBox(height: AppSpacing.xs),
          const AppSkeleton(height: 13, width: 110),
        ] else ...[
          Text(
            trimmedName.isEmpty ? '—' : trimmedName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _cardBodyStyle(et).copyWith(fontWeight: FontWeight.w600),
          ),
          if (trimmedRole != null && trimmedRole.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              trimmedRole,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(color: et.secondaryText),
            ),
          ],
        ],
      ],
    );
  }
}

class _ContactInfoRow extends StatelessWidget {
  const _ContactInfoRow({
    required this.email,
    required this.phone,
    required this.isLoading,
  });

  final String email;
  final String? phone;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    final trimmedEmail = email.trim();
    final trimmedPhone = phone?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CONTATO', style: _cardLabelStyle(et)),
        const SizedBox(height: AppSpacing.xs),
        if (isLoading) ...[
          const AppSkeleton(height: 13, width: 170),
          const SizedBox(height: AppSpacing.xs),
          const AppSkeleton(height: 13, width: 130),
        ] else ...[
          Text(
            trimmedEmail.isEmpty ? '—' : trimmedEmail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _cardBodyStyle(et),
          ),
          if (trimmedPhone != null && trimmedPhone.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              trimmedPhone,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _cardMutedStyle(et),
            ),
          ],
        ],
      ],
    );
  }
}
