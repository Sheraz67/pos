import 'package:hive/hive.dart';

class BillItem extends HiveObject {
  String id;
  String itemId;    // Reference to Item
  String itemName;  // Stored for display
  String unit;      // یونٹ
  double quantity;  // مقدار
  double price;     // قیمت
  double amount;    // رقم (quantity * price)

  BillItem({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.unit,
    required this.quantity,
    required this.price,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemId': itemId,
      'itemName': itemName,
      'unit': unit,
      'quantity': quantity,
      'price': price,
      'amount': amount,
    };
  }

  factory BillItem.fromMap(Map<String, dynamic> map) {
    return BillItem(
      id: map['id'],
      itemId: map['itemId'],
      itemName: map['itemName'],
      unit: map['unit'],
      quantity: (map['quantity'] as num).toDouble(),
      price: (map['price'] as num).toDouble(),
      amount: (map['amount'] as num).toDouble(),
    );
  }
}

class BillItemAdapter extends TypeAdapter<BillItem> {
  @override
  final int typeId = 1;

  @override
  BillItem read(BinaryReader reader) {
    final map = reader.readMap().cast<String, dynamic>();
    return BillItem.fromMap(map);
  }

  @override
  void write(BinaryWriter writer, BillItem obj) {
    writer.writeMap(obj.toMap());
  }
}
