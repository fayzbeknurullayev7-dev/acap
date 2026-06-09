import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Placeholder Settings screen — to be filled in later.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = const [
      (Icons.person_outline, 'Profil'),
      (Icons.language, 'Til'),
      (Icons.palette_outlined, 'Tema'),
      (Icons.info_outline, 'Haqida'),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              size: 18, color: AppColors.textPrimary),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/dashboard'),
        ),
        title: Text('Settings', style: AppTypography.titleLarge),
      ),
      body: ListView(
        children: [
          for (final (icon, label) in items)
            ListTile(
              leading: Icon(icon, color: AppColors.textSecondary),
              title: Text(label, style: AppTypography.bodyLarge),
              trailing:
                  Icon(Icons.chevron_right, color: AppColors.textDisabled),
              onTap: () {},
            ),
          const Divider(color: AppColors.outline, height: 32),
          ListTile(
            leading: Icon(Icons.logout, color: AppColors.error),
            title: Text('Chiqish',
                style: AppTypography.bodyLarge
                    .copyWith(color: AppColors.error)),
            onTap: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}
