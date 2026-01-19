import 'package:hive/hive.dart';
import 'bill_item.dart';

class Bill extends HiveObject {
  String id;
  String customerName;       // گاہک کا نام
  DateTime date;             // تاریخ
  List<BillItem> items;      // آئٹمز
  double subtotal;           // اس بل کا ٹوٹل (items only)
  double previousRemaining;  // پچھلا بقایا (from linked bill)
  double discount;           // رعایت
  double total;              // کل رقم (subtotal + previousRemaining - discount)
  double received;           // وصول شدہ
  double remaining;          // بقایا
  String? linkedBillId;      // پچھلے بل کی آئی ڈی (previous bill)
  String? nextBillId;        // اگلے بل کی آئی ڈی (next bill in chain)
  String status;             // pending / paid / transferred (منتقل)

  Bill({
    required this.id,
    required this.customerName,
    required this.date,
    required this.items,
    required this.subtotal,
    this.previousRemaining = 0,
    required this.discount,
    required this.total,
    required this.received,
    required this.remaining,
    this.linkedBillId,
    this.nextBillId,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'date': date.toIso8601String(),
      'items': items.map((e) => e.toMap()).toList(),
      'subtotal': subtotal,
      'previousRemaining': previousRemaining,
      'discount': discount,
      'total': total,
      'received': received,
      'remaining': remaining,
      'linkedBillId': linkedBillId,
      'nextBillId': nextBillId,
      'status': status,
    };
  }

  factory Bill.fromMap(Map<String, dynamic> map) {
    return Bill(
      id: map['id'],
      customerName: map['customerName'],
      date: DateTime.parse(map['date']),
      items: (map['items'] as List)
          .map((e) => BillItem.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      subtotal: (map['subtotal'] as num).toDouble(),
      previousRemaining: (map['previousRemaining'] as num?)?.toDouble() ?? 0,
      discount: (map['discount'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      received: (map['received'] as num).toDouble(),
      remaining: (map['remaining'] as num).toDouble(),
      linkedBillId: map['linkedBillId'],
      nextBillId: map['nextBillId'],
      status: map['status'],
    );
  }

  // Check if this bill is part of a chain
  bool get isInChain => linkedBillId != null || nextBillId != null;

  // Check if this bill has been transferred to next bill
  bool get isTransferred => status == 'transferred';
}

class BillAdapter extends TypeAdapter<Bill> {
  @override
  final int typeId = 2;

  @override
  Bill read(BinaryReader reader) {
    final map = reader.readMap().cast<String, dynamic>();
    return Bill.fromMap(map);
  }

  @override
  void write(BinaryWriter writer, Bill obj) {
    writer.writeMap(obj.toMap());
  }
}
