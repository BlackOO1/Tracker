import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../state/budget_provider.dart';
import '../../constants/app_colors.dart';
import '../widgets/kpi_card.dart';
import '../widgets/section_card.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<BudgetProvider>();
    final fmt = (double usd) => Currencies.format(usd, p.currency);
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMM d, yyyy  •  HH:mm:ss').format(now);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Live date/time header
        Text(dateStr, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        const SizedBox(height: 12),

        // Hero: Amount Left To Spend
        _HeroCard(p: p, fmt: fmt),
        const SizedBox(height: 12),

        // 4 KPI cards
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: [
            KpiCard(label: 'INCOME',   color: AppColors.teal,    actual: fmt(p.totalIncomeActualUSD),   expected: fmt(p.totalIncomeExpectedUSD)),
            KpiCard(label: 'EXPENSES', color: AppColors.peach,   actual: fmt(p.totalExpenseActualUSD + p.totalBillActualUSD),  expected: fmt(p.totalExpenseExpectedUSD + p.totalBillExpectedUSD)),
            KpiCard(label: 'DEBT',     color: AppColors.pink,    actual: fmt(p.totalDebtActualUSD),     expected: fmt(p.totalDebtExpectedUSD)),
            KpiCard(label: 'SAVINGS',  color: AppColors.mint,    actual: fmt(p.totalSavingsActualUSD),  expected: fmt(p.totalSavingsExpectedUSD)),
          ],
        ),
        const SizedBox(height: 12),

        // Recent transactions
        SectionCard(
          title: 'RECENT ACTIVITY',
          trailing: TextButton(
            onPressed: () {},
            child: const Text('See All', style: TextStyle(color: AppColors.teal, fontSize: 12)),
          ),
          child: Column(
            children: p.monthlyTransactions.take(5).map((tx) => _TxRow(tx: tx, fmt: fmt)).toList(),
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.p, required this.fmt});
  final BudgetProvider p;
  final String Function(double) fmt;

  @override
  Widget build(BuildContext context) {
    final pct = p.budgetUsedPercent;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.surface, Color(0xFF2E3348)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('AMOUNT LEFT TO SPEND',
                style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.06)),
            const SizedBox(height: 4),
            Text(fmt(p.amountLeftUSD),
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 30, fontWeight: FontWeight.w800)),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Text('Rollover', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
            Text('+${fmt(p.rolloverUSD)}',
                style: const TextStyle(color: AppColors.teal, fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: p.isOnTrack ? AppColors.teal.withOpacity(0.15) : AppColors.peach.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: p.isOnTrack ? AppColors.teal.withOpacity(0.4) : AppColors.peach.withOpacity(0.4)),
              ),
              child: Text(
                p.isOnTrack ? '✦ On Track' : '⚠ Over Budget',
                style: TextStyle(color: p.isOnTrack ? AppColors.teal : AppColors.peach, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ]),
        ]),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Budget Used', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
          Text('${pct.toStringAsFixed(1)}%', style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct / 100,
            minHeight: 6,
            backgroundColor: AppColors.background,
            valueColor: AlwaysStoppedAnimation<Color>(pct > 90 ? AppColors.peach : AppColors.teal),
          ),
        ),
      ]),
    );
  }
}

class _TxRow extends StatelessWidget {
  const _TxRow({required this.tx, required this.fmt});
  final tx;
  final String Function(double) fmt;

  @override
  Widget build(BuildContext context) {
    final isIn = tx.type == 'income';
    final color = isIn ? AppColors.teal : AppColors.peach;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(isIn ? '+' : '−', style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tx.category, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
          Text('${tx.description}  •  ${DateFormat('MMM d  HH:mm').format(tx.dateTime)}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
        ])),
        Text('${isIn ? '+' : '−'}${fmt(tx.amountUSD)}',
            style: TextStyle(color: isIn ? AppColors.teal : AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
      ]),
    );
  }
}
