import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';

class AiSuggestionOverlay extends StatelessWidget {
  final String suggestion;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;

  const AiSuggestionOverlay({
    super.key,
    required this.suggestion,
    required this.onAccept,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 4,
      left: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVar,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.15),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'AI Suggestion',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onDismiss,
                  child: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              suggestion.length > 120
                  ? '${suggestion.substring(0, 120)}...'
                  : suggestion,
              style: AppTypography.code.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDismiss,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 32),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('Dismiss', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 32),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('Accept (Tab)', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 200.ms)
          .slideY(begin: 0.2, end: 0),
    );
  }
}
