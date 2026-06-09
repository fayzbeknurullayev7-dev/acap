// lib/features/agent/presentation/widgets/agent_input_bar.dart

import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';

class AgentInputBar extends StatefulWidget {
  final bool isLoading;
  final void Function(String) onSend;

  const AgentInputBar({
    super.key,
    required this.isLoading,
    required this.onSend,
  });

  @override
  State<AgentInputBar> createState() => _AgentInputBarState();
}

class _AgentInputBarState extends State<AgentInputBar> {
  final _ctrl   = TextEditingController();
  final _focus  = FocusNode();
  bool  _hasText = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final has = _ctrl.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _send() {
    if (!_hasText || widget.isLoading) return;
    final text = _ctrl.text.trim();
    _ctrl.clear();
    widget.onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Text field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color:        AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller:  _ctrl,
                  focusNode:   _focus,
                  maxLines:    5,
                  minLines:    1,
                  enabled:     !widget.isLoading,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  style: TextStyle(
                    color:    AppColors.textPrimary,
                    fontSize: 14,
                    height:   1.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Agentlarga vazifa bering…',
                    hintStyle: TextStyle(
                      color:    AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    border:         InputBorder.none,
                    contentPadding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Send button
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _hasText && !widget.isLoading
                    ? AppColors.primary
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _hasText && !widget.isLoading
                      ? AppColors.primary
                      : AppColors.border,
                ),
              ),
              child: widget.isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    )
                  : IconButton(
                      onPressed: _hasText ? _send : null,
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.send_rounded,
                        size: 18,
                        color: _hasText
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
