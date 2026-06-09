import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../domain/entities/code_file.dart';

class EditorTabBar extends StatelessWidget {
  final List<EditorTab> tabs;
  final String? activeTabId;
  final ValueChanged<String> onTabTap;
  final ValueChanged<String> onTabClose;

  const EditorTabBar({
    super.key,
    required this.tabs,
    required this.activeTabId,
    required this.onTabTap,
    required this.onTabClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      color: AppColors.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        itemBuilder: (context, i) => _Tab(
          tab:      tabs[i],
          isActive: tabs[i].fileId == activeTabId,
          onTap:    () => onTabTap(tabs[i].fileId),
          onClose:  () => onTabClose(tabs[i].fileId),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final EditorTab tab;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _Tab({
    required this.tab,
    required this.isActive,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.background : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dirty dot
            if (tab.isDirty)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 4),
                decoration: const BoxDecoration(
                  color: AppColors.warning,
                  shape: BoxShape.circle,
                ),
              ),
            Flexible(
              child: Text(
                tab.name,
                style: AppTypography.codeSmall.copyWith(
                  color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onClose,
              child: Icon(
                Icons.close,
                size: 14,
                color: isActive ? AppColors.textSecondary : AppColors.textDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
