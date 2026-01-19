import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class BillSummary extends StatelessWidget {
  final double subtotal;
  final double previousBalance;
  final TextEditingController discountController;
  final TextEditingController receivedController;
  final double total;
  final double remaining;
  final VoidCallback onChanged;
  final bool discountError;
  final bool receivedError;

  const BillSummary({
    super.key,
    required this.subtotal,
    required this.previousBalance,
    required this.discountController,
    required this.receivedController,
    required this.total,
    required this.remaining,
    required this.onChanged,
    this.discountError = false,
    this.receivedError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Subtotal
            _buildRow(
              'اس بل کا ٹوٹل',
              subtotal.toStringAsFixed(0),
              isBold: false,
            ),

            // Previous balance if exists
            if (previousBalance > 0) ...[
              const Divider(),
              _buildRow(
                'پچھلا بقایا',
                previousBalance.toStringAsFixed(0),
                isBold: false,
                color: Colors.orange,
              ),
            ],

            const Divider(),

            // Discount
            _buildInputRow(
              'رعایت',
              discountController,
              onChanged,
              hasError: discountError,
            ),

            const Divider(),

            // Total
            _buildRow(
              'کل رقم',
              total.toStringAsFixed(0),
              isBold: true,
              isLarge: true,
              color: const Color(0xFF1a3a6e),
            ),

            const Divider(thickness: 2),

            // Received
            _buildInputRow(
              'وصول شدہ',
              receivedController,
              onChanged,
              hasError: receivedError,
            ),

            const Divider(),

            // Remaining
            _buildRow(
              'بقایا',
              remaining.toStringAsFixed(0),
              isBold: true,
              isLarge: true,
              color: remaining > 0 ? Colors.red : Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    bool isBold = false,
    bool isLarge = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.notoNastaliqUrdu(
              fontSize: isLarge ? 18 : 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: isLarge ? 22 : 18,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow(
    String label,
    TextEditingController controller,
    VoidCallback onChanged, {
    bool hasError = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.notoNastaliqUrdu(fontSize: 16),
          ),
          SizedBox(
            width: 120,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                border: const OutlineInputBorder(),
                isDense: true,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: hasError ? Colors.red : Colors.grey,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: hasError ? Colors.red : Colors.blue,
                    width: 2,
                  ),
                ),
              ),
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: hasError ? Colors.red : Colors.black,
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
        ],
      ),
    );
  }
}
