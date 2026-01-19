import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../models/models.dart';
import '../services/database_service.dart';
import 'bill_detail_screen.dart';
import 'new_bill_screen.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  List<Bill> _allBills = [];
  List<Bill> _pendingBills = [];
  List<Bill> _filteredBills = [];
  bool _showPendingOnly = false;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBills();
  }

  void _loadBills() {
    setState(() {
      _allBills = DatabaseService.getAllBills();
      _pendingBills = DatabaseService.getPendingBills();
      _filterBills();
    });
  }

  void _filterBills() {
    final query = _searchController.text.trim();
    List<Bill> source = _showPendingOnly ? _pendingBills : _allBills;

    if (query.isNotEmpty) {
      source = source.where((bill) {
        return bill.customerName.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }

    if (_selectedDate != null) {
      source = source.where((bill) {
        return bill.date.year == _selectedDate!.year &&
            bill.date.month == _selectedDate!.month &&
            bill.date.day == _selectedDate!.day;
      }).toList();
    }

    setState(() {
      _filteredBills = source;
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _filterBills();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
    });
    _filterBills();
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
            'بل دیکھیں',
            style: GoogleFonts.notoNastaliqUrdu(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFF1a3a6e),
          foregroundColor: Colors.white,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelStyle: GoogleFonts.notoNastaliqUrdu(fontSize: 14),
            tabs: [
              Tab(text: 'تمام بل (${_allBills.length})'),
              Tab(text: 'بقایا (${_pendingBills.length})'),
            ],
            onTap: (index) {
              setState(() {
                _showPendingOnly = index == 1;
              });
              _filterBills();
            },
          ),
        ),
        body: Column(
          children: [
            // Search and filter
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Search
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'گاہک کا نام تلاش کریں',
                      hintStyle: GoogleFonts.notoNastaliqUrdu(),
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    style: GoogleFonts.notoNastaliqUrdu(),
                    onChanged: (_) => _filterBills(),
                  ),
                  const SizedBox(height: 8),
                  // Date filter
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selectDate,
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            _selectedDate != null
                                ? dateFormat.format(_selectedDate!)
                                : 'تاریخ منتخب کریں',
                            style: GoogleFonts.notoNastaliqUrdu(),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                      if (_selectedDate != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _clearDateFilter,
                          icon: const Icon(Icons.clear),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Bills list
            Expanded(
              child: _filteredBills.isEmpty
                  ? Center(
                      child: Text(
                        'کوئی بل نہیں ملا',
                        style: GoogleFonts.notoNastaliqUrdu(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _filteredBills.length,
                      itemBuilder: (context, index) {
                        final bill = _filteredBills[index];
                        return _buildBillCard(bill, dateFormat);
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NewBillScreen(),
              ),
            );
            _loadBills();
          },
          icon: const Icon(Icons.add),
          label: Text(
            'نیا بل',
            style: GoogleFonts.notoNastaliqUrdu(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildBillCard(Bill bill, DateFormat dateFormat) {
    // Determine status
    String statusText;
    Color statusColor;
    Color statusBgColor;

    if (bill.status == 'transferred') {
      statusText = 'منتقل';
      statusColor = Colors.orange;
      statusBgColor = Colors.orange[100]!;
    } else if (bill.remaining <= 0) {
      statusText = 'مکمل';
      statusColor = Colors.green;
      statusBgColor = Colors.green[100]!;
    } else {
      statusText = 'بقایا';
      statusColor = Colors.red;
      statusBgColor = Colors.red[100]!;
    }

    final isInChain = bill.linkedBillId != null || bill.nextBillId != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BillDetailScreen(bill: bill),
            ),
          );
          _loadBills();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Customer name with chain icon
                  Expanded(
                    child: Row(
                      children: [
                        if (isInChain) ...[
                          Icon(Icons.link, size: 18, color: Colors.blue[600]),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            bill.customerName,
                            style: GoogleFonts.notoNastaliqUrdu(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: GoogleFonts.notoNastaliqUrdu(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Date and amounts
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateFormat.format(bill.date),
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    'کل: ${bill.total.toStringAsFixed(0)}',
                    style: GoogleFonts.notoNastaliqUrdu(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              // Show remaining for pending bills
              if (bill.remaining > 0 && bill.status != 'transferred') ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'بقایا: ${bill.remaining.toStringAsFixed(0)}',
                      style: GoogleFonts.notoNastaliqUrdu(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
              // Show transferred amount for transferred bills
              if (bill.status == 'transferred') ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'منتقل: ${bill.remaining.toStringAsFixed(0)}',
                      style: GoogleFonts.notoNastaliqUrdu(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
