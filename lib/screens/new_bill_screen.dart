import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../widgets/item_row.dart';
import '../widgets/bill_summary.dart';
import 'bills_screen.dart';

class NewBillScreen extends StatefulWidget {
  final Bill? linkedBill; // For linking to previous bill

  const NewBillScreen({super.key, this.linkedBill});

  @override
  State<NewBillScreen> createState() => _NewBillScreenState();
}

class _NewBillScreenState extends State<NewBillScreen> {
  final _customerController = TextEditingController();
  final _phoneController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _receivedController = TextEditingController(text: '0');
  final _uuid = const Uuid();

  List<BillItemData> _billItems = [];
  double _subtotal = 0;
  double _discount = 0;
  double _total = 0;
  double _received = 0;
  double _remaining = 0;

  // Validation state
  bool _customerError = false;
  bool _discountError = false;
  bool _receivedError = false;

  @override
  void initState() {
    super.initState();
    // Add first empty row
    _addNewRow();

    // If linked bill, pre-fill customer name, phone and add previous balance
    if (widget.linkedBill != null) {
      _customerController.text = widget.linkedBill!.customerName;
      _phoneController.text = widget.linkedBill!.customerPhone ?? '';
    }
  }

  void _addNewRow() {
    setState(() {
      _billItems.add(BillItemData(id: _uuid.v4()));
    });
  }

  void _removeRow(String id) {
    setState(() {
      _billItems.removeWhere((item) => item.id == id);
      _calculateTotals();
    });
  }

  void _updateRow(String id, BillItemData updatedData) {
    setState(() {
      final index = _billItems.indexWhere((item) => item.id == id);
      if (index != -1) {
        _billItems[index] = updatedData;
        _calculateTotals();
      }
    });
  }

  void _calculateTotals() {
    _subtotal = _billItems.fold(0, (sum, item) => sum + item.amount);

    // Parse discount with validation
    final discountText = _discountController.text.trim();
    final parsedDiscount = double.tryParse(discountText);

    // Add previous bill balance if linked
    double previousBalance = 0;
    if (widget.linkedBill != null) {
      previousBalance = widget.linkedBill!.remaining;
    }

    // Validate discount: must be valid number and not exceed subtotal + previousBalance
    final maxDiscount = _subtotal + previousBalance;
    _discountError = discountText.isNotEmpty &&
        (parsedDiscount == null || parsedDiscount < 0 || parsedDiscount > maxDiscount);

    _discount = (parsedDiscount != null && parsedDiscount >= 0 && parsedDiscount <= maxDiscount)
        ? parsedDiscount
        : 0;

    _total = _subtotal - _discount + previousBalance;

    // Parse received with validation
    final receivedText = _receivedController.text.trim();
    final parsedReceived = double.tryParse(receivedText);

    // Validate received: must be valid number and >= 0
    _receivedError = receivedText.isNotEmpty &&
        (parsedReceived == null || parsedReceived < 0);

    _received = (parsedReceived != null && parsedReceived >= 0) ? parsedReceived : 0;
    _remaining = _total - _received;

    setState(() {});
  }

  Future<void> _saveBill() async {
    // Validate customer name
    final customerName = _customerController.text.trim();
    if (customerName.isEmpty) {
      setState(() {
        _customerError = true;
      });
      _showError('گاہک کا نام درج کریں');
      return;
    }

    // Check for validation errors
    if (_discountError) {
      _showError('رعایت درست نہیں ہے');
      return;
    }

    if (_receivedError) {
      _showError('وصول شدہ رقم درست نہیں ہے');
      return;
    }

    final validItems = _billItems.where((item) => item.itemId != null && item.quantity > 0 && item.price > 0).toList();
    if (validItems.isEmpty) {
      _showError('کم از کم ایک مکمل آئٹم شامل کریں');
      return;
    }

    // Create bill items
    final billItems = validItems.map((data) {
      return BillItem(
        id: data.id,
        itemId: data.itemId!,
        itemName: data.itemName ?? '',
        unit: data.unit ?? '',
        quantity: data.quantity,
        price: data.price,
        amount: data.amount,
      );
    }).toList();

    // Calculate previous remaining from linked bill
    final previousRemaining = widget.linkedBill?.remaining ?? 0;

    // Create bill
    final billId = _uuid.v4();
    final phoneNumber = _phoneController.text.trim();
    final bill = Bill(
      id: billId,
      customerName: _customerController.text.trim(),
      customerPhone: phoneNumber.isNotEmpty ? phoneNumber : null,
      date: DateTime.now(),
      items: billItems,
      subtotal: _subtotal,
      previousRemaining: previousRemaining,
      discount: _discount,
      total: _total,
      received: _received,
      remaining: _remaining,
      linkedBillId: widget.linkedBill?.id,
      status: _remaining <= 0 ? 'paid' : 'pending',
    );

    // Save to database
    await DatabaseService.saveBill(bill);

    // Update linked bill if exists - set nextBillId and status to transferred
    if (widget.linkedBill != null) {
      widget.linkedBill!.nextBillId = billId;
      widget.linkedBill!.status = 'transferred';
      await DatabaseService.saveBill(widget.linkedBill!);
    }

    if (mounted) {
      _showSuccess('بل محفوظ ہو گیا');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BillsScreen()),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.notoNastaliqUrdu(),
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.notoNastaliqUrdu(),
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final today = dateFormat.format(DateTime.now());

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: Text(
            'نیا بل',
            style: GoogleFonts.notoNastaliqUrdu(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFF1a3a6e),
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date and Customer row
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            // Date
                            Row(
                              children: [
                                Text(
                                  'تاریخ:',
                                  style: GoogleFonts.notoNastaliqUrdu(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  today,
                                  style: GoogleFonts.roboto(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Customer name
                            TextField(
                              controller: _customerController,
                              decoration: InputDecoration(
                                labelText: 'گاہک کا نام',
                                labelStyle: GoogleFonts.notoNastaliqUrdu(
                                  color: _customerError ? Colors.red : null,
                                ),
                                border: const OutlineInputBorder(),
                                prefixIcon: Icon(
                                  Icons.person,
                                  color: _customerError ? Colors.red : null,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: _customerError ? Colors.red : Colors.grey,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: _customerError ? Colors.red : Colors.blue,
                                    width: 2,
                                  ),
                                ),
                                errorText: _customerError ? 'گاہک کا نام ضروری ہے' : null,
                                errorStyle: GoogleFonts.notoNastaliqUrdu(color: Colors.red),
                              ),
                              style: GoogleFonts.notoNastaliqUrdu(fontSize: 18),
                              onChanged: (_) {
                                if (_customerError) {
                                  setState(() {
                                    _customerError = false;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            // Customer phone number
                            TextField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                labelText: 'فون نمبر (اختیاری)',
                                labelStyle: GoogleFonts.notoNastaliqUrdu(),
                                hintText: '03001234567',
                                hintStyle: GoogleFonts.roboto(color: Colors.grey),
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.phone),
                              ),
                              style: GoogleFonts.roboto(fontSize: 18),
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(11),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Linked bill info
                    if (widget.linkedBill != null) ...[
                      const SizedBox(height: 8),
                      Card(
                        color: Colors.amber[50],
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(Icons.link, color: Colors.amber),
                              const SizedBox(width: 8),
                              Text(
                                'پچھلا بقایا: ${widget.linkedBill!.remaining.toStringAsFixed(0)} روپے',
                                style: GoogleFonts.notoNastaliqUrdu(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Items header
                    Card(
                      color: const Color(0xFF1a3a6e),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                'آئٹم',
                                style: GoogleFonts.notoNastaliqUrdu(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'یونٹ',
                                style: GoogleFonts.notoNastaliqUrdu(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'مقدار',
                                style: GoogleFonts.notoNastaliqUrdu(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'قیمت',
                                style: GoogleFonts.notoNastaliqUrdu(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'رقم',
                                style: GoogleFonts.notoNastaliqUrdu(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 40), // For delete button
                          ],
                        ),
                      ),
                    ),

                    // Item rows
                    ..._billItems.map((item) => ItemRow(
                          key: ValueKey(item.id),
                          data: item,
                          onUpdate: (updated) => _updateRow(item.id, updated),
                          onDelete: () => _removeRow(item.id),
                        )),

                    // Add row button
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _addNewRow,
                        icon: const Icon(Icons.add),
                        label: Text(
                          'نئی لائن',
                          style: GoogleFonts.notoNastaliqUrdu(fontSize: 16),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Summary section
                    BillSummary(
                      subtotal: _subtotal,
                      previousBalance: widget.linkedBill?.remaining ?? 0,
                      discountController: _discountController,
                      receivedController: _receivedController,
                      total: _total,
                      remaining: _remaining,
                      onChanged: _calculateTotals,
                      discountError: _discountError,
                      receivedError: _receivedError,
                    ),
                  ],
                ),
              ),
            ),

            // Save button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              child: ElevatedButton.icon(
                onPressed: _saveBill,
                icon: const Icon(Icons.save, size: 28),
                label: Text(
                  'محفوظ کریں',
                  style: GoogleFonts.notoNastaliqUrdu(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _customerController.dispose();
    _phoneController.dispose();
    _discountController.dispose();
    _receivedController.dispose();
    super.dispose();
  }
}

// Data class for bill item row
class BillItemData {
  final String id;
  String? itemId;
  String? itemName;
  String? unit;
  double quantity;
  double price;
  double amount;

  BillItemData({
    required this.id,
    this.itemId,
    this.itemName,
    this.unit,
    this.quantity = 1,
    this.price = 0,
    this.amount = 0,
  });
}
