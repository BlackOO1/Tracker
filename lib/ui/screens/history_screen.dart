import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../state/budget_provider.dart';
import '../../constants/app_colors.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _query = '';
  String _typeFilter = 'all';

  static const _typeColors = {
    'income' : AppColors.teal,
    'expense': AppColors.peach,
    'bill'   : AppColors.yellow,
    'debt'   : AppColors.pink,
    'savings': AppColors.mint,
  };

  @override
  Widget build(BuildContext context) {
    final p = context.watch<BudgetProvider>();
    String fmt(double usd) => Currencies.format(usd, p.currency);

    final txns = p.monthlyTransactions.where((tx) {
      final qMatch = tx.category.toLowerCase().contains(_query.toLowerCase()) ||
          tx.description.toLowerCase().contains(_query.toLowerCase());
      final tMatch = _typeFilter == 'all' || tx.type == _typeFilter;
      return qMatch && tMatch;
    }).toList();

    return Column(children: [
      // Search bar
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: TextField(
          onChanged: (v) => setState(() => _query = v),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Search transactions...',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
            suffixIcon: _query.isNotEmpty
                ? IconButton(icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 18),
                    onPressed: () => setState(() => _query = ''))
                : null,
          ),
        ),
      ),

      // Type filter chips
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(children: [
          for (final t in ['all', 'income', 'expense', 'bill', 'debt', 'savings'])
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                selected: _typeFilter == t,
                label: Text(t == 'all' ? 'All' : t[0].toUpperCase() + t.substring(1)),
                onSelected: (_) => setState(() => _typeFilter = t),
                selectedColor: AppColors.teal.withValues(alpha: 0.25),
                backgroundColor: AppColors.surface,
                side: BorderSide(color: _typeFilter == t ? AppColors.teal : AppColors.divider),
                labelStyle: TextStyle(
                  color: _typeFilter == t ? AppColors.teal : AppColors.textMuted,
                  fontSize: 11, fontWeight: FontWeight.w600,
                ),
              ),
            ),
          
          const SizedBox(width: 8),
          // Clear All Button
          if (p.allTransactions.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.surfaceAlt,
                    title: const Text('Clear All', style: TextStyle(color: Colors.white)),
                    content: const Text('Are you sure you want to delete all transactions? This cannot be undone.', style: TextStyle(color: AppColors.textMuted)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.peach),
                        onPressed: () {
                          p.clearAllTransactions();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Delete All', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.delete_sweep, color: AppColors.peach, size: 16),
              label: const Text('Clear All', style: TextStyle(color: AppColors.peach, fontSize: 11, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ]),
      ),
      const SizedBox(height: 8),

      // Transactions list
      Expanded(child: txns.isEmpty
          ? const Center(child: Text('No transactions found', style: TextStyle(color: AppColors.textMuted)))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              itemCount: txns.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (_, i) {
                final tx = txns[i];
                final isIn = tx.type == 'income';
                final color = _typeColors[tx.type] ?? AppColors.textMuted;
                return Dismissible(
                  key: Key(tx.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: AppColors.peach.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.delete_outline, color: AppColors.peach),
                  ),
                  onDismissed: (_) => p.deleteTransaction(tx.id),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(children: [
                      Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                        child: Center(child: Text(isIn ? '+' : '−',
                            style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text(tx.category, style: const TextStyle(
                              color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(width: 6),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                            child: Text(tx.type, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700))),
                        ]),
                        const SizedBox(height: 2),
                        Text(tx.description, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        const SizedBox(height: 2),
                        Text('🕐 ${DateFormat('EEEE, MMM d yyyy  HH:mm').format(tx.dateTime)}',
                            style: const TextStyle(color: AppColors.lavender, fontSize: 10)),
                      ])),
                      Text('${isIn ? '+' : '−'}${fmt(tx.amountUSD)}',
                          style: TextStyle(color: isIn ? AppColors.teal : AppColors.textPrimary,
                              fontWeight: FontWeight.w800, fontSize: 14)),
                    ]),
                  ),
                );
              },
            )),
    ]);
  }
}
