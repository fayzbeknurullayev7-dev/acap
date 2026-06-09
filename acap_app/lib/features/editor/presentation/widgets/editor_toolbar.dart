import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../domain/entities/code_file.dart';

class EditorToolbar extends StatelessWidget {
  final String fileName;
  final FileLanguage? language;
  final bool isDirty;
  final VoidCallback onSave;

  const EditorToolbar({
    super.key,
    required this.fileName,
    required this.language,
    required this.isDirty,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.outline, width: 0.5)),
      ),
      child: Row(
        children: [
          // Back
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            color: AppColors.textSecondary,
            onPressed: () => context.pop(),
          ),

          // File name + dirty indicator
          Expanded(
            child: Row(
              children: [
                Text(
                  fileName,
                  style: AppTypography.bodyMedium.copyWith(
                    fontFamily: 'JetBrainsMono',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (isDirty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.warning.withOpacity(0.4)),
                    ),
                    child: Text(
                      'unsaved',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.warning,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Language badge
          if (language != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceVar,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                language!.displayName,
                style: AppTypography.labelSmall.copyWith(color: AppColors.tertiary),
              ),
            ),

          // Save
          IconButton(
            icon: Icon(
              isDirty ? Icons.save_rounded : Icons.save_outlined,
              size: 20,
              color: isDirty ? AppColors.primary : AppColors.textDisabled,
            ),
            onPressed: isDirty ? onSave : null,
            tooltip: 'Save (Ctrl+S)',
          ),
        ],
      ),
    );
  }
}
