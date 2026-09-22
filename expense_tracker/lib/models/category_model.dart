import 'package:hive/hive.dart';

part 'category_model.g.dart';

@HiveType(typeId: 1)
class CategoryModel extends HiveObject {
  @HiveField(0)
  late String name;

  @HiveField(1)
  late String type; // 'expense' | 'bill' | 'income' | 'debt' | 'savings'

  @HiveField(2)
  late double expectedUSD;

  @HiveField(3)
  late String emoji;

  @HiveField(4)
  late bool paid; // for bills and debt

  @HiveField(5)
  late int? dueDay; // day of month when bill/debt is due

  CategoryModel({
    required this.name,
    required this.type,
    required this.expectedUSD,
    required this.emoji,
    this.paid = false,
    this.dueDay,
  });
}
