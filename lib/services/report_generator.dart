import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw; // Use alias for PDF widgets
import 'package:intl/intl.dart';

// --- Import YOUR app's models ---
// Make sure these paths are correct for your project
import 'package:sage/models/cashbook.dart';
import 'package:sage/models/entry.dart';
import 'package:sage/models/running_balance_entry.dart';

// --- Colors ---
final kSageDeepOrangePdf = PdfColor.fromHex("#E64A19");
final kSageLightOrangePdf = PdfColor.fromHex("#F57C00");
final kSageSummaryBgPdf = PdfColor.fromHex("#FFF4F2");
final kSageTextRedPdf = PdfColor.fromHex("#D32F2F");
final kSageTextGreenPdf = PdfColor.fromHex("#388E3C");
final kSageTextDarkPdf = PdfColor.fromHex("#333333");
final kSageTextBlackPdf = PdfColor.fromHex("#000000");

// --- Row Colors ---
final kSageTableRowOrange25 = PdfColor.fromHex("#FFEFE6"); // Approx 25% Orange (Lighter)
final kSageTableRowOrange50 = PdfColor.fromHex("#FFD9C6"); // Approx 50% Orange (Slightly Darker)


// --- Column Widths for pw.Table ---
const pw.TableColumnWidth _dateWidth = pw.FlexColumnWidth(2.5);
const pw.TableColumnWidth _remarksWidth = pw.FlexColumnWidth(3.5);
const pw.TableColumnWidth _categoryWidth = pw.FlexColumnWidth(2.0);
const pw.TableColumnWidth _modeWidth = pw.FlexColumnWidth(2.0);
const pw.TableColumnWidth _inWidth = pw.FlexColumnWidth(2.0);
const pw.TableColumnWidth _outWidth = pw.FlexColumnWidth(2.0);
const pw.TableColumnWidth _balanceWidth = pw.FlexColumnWidth(2.2);


class ReportGenerator {
  // Main function to generate and return the PDF data
  static Future<Uint8List> generateReport(
    Cashbook cashbook,
    List<Entry> entries, // These are the *filtered* entries
    String durationString,
  ) async {
    final doc = pw.Document();

    // --- Load Assets ---
    final logoData = await rootBundle.load('assets/logo.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    // --- Calculate Running Balance (Chronological) ---
    List<Entry> sortedEntries = List.from(entries);
    sortedEntries.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    List<RunningBalanceEntry> rbEntries = [];
    double currentBalance = 0.0;
    for (Entry entry in sortedEntries) {
      if (entry.cashFlow == 'cashIn') {
        currentBalance += entry.amount;
      } else if (entry.cashFlow == 'cashOut') {
        currentBalance -= entry.amount;
      }
      rbEntries.add(RunningBalanceEntry(
        entry: entry,
        runningBalance: currentBalance,
      ));
    }

    // --- Create a Map for quick balance lookup ---
    final Map<dynamic, double> balanceMap = {
      for (var rb in rbEntries) rb.entry.key : rb.runningBalance
    };

    // --- Calculate Totals (from the filtered list) ---
    final double totalCashIn = sortedEntries
        .where((e) => e.cashFlow == 'cashIn')
        .fold(0.0, (sum, e) => sum + e.amount);

    final double totalCashOut = sortedEntries
        .where((e) => e.cashFlow == 'cashOut')
        .fold(0.0, (sum, e) => sum + e.amount);

    final double finalBalance = totalCashIn - totalCashOut;

    // --- Date Formatting ---
    final DateFormat smallDateFmt = DateFormat("dd MMM yyyy");
    final DateFormat smallTimeFmt = DateFormat("hh:mm a");
    final NumberFormat currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 0); // No '₹'

    // --- Get Last Date for Footer ---
    final String lastDateString = sortedEntries.isNotEmpty
        ? smallDateFmt.format(sortedEntries.last.dateTime)
        : '---';

    // --- 2. Build the PDF Page using MultiPage ---
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        // --- Header for EACH page ---
        header: (pw.Context context) {
          if (context.pageNumber == 1) {
            // Only show full header on the first page
            return pw.Column(children: [
               pw.Image(logoImage, height: 104, alignment: pw.Alignment.center),
               pw.Center(child: pw.Container( padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 24), decoration: pw.BoxDecoration(color: kSageDeepOrangePdf, borderRadius: pw.BorderRadius.circular(8),), child: pw.Text(cashbook.name, textAlign: pw.TextAlign.center, style: pw.TextStyle(color: PdfColors.white, fontSize: 20, fontWeight: pw.FontWeight.bold,),),),),
               pw.SizedBox(height: 12), // Space after title
               pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 119), child: pw.Container(padding: const pw.EdgeInsets.all(12), decoration: pw.BoxDecoration(border: pw.Border.all(color: kSageLightOrangePdf, width: 2), borderRadius: pw.BorderRadius.circular(8),), child: pw.Text("Duration: $durationString", textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: kSageTextDarkPdf,),),),),
               pw.SizedBox(height: 16), // Space after duration
               pw.Row(children: [pw.Expanded(child: _buildPdfSummaryBox("Total Cash In", currencyFormat.format(totalCashIn), kSageTextGreenPdf, bgColor: kSageSummaryBgPdf, borderColor: kSageLightOrangePdf)), pw.SizedBox(width: 8), pw.Expanded(child: _buildPdfSummaryBox("Final Balance", currencyFormat.format(finalBalance), kSageTextBlackPdf, bgColor: PdfColors.white, borderColor: kSageDeepOrangePdf,)), pw.SizedBox(width: 8), pw.Expanded(child: _buildPdfSummaryBox("Total Cash Out", currencyFormat.format(totalCashOut), kSageTextRedPdf, bgColor: kSageSummaryBgPdf, borderColor: kSageLightOrangePdf)),],),
               pw.SizedBox(height: 15), // Space before table
            ]);
          } else {
            // Spacer for subsequent pages
             return pw.SizedBox(height: 35);
          }
        },
        // --- Footer for EACH page ---
        footer: (pw.Context context) {
           return pw.Center(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 10),
                  child: pw.Text(
                    "Generated by Sage - Cashbook App",
                    style: pw.TextStyle(
                        fontSize: 12, color: PdfColor.fromHex("#888888")),
                  ),
                )
              );
        },

        // --- Body for ALL pages ---
        build: (pw.Context context) {

          // Build the list of TableRows for the data section
          List<pw.TableRow> tableRows = [];

          // Add Header Row
          tableRows.add(_buildStyledHeaderRow());

          // Add Data Rows
          for (int i = 0; i < entries.length; i++) {
            final entry = entries[i];
            final balance = balanceMap[entry.key] ?? 0.0;

            // --- Alternating Colors (25% and 50%) ---
            final bgColor = i % 2 == 0 ? kSageTableRowOrange25 : kSageTableRowOrange50;

            tableRows.add(_buildStyledDataRow(
              entry: entry,
              balance: balance,
              bgColor: bgColor, // Use the alternating color
              dateFmt: smallDateFmt,
              timeFmt: smallTimeFmt,
              currencyFmt: currencyFormat,
            ));
          }

          // Add Footer Row
          tableRows.add(_buildStyledFooterRow(
            lastDate: lastDateString, // Pass the last date
            finalBalance: finalBalance,
            currencyFmt: currencyFormat,
          ));

          return [
            // --- Use pw.Table ---
            pw.Table(
              border: const pw.TableBorder(
                 verticalInside: pw.BorderSide(color: PdfColors.white, width: 2),
                 left: pw.BorderSide.none, right: pw.BorderSide.none, top: pw.BorderSide.none, bottom: pw.BorderSide.none, horizontalInside: pw.BorderSide.none,
              ),
              columnWidths: const {
                0: _dateWidth, 1: _remarksWidth, 2: _categoryWidth, 3: _modeWidth, 4: _inWidth, 5: _outWidth, 6: _balanceWidth,
              },
              defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
              children: tableRows,
            ),
          ];
        },
      ),
    );

    return doc.save();
  }
}

// --- HELPER WIDGETS ---

// --- Summary Box Helper (Unchanged) ---
pw.Widget _buildPdfSummaryBox(
    String title, String value, PdfColor valueColor,
    {required PdfColor bgColor, required PdfColor borderColor}) {
  return pw.Container(
    height: 70, padding: const pw.EdgeInsets.all(8),
    decoration: pw.BoxDecoration(color: bgColor, border: pw.Border.all(color: borderColor, width: 1.5), borderRadius: pw.BorderRadius.circular(8),),
    child: pw.Column(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
        pw.Text(title, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center,),
        pw.SizedBox(height: 6),
        pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: valueColor,), textAlign: pw.TextAlign.center,),
      ],),
  );
}

// --- Table Cell Content Helper ---
pw.Widget _buildCellContent({
  required String text, PdfColor? color, pw.Alignment align = pw.Alignment.center, double fontSize = 8, pw.FontWeight weight = pw.FontWeight.normal,
}) {
  final PdfColor cellColor = color ?? kSageTextDarkPdf;
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6), alignment: align,
    child: pw.Text(text, maxLines: 2, textAlign: pw.TextAlign.center, style: pw.TextStyle(color: cellColor, fontSize: fontSize, fontWeight: weight),),
  );
}

// --- Table Row Helpers ---

// --- Header Row Helper ---
pw.TableRow _buildStyledHeaderRow() {
  final bgColor = kSageDeepOrangePdf; const radius = pw.Radius.circular(4);
  return pw.TableRow(
    repeat: true, decoration: pw.BoxDecoration(color: bgColor, borderRadius: pw.BorderRadius.only(topLeft: radius, topRight: radius)),
    children: [
      _buildCellContent(text: "Date & Time", color: PdfColors.white, fontSize: 9, weight: pw.FontWeight.bold),
      _buildCellContent(text: "Remarks", color: PdfColors.white, fontSize: 9, weight: pw.FontWeight.bold),
      _buildCellContent(text: "Categories", color: PdfColors.white, fontSize: 9, weight: pw.FontWeight.bold),
      _buildCellContent(text: "Pay Mode", color: PdfColors.white, fontSize: 9, weight: pw.FontWeight.bold),
      _buildCellContent(text: "Cash In", color: PdfColors.white, fontSize: 9, weight: pw.FontWeight.bold),
      _buildCellContent(text: "Cash Out", color: PdfColors.white, fontSize: 9, weight: pw.FontWeight.bold),
      _buildCellContent(text: "Balance", color: PdfColors.white, fontSize: 9, weight: pw.FontWeight.bold),
    ],
  );
}

// --- Data Row Helper ---
pw.TableRow _buildStyledDataRow({
  required Entry entry, required double balance, required PdfColor bgColor, required DateFormat dateFmt, required DateFormat timeFmt, required NumberFormat currencyFmt,
}) {
  final bool isCashIn = entry.cashFlow == 'cashIn'; const radius = pw.Radius.circular(4);
  return pw.TableRow(
    decoration: pw.BoxDecoration(color: bgColor, borderRadius: pw.BorderRadius.all(radius)),
    children: [
      _buildCellContent(text: "${dateFmt.format(entry.dateTime)}\n${timeFmt.format(entry.dateTime)}"),
      _buildCellContent(text: entry.remarks),
      _buildCellContent(text: entry.category ?? ''),
      _buildCellContent(text: entry.paymentMethod ?? ''),
      _buildCellContent(text: isCashIn ? currencyFmt.format(entry.amount) : '', color: kSageTextGreenPdf),
      _buildCellContent(text: !isCashIn ? currencyFmt.format(entry.amount) : '', color: kSageTextRedPdf),
      _buildCellContent(text: currencyFmt.format(balance), color: kSageTextBlackPdf),
    ],
  );
}

// --- Footer Row Helper ---
pw.TableRow _buildStyledFooterRow({
  required String lastDate, required double finalBalance, required NumberFormat currencyFmt
}) {
   final bgColor = kSageDeepOrangePdf; const radius = pw.Radius.circular(6);

   List<pw.Widget> footerCells = [
     // Cell 1: Last Date
     pw.Container(
       decoration: pw.BoxDecoration(color: bgColor, borderRadius: pw.BorderRadius.only(topLeft: radius, bottomLeft: radius)),
       child: _buildCellContent(text: lastDate, color: PdfColors.white, fontSize: 10, weight: pw.FontWeight.bold,)
     ),
     // Cell 2: "Final Balance"
     pw.Container(
       decoration: pw.BoxDecoration(color: bgColor), // No rounding
       child: _buildCellContent(text: "Final Balance", color: PdfColors.white, fontSize: 10, weight: pw.FontWeight.bold,)
     ),

     // --- CELLS WITH INVISIBLE TEXT ---
     // The text color (bgColor) now matches the container's background color (kSageDeepOrangePdf).
     pw.Container(decoration: pw.BoxDecoration(color: bgColor), child: _buildCellContent(text: 'Categories', color: bgColor, fontSize: 9, weight: pw.FontWeight.bold)),
     pw.Container(decoration: pw.BoxDecoration(color: bgColor), child: _buildCellContent(text: 'Pay Mode', color: bgColor, fontSize: 9, weight: pw.FontWeight.bold)),
     pw.Container(decoration: pw.BoxDecoration(color: bgColor), child: _buildCellContent(text: 'Cash In', color: bgColor, fontSize: 9, weight: pw.FontWeight.bold)),
     pw.Container(decoration: pw.BoxDecoration(color: bgColor), child: _buildCellContent(text: 'Cash Out', color: bgColor, fontSize: 9, weight: pw.FontWeight.bold)),
     // --- END OF INVISIBLE TEXT CELLS ---

     // Cell 7: Final Balance Value
     pw.Container(
       decoration: pw.BoxDecoration(color: bgColor, borderRadius: pw.BorderRadius.only(topRight: radius, bottomRight: radius)),
       child: _buildCellContent(text: currencyFmt.format(finalBalance), color: PdfColors.white, fontSize: 10, weight: pw.FontWeight.bold)
     ),
   ];

  return pw.TableRow(
     decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.white, width: 2))), // White line separator
     children: footerCells,
  );
}
