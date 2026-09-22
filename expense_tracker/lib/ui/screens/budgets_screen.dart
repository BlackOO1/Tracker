import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/budget_provider.dart';
import '../../constants/app_colors.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});
  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _tabTypes = ['expense', 'bill', 'income', 'debt', 'savings'];
  final _tabLabels = ['Expenses', 'Bills', 'Income', 'Debt', 'Savings'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<BudgetProvider>();
    String fmt(double usd) => Currencies.format(usd, p.currency);

    return Column(children: [
      Container(
        color: AppColors.surface,
        child: TabBar(
          controller: _tabs,
          isScrollable: true,
          indicatorColor: AppColors.teal,
          labelColor: AppColors.teal,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          tabs: _tabLabels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      Expanded(child: TabBarView(
        controller: _tabs,
        children: List.generate(5, (tabIdx) {
          final type = _tabTypes[tabIdx];
          final cats = p.categoriesByType(type);
          if (cats.isEmpty) {
            return const Center(child: Text('No categories', style: TextStyle(color: AppColors.textMuted)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(14),
            itemCount: cats.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final cat = cats[i];
              final actualUSD = p.actualForCategory(cat.name, cat.type);
              final pct = cat.expectedUSD > 0 ? (actualUSD / cat.expectedUSD).clamp(0.0, 1.0) : 0.0;
              final over = actualUSD > cat.expectedUSD && cat.expectedUSD > 0;
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(cat.emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(cat.name, style: const TextStyle(
                        color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14))),
                    if (cat.dueDay != null)
                      Text('Due: ${cat.dueDay}th', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    if (type == 'bill' || type == 'debt' || type == 'savings')
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: GestureDetector(
                          onTap: () => p.togglePaid(cat.name),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: cat.paid ? AppColors.teal.withValues(alpha: 0.15) : AppColors.divider.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: cat.paid ? AppColors.teal.withValues(alpha: 0.4) : AppColors.divider),
                            ),
                            child: Text(cat.paid ? '✓ Paid' : 'Mark Paid',
                                style: TextStyle(color: cat.paid ? AppColors.teal : AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Actual: ${fmt(actualUSD)}', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                    Text('Budget: ${fmt(cat.expectedUSD)}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ]),
                  const SizedBox(height: 6),
                  ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 5,
                    backgroundColor: AppColors.background,
                    valueColor: AlwaysStoppedAnimation<Color>(over ? AppColors.peach : AppColors.teal),
                  )),
                ]),
              );
            },
          );
        }),
      )),
    ]);
  }
}
