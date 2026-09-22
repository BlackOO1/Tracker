import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class KpiCard extends StatelessWidget {
  const KpiCard({super.key, required this.label, required this.color, required this.actual, required this.expected});
  final String label, actual, expected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.05)),
        ]),
        const SizedBox(height: 6),
        Text(actual, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text('Exp: $expected', style: TextStyle(color: color, fontSize: 10)),
      ]),
    );
  }
}
