import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_version_badge.dart';

/// Sidebar de navegação lateral para desktop/tablet.
///
/// Uso em HubScreen (desktop layout):
///   AppSidebar(
///     userName: user.name,
///     userRole: 'Agência',
///     selectedIndex: _selectedIndex,
///     onItemTap: (i) => setState(() => _selectedIndex = i),
///   )
class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.userName,
    required this.userRole,
    this.avatarUrl,
    required this.selectedIndex,
    required this.onItemTap,
  });

  final String userName;
  final String userRole;
  final String? avatarUrl;
  final int selectedIndex;
  final ValueChanged<int> onItemTap;

  static const _items = [
    _SidebarItem(icon: Icons.home_outlined, label: 'Início'),
    _SidebarItem(icon: Icons.map_outlined, label: 'Regiões'),
    _SidebarItem(icon: Icons.hub_outlined, label: 'Redes'),
    _SidebarItem(icon: Icons.category_outlined, label: 'Categorias'),
    _SidebarItem(icon: Icons.store_outlined, label: 'PDVs'),
    _SidebarItem(icon: Icons.group_outlined, label: 'Equipe'),
    _SidebarItem(icon: Icons.settings_outlined, label: 'Configurações'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: AppColors.secondary,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _UserHeader(
              userName: userName,
              userRole: userRole,
              avatarUrl: avatarUrl,
            ),
            Divider(
              color: AppColors.info.withValues(alpha: 0.1),
              height: 1,
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _items.length,
                itemBuilder: (_, i) => _SidebarTile(
                  item: _items[i],
                  selected: selectedIndex == i,
                  onTap: () => onItemTap(i),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: const AppVersionBadge(
                alignment: Alignment.centerLeft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader({
    required this.userName,
    required this.userRole,
    this.avatarUrl,
  });

  final String userName;
  final String userRole;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary,
            backgroundImage:
                avatarUrl != null ? NetworkImage(avatarUrl!) : null,
            child: avatarUrl == null
                ? Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.info,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  userRole,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.accent2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _SidebarItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.accent2;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            border: selected
                ? const Border(
                    left: BorderSide(color: AppColors.primary, width: 3),
                  )
                : const Border(
                    left: BorderSide(color: Colors.transparent, width: 3),
                  ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          child: Row(
            children: [
              Icon(item.icon, size: 20, color: color),
              const SizedBox(width: AppSpacing.sm),
              Text(
                item.label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: color,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarItem {
  const _SidebarItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}
