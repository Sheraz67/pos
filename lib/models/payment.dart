import 'package:hive/hive.dart';

class Payment extends HiveObject {
  String id;
  String billId;      // بل آئی ڈی
  double amount;      // رقم
  DateTime date;      // تاریخ

  Payment({
    required this.id,
    required this.billId,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'billId': billId,
      'amount': amount,
      'date': date.toIso8601String(),
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      billId: map['billId'],
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date']),
    );
  }
}

class PaymentAdapter extends TypeAdapter<Payment> {
  @override
  final int typeId = 3;

  @override
  Payment read(BinaryReader reader) {
    final map = reader.readMap().cast<String, dynamic>();
    return Payment.fromMap(map);
  }

  @override
  void write(BinaryWriter writer, Payment obj) {
    writer.writeMap(obj.toMap());
  }
}
