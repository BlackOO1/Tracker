import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/budget_provider.dart';
import '../../constants/app_colors.dart';

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key});
  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  String _type = 'expense';
  String? _category;
  final _amountCtrl = TextEditingController();
  final _descCtrl   = TextEditingController();
  DateTime _dateTime = DateTime.now();

  final _typeLabels = {
    'expense': 'Expense (−)', 'bill': 'Bill (−)',
    'income': 'Income (+)', 'debt': 'Debt (−)', 'savings': 'Savings (−)',
  };

  final _typeColors = {
    'expense': AppColors.peach, 'bill': AppColors.yellow,
    'income': AppColors.teal, 'debt': AppColors.pink, 'savings': AppColors.mint,
  };

  List<String> _getCats(BudgetProvider p) =>
      p.categoriesByType(_type).map((c) => c.name).toList();

  Future<void> _pickDateTime() async {
    final d = await showDatePicker(
        context: context, initialDate: _dateTime,
        firstDate: DateTime(2020), lastDate: DateTime(2030),
        builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.dark(primary: AppColors.teal, surface: AppColors.surface)),
          child: child!,
        ));
    if (d == null) return;
    final t = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(_dateTime),
        builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.dark(primary: AppColors.teal, surface: AppColors.surface)),
          child: child!,
        ));
    if (t == null) return;
    setState(() => _dateTime = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  Future<void> _save() async {
    final p = context.read<BudgetProvider>();
    final amtLocal = double.tryParse(_amountCtrl.text.replaceAll(',', ''));
    if (amtLocal == null || amtLocal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter a valid amount'), backgroundColor: AppColors.peach));
      return;
    }
    if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select a category'), backgroundColor: AppColors.peach));
      return;
    }
    // Convert from current currency to USD for storage
    final amtUSD = amtLocal / Currencies.rate(p.currency);
    await p.addTransaction(
      type: _type, category: _category!,
      amountUSD: amtUSD, dateTime: _dateTime,
      description: _descCtrl.text.trim().isEmpty ? '$_type record' : _descCtrl.text.trim(),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<BudgetProvider>();
    final cats = _getCats(p);
    if (_category == null || !cats.contains(_category)) {
      _category = cats.isNotEmpty ? cats.first : null;
    }
    final accentColor = _typeColors[_type] ?? AppColors.teal;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Handle
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(
            color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),

        const Text('Add Transaction', style: TextStyle(
            color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 18),

        // Type selector chips
        const Text('TYPE', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.06)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: _typeLabels.entries.map((e) {
            final sel = _type == e.key;
            final c = _typeColors[e.key]!;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() { _type = e.key; _category = null; }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? c.withOpacity(0.2) : AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? c : AppColors.divider, width: sel ? 1.5 : 1),
                  ),
                  child: Text(e.value, style: TextStyle(
                      color: sel ? c : AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
            );
          }).toList()),
        ),
        const SizedBox(height: 14),

        // Date/Time
        const Text('DATE & TIME', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.06)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _pickDateTime,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider)),
            child: Row(children: [
              const Icon(Icons.calendar_today, color: AppColors.textMuted, size: 16),
              const SizedBox(width: 10),
              Text('${_dateTime.day.toString().padLeft(2,'0')}/${_dateTime.month.toString().padLeft(2,'0')}/${_dateTime.year}  ${_dateTime.hour.toString().padLeft(2,'0')}:${_dateTime.minute.toString().padLeft(2,'0')}',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
              const Spacer(),
              const Icon(Icons.edit_calendar, color: AppColors.teal, size: 16),
            ]),
          ),
        ),
        const SizedBox(height: 14),

        // Category
        const Text('CATEGORY', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.06)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _category,
          dropdownColor: AppColors.surface,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          decoration: InputDecoration(filled: true, fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider))),
          items: cats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => setState(() => _category = v),
        ),
        const SizedBox(height: 14),

        // Amount
        Text('AMOUNT (${p.currencySymbol} ${p.currency})', style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.06)),
        const SizedBox(height: 6),
        TextField(
          controller: _amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: '0.00',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            prefixText: '${p.currencySymbol}  ',
            prefixStyle: TextStyle(color: accentColor, fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
        const SizedBox(height: 14),

        // Description
        const Text('DESCRIPTION', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.06)),
        const SizedBox(height: 6),
        TextField(
          controller: _descCtrl,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          decoration: const InputDecoration(hintText: 'e.g. Grocery run, Netflix bill...', hintStyle: TextStyle(color: AppColors.textMuted)),
        ),
        const SizedBox(height: 20),

        // Buttons
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.divider),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          )),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: accentColor,
              foregroundColor: AppColors.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Save Record', style: TextStyle(fontWeight: FontWeight.w800)),
          )),
        ]),
      ])),
    );
  }
}
