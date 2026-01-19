import 'package:hive/hive.dart';

class Item extends HiveObject {
  String id;
  String name;      // نام (Urdu)
  String unit;      // یونٹ (فٹ، کلو، عدد)
  String serialNo;  // سیریل نمبر

  Item({
    required this.id,
    required this.name,
    required this.unit,
    required this.serialNo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'unit': unit,
      'serialNo': serialNo,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'],
      name: map['name'],
      unit: map['unit'],
      serialNo: map['serialNo'],
    );
  }
}

class ItemAdapter extends TypeAdapter<Item> {
  @override
  final int typeId = 0;

  @override
  Item read(BinaryReader reader) {
    final map = reader.readMap().cast<String, dynamic>();
    return Item.fromMap(map);
  }

  @override
  void write(BinaryWriter writer, Item obj) {
    writer.writeMap(obj.toMap());
  }
}
