import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../models/models.dart';
import '../services/database_service.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  int _selectedDays = 30;

  // Sales data
  double _totalSales = 0;
  double _totalReceived = 0;
  double _totalRemaining = 0;
  int _billCount = 0;
  int _paidBillCount = 0;
  int _pendingBillCount = 0;
  List<Bill> _periodBills = [];
  Map<String, double> _dailySales = {};

  @override
  void initState() {
    super.initState();
    _calculateReport();
  }

  void _setDays(int days) {
    setState(() {
      _selectedDays = days;
      _endDate = DateTime.now();
      _startDate = DateTime.now().subtract(Duration(days: days));
    });
    _calculateReport();
  }

  Future<void> _selectCustomDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedDays = 0; // Custom range
      });
      _calculateReport();
    }
  }

  void _calculateReport() {
    final allBills = DatabaseService.getAllBills();

    // Filter bills by date range
    _periodBills = allBills.where((bill) {
      final billDate = DateTime(bill.date.year, bill.date.month, bill.date.day);
      final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
      final end = DateTime(_endDate.year, _endDate.month, _endDate.day);
      return billDate.isAfter(start.subtract(const Duration(days: 1))) &&
             billDate.isBefore(end.add(const Duration(days: 1)));
    }).toList();

    // Calculate totals
    _totalSales = 0;
    _totalReceived = 0;
    _totalRemaining = 0;
    _billCount = _periodBills.length;
    _paidBillCount = 0;
    _pendingBillCount = 0;
    _dailySales = {};

    for (var bill in _periodBills) {
      // Only count subtotal (actual sales, not carried forward amounts)
      _totalSales += bill.subtotal;
      _totalReceived += bill.received;

      // For remaining, only count pending bills (not transferred)
      if (bill.status == 'pending' && bill.remaining > 0) {
        _totalRemaining += bill.remaining;
        _pendingBillCount++;
      } else if (bill.status == 'paid' || bill.remaining <= 0) {
        _paidBillCount++;
      }

      // Daily sales aggregation
      final dayKey = DateFormat('dd/MM').format(bill.date);
      _dailySales[dayKey] = (_dailySales[dayKey] ?? 0) + bill.subtotal;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: Text(
            'سیلز رپورٹ',
            style: GoogleFonts.notoNastaliqUrdu(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFF1a3a6e),
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Date range selector
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مدت منتخب کریں',
                        style: GoogleFonts.notoNastaliqUrdu(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Quick select buttons
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildDayChip(7, '7 دن'),
                          _buildDayChip(15, '15 دن'),
                          _buildDayChip(30, '30 دن'),
                          _buildDayChip(60, '60 دن'),
                          _buildDayChip(90, '90 دن'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Custom date range button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _selectCustomDateRange,
                          icon: const Icon(Icons.date_range),
                          label: Text(
                            _selectedDays == 0
                                ? '${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}'
                                : 'اپنی تاریخ منتخب کریں',
                            style: GoogleFonts.notoNastaliqUrdu(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Selected range display
                      Center(
                        child: Text(
                          '${dateFormat.format(_startDate)} سے ${dateFormat.format(_endDate)} تک',
                          style: GoogleFonts.notoNastaliqUrdu(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Sales summary card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[700]!, Colors.green[500]!],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'کل سیلز',
                      style: GoogleFonts.notoNastaliqUrdu(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_totalSales.toStringAsFixed(0)} روپے',
                      style: GoogleFonts.roboto(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSummaryChip(
                          '$_billCount',
                          'بل',
                          Icons.receipt,
                          Colors.white.withOpacity(0.2),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Received and Remaining cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'وصول شدہ',
                      _totalReceived,
                      Colors.blue,
                      Icons.account_balance_wallet,
                      '$_paidBillCount مکمل',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'بقایا جات',
                      _totalRemaining,
                      Colors.red,
                      Icons.pending_actions,
                      '$_pendingBillCount بل',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Collection rate
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'وصولی کی شرح',
                            style: GoogleFonts.notoNastaliqUrdu(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _totalSales > 0
                                ? '${((_totalReceived / _totalSales) * 100).toStringAsFixed(1)}%'
                                : '0%',
                            style: GoogleFonts.roboto(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _totalSales > 0 ? _totalReceived / _totalSales : 0,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
                          minHeight: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Daily sales breakdown
              if (_dailySales.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'روزانہ سیلز',
                          style: GoogleFonts.notoNastaliqUrdu(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._buildDailySalesList(),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Bills list
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'بل کی تفصیل',
                            style: GoogleFonts.notoNastaliqUrdu(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_periodBills.length} بل',
                            style: GoogleFonts.notoNastaliqUrdu(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_periodBills.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              'اس مدت میں کوئی بل نہیں',
                              style: GoogleFonts.notoNastaliqUrdu(
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      else
                        ...List.generate(
                          _periodBills.length > 10 ? 10 : _periodBills.length,
                          (index) => _buildBillTile(_periodBills[index], dateFormat),
                        ),
                      if (_periodBills.length > 10)
                        Center(
                          child: TextButton(
                            onPressed: () {
                              // Could navigate to full list
                            },
                            child: Text(
                              'اور ${_periodBills.length - 10} بل...',
                              style: GoogleFonts.notoNastaliqUrdu(
                                color: const Color(0xFF1a3a6e),
                              ),
                            ),
                          ),
                        ),
                    ],
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

  Widget _buildDayChip(int days, String label) {
    final isSelected = _selectedDays == days;
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.notoNastaliqUrdu(
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => _setDays(days),
      selectedColor: const Color(0xFF1a3a6e),
      backgroundColor: Colors.grey[200],
    );
  }

  Widget _buildSummaryChip(String value, String label, IconData icon, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.notoNastaliqUrdu(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    double amount,
    Color color,
    IconData icon,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.notoNastaliqUrdu(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${amount.toStringAsFixed(0)}',
            style: GoogleFonts.roboto(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.notoNastaliqUrdu(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDailySalesList() {
    // Sort by date (most recent first)
    final sortedEntries = _dailySales.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    // Show max 7 days
    final displayEntries = sortedEntries.take(7).toList();
    final maxSale = _dailySales.values.isEmpty
        ? 1.0
        : _dailySales.values.reduce((a, b) => a > b ? a : b);

    return displayEntries.map((entry) {
      final percentage = entry.value / maxSale;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            SizedBox(
              width: 50,
              child: Text(
                entry.key,
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green[400]!),
                  minHeight: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 70,
              child: Text(
                entry.value.toStringAsFixed(0),
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildBillTile(Bill bill, DateFormat dateFormat) {
    Color statusColor;
    String statusText;

    if (bill.status == 'transferred') {
      statusColor = Colors.orange;
      statusText = 'منتقل';
    } else if (bill.remaining <= 0) {
      statusColor = Colors.green;
      statusText = 'مکمل';
    } else {
      statusColor = Colors.red;
      statusText = 'بقایا';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.customerName,
                  style: GoogleFonts.notoNastaliqUrdu(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  dateFormat.format(bill.date),
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${bill.subtotal.toStringAsFixed(0)}',
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.notoNastaliqUrdu(
                    fontSize: 10,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
