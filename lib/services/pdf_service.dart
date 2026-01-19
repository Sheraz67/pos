import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../models/models.dart';

class PdfService {
  static pw.Font? _arabicFont;
  static pw.Font? _arabicBoldFont;
  static pw.Font? _latinFont;
  static pw.Font? _latinBoldFont;

  // Load fonts using PdfGoogleFonts for reliable Unicode support
  static Future<void> _loadFonts() async {
    if (_arabicFont == null) {
      _arabicFont = await PdfGoogleFonts.notoSansArabicRegular();
    }
    if (_arabicBoldFont == null) {
      _arabicBoldFont = await PdfGoogleFonts.notoSansArabicBold();
    }
    if (_latinFont == null) {
      _latinFont = await PdfGoogleFonts.notoSansRegular();
    }
    if (_latinBoldFont == null) {
      _latinBoldFont = await PdfGoogleFonts.notoSansBold();
    }
  }

  // Generate bill PDF as bytes (works on all platforms)
  static Future<Uint8List> generateBillPdfBytes(Bill bill) async {
    await _loadFonts();
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Create document with theme at Document level to ensure all elements use custom fonts
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: _arabicFont!,
        bold: _arabicBoldFont!,
        italic: _arabicFont!,
        boldItalic: _arabicBoldFont!,
      ),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (context) => _buildPdfContent(bill, dateFormat),
      ),
    );

    return pdf.save();
  }

  // Generate bill PDF as File (for mobile sharing)
  static Future<File> generateBillPdfFile(Bill bill) async {
    final pdfBytes = await generateBillPdfBytes(bill);
    final dateFormat = DateFormat('dd-MM-yyyy');

    final tempDir = await getTemporaryDirectory();
    final fileName = 'bill_${bill.customerName.replaceAll(' ', '_')}_${dateFormat.format(bill.date)}.pdf';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(pdfBytes);

    return file;
  }

  // Get filename for the bill
  static String getBillFileName(Bill bill) {
    final dateFormat = DateFormat('dd-MM-yyyy');
    return 'bill_${bill.customerName.replaceAll(' ', '_')}_${dateFormat.format(bill.date)}.pdf';
  }

  // Helper to create text style with Arabic font and Latin fallback
  static pw.TextStyle _textStyle({
    double fontSize = 14,
    bool isBold = false,
    PdfColor? color,
  }) {
    return pw.TextStyle(
      font: isBold ? _arabicBoldFont : _arabicFont,
      fontFallback: [
        if (isBold) _latinBoldFont! else _latinFont!,
      ],
      fontSize: fontSize,
      color: color,
    );
  }

  // Helper for Latin-only text (numbers, dates, English names)
  static pw.TextStyle _latinTextStyle({
    double fontSize = 14,
    bool isBold = false,
    PdfColor? color,
  }) {
    return pw.TextStyle(
      font: isBold ? _latinBoldFont : _latinFont,
      fontFallback: [
        if (isBold) _arabicBoldFont! else _arabicFont!,
      ],
      fontSize: fontSize,
      color: color,
    );
  }

  // Build PDF content
  static pw.Widget _buildPdfContent(Bill bill, DateFormat dateFormat) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // Header
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#1a3a6e'),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            children: [
              pw.Text(
                'میاں ہارڈویئر سٹور',
                style: _textStyle(fontSize: 24, isBold: true, color: PdfColors.white),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'عیدگاہ روڈ ناروال',
                style: _textStyle(fontSize: 14, color: PdfColors.white),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '0308-6363647 | 0312-7223189',
                style: _latinTextStyle(fontSize: 12, color: PdfColors.white),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 16),

        // Bill info row
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              dateFormat.format(bill.date),
              style: _latinTextStyle(fontSize: 12),
            ),
            pw.Text(
              'تاریخ:',
              style: _textStyle(fontSize: 12),
              textDirection: pw.TextDirection.rtl,
            ),
          ],
        ),

        pw.SizedBox(height: 8),

        // Customer name and phone
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    bill.customerName,
                    style: _latinTextStyle(fontSize: 16, isBold: true),
                  ),
                  pw.Text(
                    'گاہک:',
                    style: _textStyle(fontSize: 14),
                    textDirection: pw.TextDirection.rtl,
                  ),
                ],
              ),
              if (bill.customerPhone != null && bill.customerPhone!.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      bill.customerPhone!,
                      style: _latinTextStyle(fontSize: 14),
                    ),
                    pw.Text(
                      'فون:',
                      style: _textStyle(fontSize: 14),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        pw.SizedBox(height: 16),

        // Items table header
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#1a3a6e'),
            borderRadius: const pw.BorderRadius.only(
              topLeft: pw.Radius.circular(8),
              topRight: pw.Radius.circular(8),
            ),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 1,
                child: pw.Text(
                  'رقم',
                  style: _textStyle(isBold: true, color: PdfColors.white),
                  textDirection: pw.TextDirection.rtl,
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Text(
                  'قیمت',
                  style: _textStyle(isBold: true, color: PdfColors.white),
                  textDirection: pw.TextDirection.rtl,
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Text(
                  'مقدار',
                  style: _textStyle(isBold: true, color: PdfColors.white),
                  textDirection: pw.TextDirection.rtl,
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Text(
                  'یونٹ',
                  style: _textStyle(isBold: true, color: PdfColors.white),
                  textDirection: pw.TextDirection.rtl,
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'آئٹم',
                  style: _textStyle(isBold: true, color: PdfColors.white),
                  textDirection: pw.TextDirection.rtl,
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          ),
        ),

        // Items rows
        ...bill.items.map((item) => pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  left: const pw.BorderSide(color: PdfColors.grey300),
                  right: const pw.BorderSide(color: PdfColors.grey300),
                  bottom: const pw.BorderSide(color: PdfColors.grey300),
                ),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      item.amount.toStringAsFixed(0),
                      textAlign: pw.TextAlign.center,
                      style: _latinTextStyle(isBold: true),
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      item.price.toStringAsFixed(0),
                      textAlign: pw.TextAlign.center,
                      style: _latinTextStyle(),
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      item.quantity.toStringAsFixed(0),
                      textAlign: pw.TextAlign.center,
                      style: _latinTextStyle(),
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      item.unit,
                      style: _textStyle(),
                      textDirection: pw.TextDirection.rtl,
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      item.itemName,
                      style: _textStyle(),
                      textDirection: pw.TextDirection.rtl,
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ],
              ),
            )),

        pw.SizedBox(height: 16),

        // Summary section
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            children: [
              _buildSummaryRow('اس بل کا ٹوٹل', bill.subtotal),
              if (bill.previousRemaining > 0)
                _buildSummaryRow('پچھلا بقایا', bill.previousRemaining, color: PdfColors.orange),
              if (bill.discount > 0)
                _buildSummaryRow('رعایت', -bill.discount),
              pw.Divider(color: PdfColors.grey400),
              _buildSummaryRow('کل رقم', bill.total, isBold: true, color: PdfColor.fromHex('#1a3a6e')),
              pw.Divider(color: PdfColors.grey400),
              _buildSummaryRow('وصول شدہ', bill.received, color: PdfColors.green),
              _buildSummaryRow('بقایا', bill.remaining,
                  isBold: true,
                  color: bill.remaining > 0 ? PdfColors.red : PdfColors.green),
            ],
          ),
        ),

        pw.Spacer(),

        // Footer
        pw.Center(
          child: pw.Text(
            'شکریہ - آپ کی سرپرستی کا',
            style: _textStyle(fontSize: 14, color: PdfColors.grey600),
            textDirection: pw.TextDirection.rtl,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSummaryRow(
    String label,
    double value, {
    bool isBold = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                ' روپے',
                style: _textStyle(isBold: isBold, color: color),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                value.toStringAsFixed(0),
                style: _latinTextStyle(isBold: isBold, color: color),
              ),
            ],
          ),
          pw.Text(
            label,
            style: _textStyle(isBold: isBold, color: color),
            textDirection: pw.TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}
