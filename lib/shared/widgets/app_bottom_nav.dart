import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Barra de navegação inferior para mobile.
///
/// Uso em HubScreen (mobile layout):
///   AppBottomNav(
///     currentIndex: _currentIndex,
///     onTap: (i) => setState(() => _currentIndex = i),
///   )
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.secondary,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.accent2,
      selectedLabelStyle: AppTextStyles.labelSmall.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: AppTextStyles.labelSmall.copyWith(
        color: AppColors.accent2,
      ),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Início',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.store_outlined),
          activeIcon: Icon(Icons.store),
          label: 'PDVs',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment_outlined),
          activeIcon: Icon(Icons.assignment),
          label: 'Operações',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.factory_outlined),
          activeIcon: Icon(Icons.factory),
          label: 'Indústrias',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          activeIcon: Icon(Icons.calendar_today),
          label: 'Agenda',
        ),
      ],
    );
  }
}
