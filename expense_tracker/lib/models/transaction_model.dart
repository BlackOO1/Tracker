import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

/// Transaction types matching Sheet 2 of Expense Tracker.xlsx
enum TransactionType { income, expense, bill, debt, savings }

@HiveType(typeId: 0)
class TransactionModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late DateTime dateTime;

  @HiveField(2)
  late String type; // 'income' | 'expense' | 'bill' | 'debt' | 'savings'

  @HiveField(3)
  late String category;

  @HiveField(4)
  late double amountUSD; // Always stored in USD; converted on display

  @HiveField(5)
  late String description;

  TransactionModel({
    required this.id,
    required this.dateTime,
    required this.type,
    required this.category,
    required this.amountUSD,
    required this.description,
  });

  bool get isIncome => type == 'income';

  double convertedAmount(double rate) => amountUSD * rate;

  @override
  String toString() => 'Transaction($type, $category, $amountUSD USD, $dateTime)';
}
