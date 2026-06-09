import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';

/// Mobile-optimized code shortcut bar shown above the software keyboard.
/// Provides quick access to common code symbols and actions.
class EditorKeyboardBar extends StatelessWidget {
  const EditorKeyboardBar({super.key});

  static const _symbols = [
    '(', ')', '{', '}', '[', ']', '<', '>',
    ';', ':', '.', ',', '=', '+', '-', '*',
    '/', '\\', "'", '"', '`', '_', '!', '?',
    '|', '&', '#', '@', '\$', '%', '^', '~',
  ];

  static const _keys = [
    ('Tab', '\t'),
    ('Esc', '\x1b'),
    ('↑',   'up'),
    ('↓',   'down'),
    ('←',   'left'),
    ('→',   'right'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      color: AppColors.surface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: [
          ..._keys.map((k) => _ActionKey(label: k.$1, value: k.$2)),
          const _Divider(),
          ..._symbols.map((s) => _SymbolKey(symbol: s)),
        ],
      ),
    );
  }
}

class _SymbolKey extends StatelessWidget {
  final String symbol;
  const _SymbolKey({required this.symbol});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Insert symbol at cursor via keyboard simulation
        // In a real app, call the editor controller directly
        HapticFeedback.selectionClick();
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 36,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceVar,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.outline, width: 0.5),
        ),
        child: Text(
          symbol,
          style: AppTypography.code.copyWith(
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _ActionKey extends StatelessWidget {
  final String label;
  final String value;
  const _ActionKey({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => HapticFeedback.selectionClick(),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      color: AppColors.outline,
    );
  }
}
