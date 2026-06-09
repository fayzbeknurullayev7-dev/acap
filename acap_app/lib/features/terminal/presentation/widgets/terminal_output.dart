import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../domain/entities/terminal_session.dart';

class TerminalOutput extends StatelessWidget {
  final List<TerminalLine> lines;
  final ScrollController scrollController;

  const TerminalOutput({
    super.key,
    required this.lines,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      width: double.infinity,
      child: ListView.builder(
        controller:  scrollController,
        padding:     const EdgeInsets.all(12),
        itemCount:   lines.length,
        itemBuilder: (context, i) => _TerminalLine(line: lines[i]),
      ),
    );
  }
}

class _TerminalLine extends StatelessWidget {
  final TerminalLine line;
  const _TerminalLine({required this.line});

  Color get _color {
    switch (line.type) {
      case LineType.command: return AppColors.primary;
      case LineType.error:   return AppColors.error;
      case LineType.system:  return AppColors.warning;
      case LineType.output:  return AppColors.textPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: SelectableText(
        line.text,
        style: AppTypography.code.copyWith(
          color:    _color,
          fontSize: 13,
          height:   1.5,
        ),
      ),
    );
  }
}
