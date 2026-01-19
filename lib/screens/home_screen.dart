import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'new_bill_screen.dart';
import 'bills_screen.dart';
import 'due_bills_screen.dart';
import 'sales_report_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: Text(
            'POS',
            style: GoogleFonts.notoNastaliqUrdu(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF1a3a6e),
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Store name
              Text(
                'میاں ہارڈویئر سٹور',
                style: GoogleFonts.notoNastaliqUrdu(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1a3a6e),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'عیدگاہ روڈ ناروال',
                style: GoogleFonts.notoNastaliqUrdu(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 30),
              // Menu buttons
              _buildMenuButton(
                context,
                'نیا بل',
                Icons.add_shopping_cart,
                Colors.green,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NewBillScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              _buildMenuButton(
                context,
                'بل دیکھیں',
                Icons.receipt_long,
                const Color(0xFF1a3a6e),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BillsScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              _buildMenuButton(
                context,
                'بقایا جات',
                Icons.account_balance_wallet,
                Colors.red,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DueBillsScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              _buildMenuButton(
                context,
                'سیلز رپورٹ',
                Icons.bar_chart,
                Colors.purple,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SalesReportScreen(),
                  ),
                ),
              ),
              const Spacer(),
              // Contact info
              Text(
                '0308-6363647 | 0312-7223189',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 3,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32),
            const SizedBox(width: 15),
            Text(
              title,
              style: GoogleFonts.notoNastaliqUrdu(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
