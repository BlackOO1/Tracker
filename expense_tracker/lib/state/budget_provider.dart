import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../constants/app_colors.dart';

class BudgetProvider extends ChangeNotifier {
  // ─── State ──────────────────────────────────────────────────────────────────
  late Box<TransactionModel> _txBox;
  late Box<CategoryModel> _catBox;
  late Box _settings;

  String _currency = 'USD';
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  double _rolloverUSD = 250.0;

  // ─── Getters ────────────────────────────────────────────────────────────────
  String get currency => _currency;
  int get selectedMonth => _selectedMonth;
  int get selectedYear => _selectedYear;
  double get rolloverUSD => _rolloverUSD;
  double get exchangeRate => Currencies.rate(_currency);
  String get currencySymbol => Currencies.symbol(_currency);

  List<TransactionModel> get allTransactions =>
      _txBox.values.toList()..sort((a, b) => b.dateTime.compareTo(a.dateTime));

  List<TransactionModel> get monthlyTransactions => allTransactions.where((tx) =>
      tx.dateTime.month == _selectedMonth && tx.dateTime.year == _selectedYear).toList();

  List<CategoryModel> get allCategories => _catBox.values.toList();
  List<CategoryModel> categoriesByType(String type) =>
      allCategories.where((c) => c.type == type).toList();

  // ─── Calculated totals (USD) ─────────────────────────────────────────────────
  double _sumActual(String type) {
    return monthlyTransactions.where((tx) => tx.type == type).fold(0, (s, tx) => s + tx.amountUSD);
  }

  double get totalIncomeActualUSD  => _sumActual('income');
  double get totalExpenseActualUSD => _sumActual('expense');
  double get totalBillActualUSD    => _sumActual('bill');
  double get totalDebtActualUSD    => _sumActual('debt');
  double get totalSavingsActualUSD => _sumActual('savings');

  double _sumExpected(String type) =>
      categoriesByType(type).fold(0, (s, c) => s + c.expectedUSD);

  double get totalIncomeExpectedUSD  => _sumExpected('income');
  double get totalExpenseExpectedUSD => _sumExpected('expense');
  double get totalBillExpectedUSD    => _sumExpected('bill');
  double get totalDebtExpectedUSD    => _sumExpected('debt');
  double get totalSavingsExpectedUSD => _sumExpected('savings');

  double get totalOutgoingsUSD =>
      totalExpenseActualUSD + totalBillActualUSD + totalDebtActualUSD + totalSavingsActualUSD;

  double get amountLeftUSD =>
      _rolloverUSD + totalIncomeActualUSD - totalOutgoingsUSD;

  bool get isOnTrack =>
      totalExpenseActualUSD + totalBillActualUSD <=
      totalExpenseExpectedUSD + totalBillExpectedUSD;

  double get budgetUsedPercent {
    final inc = totalIncomeActualUSD + _rolloverUSD;
    if (inc <= 0) return 0;
    return (totalOutgoingsUSD / inc * 100).clamp(0, 100);
  }

  // ─── Actual per category ────────────────────────────────────────────────────
  double actualForCategory(String name, String type) {
    return monthlyTransactions
        .where((tx) => tx.type == type && tx.category == name)
        .fold(0, (s, tx) => s + tx.amountUSD);
  }

  // ─── 6-month trend ──────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get sixMonthTrend {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final m = DateTime(now.year, now.month - 5 + i, 1);
      final txs = allTransactions.where(
          (tx) => tx.dateTime.month == m.month && tx.dateTime.year == m.year);
      final exp = txs.where((t) => t.type=='expense'||t.type=='bill').fold(0.0,(s,t)=>s+t.amountUSD);
      final sav = txs.where((t) => t.type=='savings').fold(0.0,(s,t)=>s+t.amountUSD);
      return {'month': m, 'expenses': exp, 'savings': sav};
    });
  }

  // ─── Category spending for charts ───────────────────────────────────────────
  List<Map<String, dynamic>> get topSpendingCategories {
    final Map<String, double> totals = {};
    for (final tx in monthlyTransactions) {
      if (tx.type == 'expense' || tx.type == 'bill') {
        totals[tx.category] = (totals[tx.category] ?? 0) + tx.amountUSD;
      }
    }
    final sorted = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => {'name': e.key, 'amount': e.value}).toList();
  }

  // ─── Init ───────────────────────────────────────────────────────────────────
  Future<void> init() async {
    _txBox  = Hive.box<TransactionModel>('transactions');
    _catBox = Hive.box<CategoryModel>('categories');
    _settings = Hive.box('settings');

    _currency = _settings.get('currency', defaultValue: 'USD');
    _rolloverUSD = _settings.get('rollover', defaultValue: 250.0);

    if (_catBox.isEmpty) _seedDefaultCategories();
    if (_txBox.isEmpty)  _seedSampleTransactions();

    notifyListeners();
  }

  // ─── Actions ─────────────────────────────────────────────────────────────────
  void setCurrency(String code) {
    _currency = code;
    _settings.put('currency', code);
    notifyListeners();
  }

  void setMonth(int month, int year) {
    _selectedMonth = month;
    _selectedYear  = year;
    notifyListeners();
  }

  void setRollover(double amount) {
    _rolloverUSD = amount;
    _settings.put('rollover', amount);
    notifyListeners();
  }

  Future<void> addTransaction({
    required String type,
    required String category,
    required double amountUSD,
    required DateTime dateTime,
    required String description,
  }) async {
    final tx = TransactionModel(
      id: const Uuid().v4(),
      dateTime: dateTime,
      type: type,
      category: category,
      amountUSD: amountUSD,
      description: description,
    );
    await _txBox.put(tx.id, tx);
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    await _txBox.delete(id);
    notifyListeners();
  }

  Future<void> updateCategoryExpected(String key, double newAmountUSD) async {
    final cat = _catBox.get(key);
    if (cat != null) {
      cat.expectedUSD = newAmountUSD;
      await cat.save();
      notifyListeners();
    }
  }

  Future<void> togglePaid(String key) async {
    final cat = _catBox.get(key);
    if (cat != null) {
      cat.paid = !cat.paid;
      await cat.save();
      notifyListeners();
    }
  }

  // ─── Seed data (Sheet 2 defaults) ───────────────────────────────────────────
  void _seedDefaultCategories() {
    final defaults = [
      // Expenses
      CategoryModel(name:'Food',           type:'expense',  expectedUSD:600, emoji:'🍔'),
      CategoryModel(name:'Social Life',    type:'expense',  expectedUSD:250, emoji:'🎉'),
      CategoryModel(name:'Transportation', type:'expense',  expectedUSD:200, emoji:'🚗'),
      CategoryModel(name:'Household',      type:'expense',  expectedUSD:150, emoji:'🏠'),
      CategoryModel(name:'Apparel',        type:'expense',  expectedUSD:100, emoji:'👕'),
      CategoryModel(name:'Beauty',         type:'expense',  expectedUSD:80,  emoji:'💄'),
      CategoryModel(name:'Health',         type:'expense',  expectedUSD:120, emoji:'💊'),
      CategoryModel(name:'Education',      type:'expense',  expectedUSD:150, emoji:'📚'),
      CategoryModel(name:'Gift',           type:'expense',  expectedUSD:50,  emoji:'🎁'),
      CategoryModel(name:'Pet',            type:'expense',  expectedUSD:100, emoji:'🐾'),
      CategoryModel(name:'Self-development',type:'expense', expectedUSD:100, emoji:'🌱'),
      // Bills
      CategoryModel(name:'Internet',       type:'bill', expectedUSD:70,  emoji:'🌐', dueDay:8),
      CategoryModel(name:'Electricity',    type:'bill', expectedUSD:120, emoji:'⚡', dueDay:15),
      CategoryModel(name:'Water',          type:'bill', expectedUSD:45,  emoji:'💧', dueDay:20),
      CategoryModel(name:'Mobile',         type:'bill', expectedUSD:55,  emoji:'📱', dueDay:12),
      CategoryModel(name:'Life Insurance', type:'bill', expectedUSD:100, emoji:'🛡️', dueDay:28),
      CategoryModel(name:'Health Insurance',type:'bill',expectedUSD:150, emoji:'🏥', dueDay:28),
      CategoryModel(name:'City Garbage',   type:'bill', expectedUSD:30,  emoji:'🗑️', dueDay:5),
      CategoryModel(name:'Gas',            type:'bill', expectedUSD:40,  emoji:'🔥', dueDay:18),
      // Income
      CategoryModel(name:'Paycheck',       type:'income', expectedUSD:3500, emoji:'💼'),
      CategoryModel(name:'Business',       type:'income', expectedUSD:500,  emoji:'📈'),
      CategoryModel(name:'Side Hustle',    type:'income', expectedUSD:200,  emoji:'💻'),
      CategoryModel(name:'Dividends',      type:'income', expectedUSD:100,  emoji:'🪙'),
      CategoryModel(name:'Interest Income',type:'income', expectedUSD:20,   emoji:'🏦'),
      CategoryModel(name:'Commission',     type:'income', expectedUSD:100,  emoji:'🎯'),
      // Debt
      CategoryModel(name:'Student Loans',  type:'debt', expectedUSD:200, emoji:'🎓', dueDay:15),
      CategoryModel(name:'Mortgage',       type:'debt', expectedUSD:0,   emoji:'🏡', dueDay:1),
      CategoryModel(name:'Car Payments',   type:'debt', expectedUSD:250, emoji:'🚙', dueDay:22),
      // Savings
      CategoryModel(name:'Travel Fund',    type:'savings', expectedUSD:150, emoji:'✈️'),
      CategoryModel(name:'Wedding Fund',   type:'savings', expectedUSD:200, emoji:'💍'),
      CategoryModel(name:'Car Fund',       type:'savings', expectedUSD:100, emoji:'🚘'),
      CategoryModel(name:'Stocks',         type:'savings', expectedUSD:100, emoji:'📊'),
      CategoryModel(name:'Mutual Funds',   type:'savings', expectedUSD:50,  emoji:'📑'),
      CategoryModel(name:'Cryptocurrency', type:'savings', expectedUSD:50,  emoji:'₿'),
    ];
    for (final c in defaults) { _catBox.put(c.name, c); }
  }

  void _seedSampleTransactions() {
    final now = DateTime.now();
    final samples = [
      ('income','Paycheck',1750.0,'Bi-weekly salary', DateTime(now.year,now.month,10,8,0)),
      ('income','Side Hustle',120.0,'Freelance design', DateTime(now.year,now.month,3,11,0)),
      ('expense','Food',64.5,'Weekly groceries', DateTime(now.year,now.month,18,14,30)),
      ('expense','Social Life',42.0,'Dinner with friends', DateTime(now.year,now.month,17,20,15)),
      ('expense','Transportation',35.0,'Cab rides', DateTime(now.year,now.month,8,12,30)),
      ('bill','Electricity',115.0,'Monthly power bill', DateTime(now.year,now.month,15,9,0)),
      ('bill','Mobile',55.0,'Monthly mobile plan', DateTime(now.year,now.month,5,9,0)),
      ('debt','Student Loans',200.0,'Monthly instalment', DateTime(now.year,now.month,15,10,0)),
      ('savings','Travel Fund',150.0,'Monthly savings transfer', DateTime(now.year,now.month,2,10,0)),
    ];
    for (final s in samples) {
      final tx = TransactionModel(
        id: const Uuid().v4(),
        dateTime: s.$5,
        type: s.$1,
        category: s.$2,
        amountUSD: s.$3,
        description: s.$4,
      );
      _txBox.put(tx.id, tx);
    }
  }
}
