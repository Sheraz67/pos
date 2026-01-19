import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../models/models.dart';
import '../services/database_service.dart';
import 'bill_detail_screen.dart';

class DueBillsScreen extends StatefulWidget {
  const DueBillsScreen({super.key});

  @override
  State<DueBillsScreen> createState() => _DueBillsScreenState();
}

class _DueBillsScreenState extends State<DueBillsScreen> {
  List<Bill> _pendingBills = [];
  Map<String, List<Bill>> _billsByCustomer = {};
  Map<String, double> _totalByCustomer = {};
  double _grandTotal = 0;

  @override
  void initState() {
    super.initState();
    _loadDueBills();
  }

  void _loadDueBills() {
    // Get all pending bills (not transferred, has remaining > 0)
    final allBills = DatabaseService.getAllBills();
    _pendingBills = allBills.where((bill) {
      return bill.status == 'pending' && bill.remaining > 0;
    }).toList();

    // Group by customer
    _billsByCustomer = {};
    _totalByCustomer = {};
    _grandTotal = 0;

    for (var bill in _pendingBills) {
      final customer = bill.customerName;
      if (!_billsByCustomer.containsKey(customer)) {
        _billsByCustomer[customer] = [];
        _totalByCustomer[customer] = 0;
      }
      _billsByCustomer[customer]!.add(bill);
      _totalByCustomer[customer] = _totalByCustomer[customer]! + bill.remaining;
      _grandTotal += bill.remaining;
    }

    // Sort customers by total due (highest first)
    _billsByCustomer = Map.fromEntries(
      _billsByCustomer.entries.toList()
        ..sort((a, b) => _totalByCustomer[b.key]!.compareTo(_totalByCustomer[a.key]!)),
    );

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
            'بقایا جات',
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
            // Summary card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red[700]!, Colors.red[500]!],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'کل بقایا',
                    style: GoogleFonts.notoNastaliqUrdu(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_grandTotal.toStringAsFixed(0)} روپے',
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
                        '${_billsByCustomer.length}',
                        'گاہک',
                        Icons.people,
                      ),
                      const SizedBox(width: 20),
                      _buildSummaryChip(
                        '${_pendingBills.length}',
                        'بل',
                        Icons.receipt,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Customer list
            Expanded(
              child: _billsByCustomer.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 64,
                            color: Colors.green[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'کوئی بقایا نہیں!',
                            style: GoogleFonts.notoNastaliqUrdu(
                              fontSize: 20,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _billsByCustomer.length,
                      itemBuilder: (context, index) {
                        final customer = _billsByCustomer.keys.elementAt(index);
                        final bills = _billsByCustomer[customer]!;
                        final totalDue = _totalByCustomer[customer]!;

                        return _buildCustomerCard(
                          customer,
                          bills,
                          totalDue,
                          dateFormat,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryChip(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
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

  Widget _buildCustomerCard(
    String customer,
    List<Bill> bills,
    double totalDue,
    DateFormat dateFormat,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.red[100],
              child: Text(
                customer.isNotEmpty ? customer[0] : '?',
                style: GoogleFonts.notoNastaliqUrdu(
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer,
                    style: GoogleFonts.notoNastaliqUrdu(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${bills.length} بل',
                    style: GoogleFonts.notoNastaliqUrdu(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${totalDue.toStringAsFixed(0)}',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            Text(
              'روپے',
              style: GoogleFonts.notoNastaliqUrdu(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        children: [
          const Divider(height: 1),
          ...bills.map((bill) => ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.receipt, color: Colors.grey),
                ),
                title: Text(
                  dateFormat.format(bill.date),
                  style: GoogleFonts.roboto(fontSize: 14),
                ),
                subtitle: Text(
                  'کل: ${bill.total.toStringAsFixed(0)} | وصول: ${bill.received.toStringAsFixed(0)}',
                  style: GoogleFonts.notoNastaliqUrdu(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                trailing: Text(
                  '${bill.remaining.toStringAsFixed(0)}',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BillDetailScreen(bill: bill),
                    ),
                  );
                  _loadDueBills();
                },
              )),
        ],
      ),
    );
  }
}
