import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';

class DatabaseService {
  static const String itemsBoxName = 'items';
  static const String billsBoxName = 'bills';
  static const String paymentsBoxName = 'payments';

  static late Box<Item> itemsBox;
  static late Box<Bill> billsBox;
  static late Box<Payment> paymentsBox;

  // Get persistent storage path that survives app uninstall
  static Future<String> _getPersistentPath() async {
    if (kIsWeb) {
      // Web uses IndexedDB, no file path needed
      return '';
    }

    // For Android/iOS, use external storage directory
    // This persists even after app uninstall
    Directory? directory;

    if (Platform.isAndroid) {
      // Try to get external storage first (persists after uninstall)
      directory = await getExternalStorageDirectory();
      if (directory != null) {
        // Go up to root external storage and create app folder
        // /storage/emulated/0/Android/data/com.example.pos_app/files
        // We want: /storage/emulated/0/POS_MianHardware
        final parts = directory.path.split('/');
        final androidIndex = parts.indexOf('Android');
        if (androidIndex > 0) {
          final basePath = parts.sublist(0, androidIndex).join('/');
          directory = Directory('$basePath/POS_MianHardware');
        }
      }
    } else if (Platform.isIOS) {
      // iOS: Use documents directory (backed up by iCloud)
      directory = await getApplicationDocumentsDirectory();
      directory = Directory('${directory.path}/POS_MianHardware');
    }

    // Fallback to app documents directory
    directory ??= await getApplicationDocumentsDirectory();

    // Create directory if it doesn't exist
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory.path;
  }

  // Initialize Hive and open boxes
  static Future<void> init() async {
    // Get persistent storage path
    final dbPath = await _getPersistentPath();

    if (kIsWeb) {
      await Hive.initFlutter();
    } else {
      // Initialize Hive with custom path for persistence
      Hive.init(dbPath);
    }

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ItemAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(BillItemAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(BillAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(PaymentAdapter());
    }

    // Open boxes
    itemsBox = await Hive.openBox<Item>(itemsBoxName);
    billsBox = await Hive.openBox<Bill>(billsBoxName);
    paymentsBox = await Hive.openBox<Payment>(paymentsBoxName);

    // Add items if empty or reset if old dummy items exist
    if (itemsBox.isEmpty) {
      await _addDummyItems();
    } else {
      // Check if old dummy items exist (IDs 1-10) and reset to new items
      if (itemsBox.get('1') != null || itemsBox.get('101') == null) {
        await resetItems();
      }
    }
  }

  // Add real items
  static Future<void> _addDummyItems() async {
    final items = [
      // ہینڈل (Handles)
      Item(id: '101', name: 'میل چینل ہینڈل', unit: 'عدد', serialNo: '101'),
      Item(id: '102', name: 'سٹینلیس ہینڈل 303', unit: 'عدد', serialNo: '102'),
      Item(id: '103', name: 'سٹینلیس ہینڈل SA', unit: 'عدد', serialNo: '103'),
      Item(id: '104', name: 'لوہے کی ہینڈل', unit: 'عدد', serialNo: '104'),
      Item(id: '105', name: 'شاہ ہینڈر', unit: 'عدد', serialNo: '105'),
      Item(id: '106', name: 'سیمی ڈراپ', unit: 'عدد', serialNo: '106'),
      Item(id: '107', name: 'سائڈ ہینڈل', unit: 'عدد', serialNo: '107'),
      Item(id: '108', name: 'شیشم ہینڈل', unit: 'عدد', serialNo: '108'),
      Item(id: '109', name: 'H ہینڈل', unit: 'عدد', serialNo: '109'),
      Item(id: '110', name: 'گول ہینڈل تیر', unit: 'عدد', serialNo: '110'),
      Item(id: '111', name: 'برش ہینڈل', unit: 'عدد', serialNo: '111'),

      // موٹر (Motors)
      Item(id: '112', name: 'موٹر 8 ایل', unit: 'عدد', serialNo: '112'),
      Item(id: '113', name: 'موٹر 9 ایل', unit: 'عدد', serialNo: '113'),
      Item(id: '114', name: 'موٹر 10 ایل', unit: 'عدد', serialNo: '114'),
      Item(id: '115', name: 'موٹر 32', unit: 'عدد', serialNo: '115'),

      // دیگر آئٹمز (Other Items)
      Item(id: '116', name: 'ایل پی واشر', unit: 'عدد', serialNo: '116'),
      Item(id: '117', name: 'موٹر 8/8 کھٹکا', unit: 'عدد', serialNo: '117'),
      Item(id: '118', name: 'نیل خاص', unit: 'کلو', serialNo: '118'),
      Item(id: '119', name: 'ڈبل روڈ', unit: 'فٹ', serialNo: '119'),
      Item(id: '120', name: 'نش پروفائل', unit: 'فٹ', serialNo: '120'),
      Item(id: '121', name: 'نش تھری ٹریک', unit: 'فٹ', serialNo: '121'),
      Item(id: '122', name: 'سٹی 5 انچ', unit: 'عدد', serialNo: '122'),
      Item(id: '123', name: 'سٹی 6 انچ', unit: 'عدد', serialNo: '123'),
      Item(id: '124', name: 'سوکا نر', unit: 'عدد', serialNo: '124'),
      Item(id: '125', name: 'سوکا انر', unit: 'عدد', serialNo: '125'),
      Item(id: '126', name: '15 ایل ویل', unit: 'عدد', serialNo: '126'),
      Item(id: '127', name: '9 پہیہ', unit: 'عدد', serialNo: '127'),
      Item(id: '128', name: 'منی والش', unit: 'عدد', serialNo: '128'),
    ];

    for (var item in items) {
      await itemsBox.put(item.id, item);
    }
  }

  // Reset items (clear and reload)
  static Future<void> resetItems() async {
    await itemsBox.clear();
    await _addDummyItems();
  }

  // ===== ITEMS =====
  static List<Item> getAllItems() {
    return itemsBox.values.toList();
  }

  static Item? getItem(String id) {
    return itemsBox.get(id);
  }

  static Future<void> saveItem(Item item) async {
    await itemsBox.put(item.id, item);
  }

  static Future<void> deleteItem(String id) async {
    await itemsBox.delete(id);
  }

  // Search items by name or serial number
  static List<Item> searchItems(String query) {
    if (query.isEmpty) return getAllItems();
    final lowerQuery = query.toLowerCase();
    return itemsBox.values.where((item) {
      return item.name.toLowerCase().contains(lowerQuery) ||
          item.serialNo.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // ===== BILLS =====
  static List<Bill> getAllBills() {
    final bills = billsBox.values.toList();
    bills.sort((a, b) => b.date.compareTo(a.date)); // Newest first
    return bills;
  }

  static Bill? getBill(String id) {
    return billsBox.get(id);
  }

  static Future<void> saveBill(Bill bill) async {
    await billsBox.put(bill.id, bill);
  }

  static Future<void> deleteBill(String id) async {
    await billsBox.delete(id);
    // Also delete associated payments
    final payments = paymentsBox.values.where((p) => p.billId == id).toList();
    for (var payment in payments) {
      await paymentsBox.delete(payment.id);
    }
  }

  // Search bills by customer name
  static List<Bill> searchBillsByCustomer(String customerName) {
    if (customerName.isEmpty) return getAllBills();
    final lowerQuery = customerName.toLowerCase();
    final bills = billsBox.values.where((bill) {
      return bill.customerName.toLowerCase().contains(lowerQuery);
    }).toList();
    bills.sort((a, b) => b.date.compareTo(a.date));
    return bills;
  }

  // Search bills by date range
  static List<Bill> searchBillsByDate(DateTime start, DateTime end) {
    final bills = billsBox.values.where((bill) {
      return bill.date.isAfter(start.subtract(const Duration(days: 1))) &&
          bill.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
    bills.sort((a, b) => b.date.compareTo(a.date));
    return bills;
  }

  // Get bills with pending payment
  static List<Bill> getPendingBills() {
    final bills = billsBox.values.where((bill) {
      return bill.status == 'pending' && bill.remaining > 0;
    }).toList();
    bills.sort((a, b) => b.date.compareTo(a.date));
    return bills;
  }

  // ===== PAYMENTS =====
  static List<Payment> getPaymentsForBill(String billId) {
    final payments =
        paymentsBox.values.where((p) => p.billId == billId).toList();
    payments.sort((a, b) => b.date.compareTo(a.date));
    return payments;
  }

  static Future<void> savePayment(Payment payment) async {
    await paymentsBox.put(payment.id, payment);

    // Update bill's received and remaining amounts
    final bill = billsBox.get(payment.billId);
    if (bill != null) {
      final allPayments = getPaymentsForBill(payment.billId);
      final totalReceived =
          allPayments.fold(0.0, (sum, p) => sum + p.amount);
      bill.received = totalReceived;
      bill.remaining = bill.total - totalReceived;
      bill.status = bill.remaining <= 0 ? 'paid' : 'pending';
      await billsBox.put(bill.id, bill);
    }
  }

  static Future<void> deletePayment(String id) async {
    final payment = paymentsBox.get(id);
    if (payment != null) {
      final billId = payment.billId;
      await paymentsBox.delete(id);

      // Update bill's received and remaining amounts
      final bill = billsBox.get(billId);
      if (bill != null) {
        final allPayments = getPaymentsForBill(billId);
        final totalReceived =
            allPayments.fold(0.0, (sum, p) => sum + p.amount);
        bill.received = totalReceived;
        bill.remaining = bill.total - totalReceived;
        bill.status = bill.remaining <= 0 ? 'paid' : 'pending';
        await billsBox.put(bill.id, bill);
      }
    }
  }
}
