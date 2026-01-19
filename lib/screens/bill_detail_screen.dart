import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import 'new_bill_screen.dart';

class BillDetailScreen extends StatefulWidget {
  final Bill bill;

  const BillDetailScreen({super.key, required this.bill});

  @override
  State<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends State<BillDetailScreen> {
  late Bill _bill;
  List<Payment> _payments = [];
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _bill = widget.bill;
    _loadPayments();
  }

  void _loadPayments() {
    setState(() {
      _payments = DatabaseService.getPaymentsForBill(_bill.id);
      // Refresh bill data
      final updatedBill = DatabaseService.getBill(_bill.id);
      if (updatedBill != null) {
        _bill = updatedBill;
      }
    });
  }

  // Get status text and color
  (String, Color, Color) _getStatusInfo() {
    if (_bill.status == 'transferred') {
      return ('منتقل', Colors.orange, Colors.orange[100]!);
    } else if (_bill.remaining <= 0) {
      return ('مکمل', Colors.green, Colors.green[100]!);
    } else {
      return ('بقایا', Colors.red, Colors.red[100]!);
    }
  }

  Future<void> _addPayment() async {
    final amountController = TextEditingController();
    String? errorText;

    final result = await showDialog<double>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(
              'ادائیگی درج کریں',
              style: GoogleFonts.notoNastaliqUrdu(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'بقایا: ${_bill.remaining.toStringAsFixed(0)} روپے',
                  style: GoogleFonts.notoNastaliqUrdu(
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'رقم',
                    labelStyle: GoogleFonts.notoNastaliqUrdu(
                      color: errorText != null ? Colors.red : null,
                    ),
                    border: const OutlineInputBorder(),
                    prefixText: 'Rs. ',
                    errorText: errorText,
                    errorStyle: GoogleFonts.notoNastaliqUrdu(color: Colors.red),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: errorText != null ? Colors.red : Colors.grey,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: errorText != null ? Colors.red : Colors.blue,
                        width: 2,
                      ),
                    ),
                  ),
                  style: GoogleFonts.roboto(fontSize: 20),
                  onChanged: (_) {
                    if (errorText != null) {
                      setDialogState(() {
                        errorText = null;
                      });
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'منسوخ',
                  style: GoogleFonts.notoNastaliqUrdu(),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final amountText = amountController.text.trim();
                  final amount = double.tryParse(amountText);

                  // Validate: must be a valid positive number
                  if (amountText.isEmpty || amount == null || amount <= 0) {
                    setDialogState(() {
                      errorText = 'درست رقم درج کریں';
                    });
                    return;
                  }

                  // Validate: should not exceed remaining
                  if (amount > _bill.remaining) {
                    setDialogState(() {
                      errorText = 'رقم بقایا سے زیادہ نہیں ہو سکتی';
                    });
                    return;
                  }

                  Navigator.pop(context, amount);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'محفوظ کریں',
                  style: GoogleFonts.notoNastaliqUrdu(),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null) {
      final payment = Payment(
        id: _uuid.v4(),
        billId: _bill.id,
        amount: result,
        date: DateTime.now(),
      );
      await DatabaseService.savePayment(payment);
      _loadPayments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ادائیگی محفوظ ہو گئی',
              style: GoogleFonts.notoNastaliqUrdu(),
              textDirection: TextDirection.rtl,
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _linkNewBill() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewBillScreen(linkedBill: _bill),
      ),
    );
    _loadPayments();
  }

  void _goToPreviousBill() {
    if (_bill.linkedBillId != null) {
      final prevBill = DatabaseService.getBill(_bill.linkedBillId!);
      if (prevBill != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BillDetailScreen(bill: prevBill),
          ),
        );
      }
    }
  }

  void _goToNextBill() {
    if (_bill.nextBillId != null) {
      final nextBill = DatabaseService.getBill(_bill.nextBillId!);
      if (nextBill != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BillDetailScreen(bill: nextBill),
          ),
        );
      }
    }
  }

  Future<void> _deleteBill() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(
            'بل حذف کریں؟',
            style: GoogleFonts.notoNastaliqUrdu(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'کیا آپ واقعی یہ بل حذف کرنا چاہتے ہیں؟ یہ عمل واپس نہیں ہو سکتا۔',
            style: GoogleFonts.notoNastaliqUrdu(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('نہیں', style: GoogleFonts.notoNastaliqUrdu()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('ہاں، حذف کریں', style: GoogleFonts.notoNastaliqUrdu()),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      await DatabaseService.deleteBill(_bill.id);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final (statusText, statusColor, statusBgColor) = _getStatusInfo();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: Text(
            'بل کی تفصیل',
            style: GoogleFonts.notoNastaliqUrdu(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFF1a3a6e),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              onPressed: _deleteBill,
              icon: const Icon(Icons.delete),
              tooltip: 'حذف کریں',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chain navigation (if part of chain)
              if (_bill.linkedBillId != null || _bill.nextBillId != null)
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.link, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              'بل چین',
                              style: GoogleFonts.notoNastaliqUrdu(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Previous bill button
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _bill.linkedBillId != null
                                    ? _goToPreviousBill
                                    : null,
                                icon: const Icon(Icons.arrow_forward),
                                label: Text(
                                  'پچھلا بل',
                                  style: GoogleFonts.notoNastaliqUrdu(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Next bill button
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _bill.nextBillId != null
                                    ? _goToNextBill
                                    : null,
                                icon: const Icon(Icons.arrow_back),
                                label: Text(
                                  'اگلا بل',
                                  style: GoogleFonts.notoNastaliqUrdu(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              if (_bill.linkedBillId != null || _bill.nextBillId != null)
                const SizedBox(height: 12),

              // Customer and date info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _bill.customerName,
                              style: GoogleFonts.notoNastaliqUrdu(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              statusText,
                              style: GoogleFonts.notoNastaliqUrdu(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'تاریخ: ${dateFormat.format(_bill.date)}',
                        style: GoogleFonts.notoNastaliqUrdu(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Items list
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1a3a6e),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
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
                            ),
                          ),
                          Expanded(
                            flex: 1,
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
                            flex: 1,
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
                            flex: 1,
                            child: Text(
                              'رقم',
                              style: GoogleFonts.notoNastaliqUrdu(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Items
                    ..._bill.items.map((item) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.itemName,
                                      style: GoogleFonts.notoNastaliqUrdu(
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      item.unit,
                                      style: GoogleFonts.notoNastaliqUrdu(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  item.quantity.toStringAsFixed(0),
                                  style: GoogleFonts.roboto(fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  item.price.toStringAsFixed(0),
                                  style: GoogleFonts.roboto(fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  item.amount.toStringAsFixed(0),
                                  style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      _buildSummaryRow('اس بل کا ٹوٹل', _bill.subtotal),
                      if (_bill.previousRemaining > 0)
                        _buildSummaryRow('پچھلا بقایا', _bill.previousRemaining,
                            color: Colors.orange),
                      if (_bill.discount > 0)
                        _buildSummaryRow('رعایت', -_bill.discount),
                      const Divider(),
                      _buildSummaryRow('کل رقم', _bill.total, isBold: true),
                      const Divider(),
                      _buildSummaryRow('وصول شدہ', _bill.received,
                          color: Colors.green),
                      if (_bill.status == 'transferred')
                        _buildSummaryRow('اگلے بل میں منتقل', _bill.remaining,
                            color: Colors.orange, isBold: true)
                      else
                        _buildSummaryRow('بقایا', _bill.remaining,
                            isBold: true,
                            color: _bill.remaining > 0
                                ? Colors.red
                                : Colors.green),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Payments history
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ادائیگیوں کی تفصیل',
                            style: GoogleFonts.notoNastaliqUrdu(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Only show add payment if not transferred and has remaining
                          if (_bill.remaining > 0 &&
                              _bill.status != 'transferred')
                            ElevatedButton.icon(
                              onPressed: _addPayment,
                              icon: const Icon(Icons.add, size: 18),
                              label: Text(
                                'ادائیگی',
                                style: GoogleFonts.notoNastaliqUrdu(),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_payments.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Center(
                          child: Text(
                            'ابھی تک کوئی ادائیگی نہیں',
                            style: GoogleFonts.notoNastaliqUrdu(
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                    else
                      ..._payments.map((payment) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dateFormat.format(payment.date),
                                      style: GoogleFonts.roboto(fontSize: 14),
                                    ),
                                    Text(
                                      timeFormat.format(payment.date),
                                      style: GoogleFonts.roboto(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${payment.amount.toStringAsFixed(0)} روپے',
                                  style: GoogleFonts.notoNastaliqUrdu(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          )),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Link to new bill button (only if not already transferred)
              if (_bill.remaining > 0 && _bill.status != 'transferred')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _linkNewBill,
                    icon: const Icon(Icons.link),
                    label: Text(
                      'نیا بل جوڑیں',
                      style: GoogleFonts.notoNastaliqUrdu(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.notoNastaliqUrdu(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
          Text(
            '${value.toStringAsFixed(0)} روپے',
            style: GoogleFonts.notoNastaliqUrdu(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
