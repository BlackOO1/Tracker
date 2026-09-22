// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'category_model.dart';

class CategoryModelAdapter extends TypeAdapter<CategoryModel> {
  @override
  final int typeId = 1;

  @override
  CategoryModel read(BinaryReader reader) {
    final fields = reader.readMap();
    return CategoryModel(
      name: fields[0] as String,
      type: fields[1] as String,
      expectedUSD: fields[2] as double,
      emoji: fields[3] as String,
      paid: fields[4] as bool? ?? false,
      dueDay: fields[5] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, CategoryModel obj) {
    writer.writeMap({
      0: obj.name,
      1: obj.type,
      2: obj.expectedUSD,
      3: obj.emoji,
      4: obj.paid,
      5: obj.dueDay,
    });
  }
}
