// lib/features/agent/presentation/widgets/agent_result_view.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/theme/colors.dart';

class AgentResultView extends StatelessWidget {
  final String output;
  const AgentResultView({super.key, required this.output});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.success.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  size: 16, color: AppColors.success),
              const SizedBox(width: 6),
              Text(
                'Task Completed',
                style: TextStyle(
                  color:      AppColors.success,
                  fontSize:   13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // Copy button
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: output));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Icon(Icons.copy_rounded,
                    size: 16, color: AppColors.textSecondary),
              ),
            ],
          ),

          const SizedBox(height: 10),
          Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),

          // Output text
          Text(
            output,
            style: TextStyle(
              color:    AppColors.textPrimary,
              fontSize: 13,
              height:   1.6,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.05, duration: 400.ms, curve: Curves.easeOut);
  }
}
