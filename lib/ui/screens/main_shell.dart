import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/budget_provider.dart';
import '../../services/auth_service.dart';
import 'overview_screen.dart';
import 'budgets_screen.dart';
import 'history_screen.dart';
import 'analytics_screen.dart';
import '../widgets/add_transaction_sheet.dart';
import '../../constants/app_colors.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    OverviewScreen(),
    BudgetsScreen(),
    HistoryScreen(),
    AnalyticsScreen(),
  ];

  void _openAddTransaction() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTransactionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Planner', style: TextStyle(fontSize: 18)),
        actions: [
          // Month selector
          TextButton.icon(
            onPressed: () => _pickMonth(context, provider),
            icon: const Icon(Icons.calendar_today, size: 16, color: AppColors.teal),
            label: Text(
              '${months[provider.selectedMonth - 1]} ${provider.selectedYear}',
              style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700),
            ),
          ),
          // Currency selector
          TextButton.icon(
            onPressed: () => _pickCurrency(context, provider),
            icon: const Icon(Icons.currency_exchange, size: 16, color: AppColors.lavender),
            label: Text(
              provider.currency,
              style: const TextStyle(color: AppColors.lavender, fontWeight: FontWeight.w700),
            ),
          ),
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout, size: 20, color: AppColors.peach),
            tooltip: 'Logout',
            onPressed: () async {
              await context.read<AuthService>().signOut();
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddTransaction,
        tooltip: 'Add Transaction',
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_rounded), label: 'Budgets'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart_rounded), label: 'Charts'),
        ],
      ),
    );
  }

  void _pickMonth(BuildContext ctx, BudgetProvider provider) {
    showDialog(
      context: ctx,
      builder: (_) => SimpleDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Select Month', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        children: List.generate(12, (i) {
          final months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
          return SimpleDialogOption(
            onPressed: () { provider.setMonth(i+1, provider.selectedYear); Navigator.pop(ctx); },
            child: Text(months[i], style: TextStyle(
              color: provider.selectedMonth == i+1 ? AppColors.teal : AppColors.textSecondary,
              fontWeight: provider.selectedMonth == i+1 ? FontWeight.w700 : FontWeight.normal,
            )),
          );
        }),
      ),
    );
  }

  void _pickCurrency(BuildContext ctx, BudgetProvider provider) {
    const currencies = Currencies.all;
    showDialog(
      context: ctx,
      builder: (_) => SimpleDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Select Currency', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        children: currencies.entries.map((e) {
          final isSelected = provider.currency == e.key;
          return SimpleDialogOption(
            onPressed: () { provider.setCurrency(e.key); Navigator.pop(ctx); },
            child: Row(children: [
              Text('${e.value['symbol']}  ', style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700, fontSize: 16)),
              Expanded(child: Text('${e.key} — ${e.value['name']}', style: TextStyle(
                color: isSelected ? AppColors.teal : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
              ))),
              if (isSelected) const Icon(Icons.check, color: AppColors.teal, size: 18),
            ]),
          );
        }).toList(),
      ),
    );
  }
}
