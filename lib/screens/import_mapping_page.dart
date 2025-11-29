import 'package:flutter/material.dart';
import 'package:sage/models/cashbook.dart';
import 'package:sage/models/import_field.dart'; // Import the enum
import 'package:sage/screens/import_review_page.dart';
// Import review page

class ImportMappingPage extends StatefulWidget {
  final List<dynamic> csvHeaders;
  final List<List<dynamic>> dataRows;
  final List<Cashbook> allCashbooks;
  final String tableName; // --- To show in subtitle ---

  const ImportMappingPage({
    super.key,
    required this.csvHeaders,
    required this.dataRows,
    required this.allCashbooks,
    required this.tableName,
  });
  @override
  State<ImportMappingPage> createState() => _ImportMappingPageState();
}

class _ImportMappingPageState extends State<ImportMappingPage> {
  // --- MODIFIED: New mapping structure ---
  // Maps the app's field to the *index* of the CSV/SQL column
  late Map<AppField, int?> _mapping;

  // --- NEW: Define colors from the image ---
  static const Color _orangeColor = Color(0xFFE64A19); // Deep Orange
  static const Color _greenColor = Color(0xFF388E3C); // Green
  static const Color _redColor = Color(0xFFD32F2F); // Red

  @override
  void initState() {
    super.initState();

    // --- MODIFIED: Initialize new mapping ---
    // We only map the fields shown in the UI.
    _mapping = {
      AppField.date: null,
      AppField.time: null,
      AppField.remarks: null,
      AppField.category: null,
      AppField.paymentMethod: null,
      AppField.amountIn: null,
      AppField.amountOut: null,
      AppField.amountSingleColumn: null, // Keep for auto-map logic
    };

    _autoMapHeaders();
  }

  /// --- MODIFIED: To work with new mapping structure ---
  /// Tries to guess the mapping by common header names
  void _autoMapHeaders() {
    for (int i = 0; i < widget.csvHeaders.length; i++) {
      String header = widget.csvHeaders[i].toString().toLowerCase().trim();

      // Use `putIfAbsent` logic to only map the first match
      if (header.contains('date')) {
        _mapping.update(AppField.date, (val) => val ?? i, ifAbsent: () => i);
      } else if (header.contains('time')) {
        _mapping.update(AppField.time, (val) => val ?? i, ifAbsent: () => i);
      } else if (header.contains('remark') ||
          header.contains('desc') ||
          header.contains('detail')) {
        _mapping.update(AppField.remarks, (val) => val ?? i, ifAbsent: () => i);
      } else if (header.contains('category')) {
        _mapping.update(AppField.category, (val) => val ?? i, ifAbsent: () => i);
      } else if (header.contains('mode') || header.contains('method')) {
        _mapping.update(AppField.paymentMethod, (val) => val ?? i, ifAbsent: () => i);
      } else if (header.contains('credit') || header.contains('in')) {
        _mapping.update(AppField.amountIn, (val) => val ?? i, ifAbsent: () => i);
      } else if (header.contains('debit') || header.contains('out')) {
        _mapping.update(AppField.amountOut, (val) => val ?? i, ifAbsent: () => i);
      } else if (header.contains('amount')) {
        _mapping.update(AppField.amountSingleColumn, (val) => val ?? i, ifAbsent: () => i);
      }
    }
    // Update UI after auto-mapping
    setState(() {});
  }

  /// --- MODIFIED: Validation logic for new mapping ---
  void _onNextPressed() {
    // Check 1: Must have a 'Date'
    if (_mapping[AppField.date] == null) {
      _showError("You must map a column to 'Date'.");
      return;
    }

    // Check 2: Must have at least one amount column
    bool hasAmount = _mapping[AppField.amountIn] != null ||
        _mapping[AppField.amountOut] != null ||
        _mapping[AppField.amountSingleColumn] != null;

    if (!hasAmount) {
      _showError(
          "You must map at least one amount column (e.g., 'Amount In', 'Amount Out', or 'Amount (Single Column)').");
      return;
    }

    // Check 3: Don't map 'Amount In' and 'Amount Single Column' at the same time
    if (_mapping[AppField.amountSingleColumn] != null &&
        (_mapping[AppField.amountIn] != null ||
            _mapping[AppField.amountOut] != null)) {
      _showError(
          "Please map EITHER 'Amount (Single Column)' OR 'Amount In' / 'Amount Out', but not both.");
      return;
    }

    // --- MODIFIED: Convert new map to old map format for review page ---
    final Map<int, AppField> oldFormatMapping = {};
    _mapping.forEach((appField, index) {
      if (index != null) {
        // We found a mapping, add it
        oldFormatMapping[index] = appField;
      }
    });

    // Add back the 'ignore' fields for any unmapped columns
    for (int i = 0; i < widget.csvHeaders.length; i++) {
      if (!oldFormatMapping.containsKey(i)) {
        oldFormatMapping[i] = AppField.ignore;
      }
    }

    // --- 2. Navigation ---
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImportReviewPage(
          dataRows: widget.dataRows,
          allCashbooks: widget.allCashbooks,
          columnMapping: oldFormatMapping, 
          tableName: widget.tableName, // <-- *** FIX IS HERE ***
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  /// --- NEW: Shows modal to pick a column ---
  void _showFieldPicker(AppField fieldToMap) {
    // Get the first row for example data
    final firstRow = widget.dataRows.isNotEmpty ? widget.dataRows.first : [];

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Select Column for "${fieldToMap.displayName}"',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Divider(height: 1),
            // "Clear" option
            ListTile(
              leading: const Icon(Icons.clear),
              title: const Text('(Clear Selection)'),
              onTap: () {
                setState(() {
                  _mapping[fieldToMap] = null;
                });
                Navigator.pop(context);
              },
            ),
            // Column headers
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.csvHeaders.length,
                itemBuilder: (context, index) {
                  final headerName = widget.csvHeaders[index].toString();
                  // Show example data if available
                  final exampleData = (firstRow.length > index)
                      ? firstRow[index].toString()
                      : '(no data)';

                  final isSelected = _mapping[fieldToMap] == index;

                  return ListTile(
                    title: Text(headerName,
                        style: TextStyle(
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal)),
                    subtitle: Text('Example: "$exampleData"'),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: _orangeColor)
                        : null,
                    onTap: () {
                      setState(() {
                        // Check if another field is already using this index
                        _mapping.forEach((field, i) {
                          if (i == index) {
                            _mapping[field] = null;
                          }
                        });

                        // Assign new mapping
                        _mapping[fieldToMap] = index;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// --- NEW: Helper to get example text ---
  String _getExampleText(AppField field) {
    final index = _mapping[field];
    if (index == null || widget.dataRows.isEmpty) {
      // Return default text from image
      switch (field) {
        case AppField.date:
          return '2023-10-28, 10/26/23...';
        case AppField.time:
          return '2023-10-28, 10:20 PM...';
        case AppField.remarks:
          return 'Notes & Description';
        case AppField.category:
          return 'Bills, Fuel, Food';
        case AppField.paymentMethod:
          return 'Cash, Online, Cheque';
        case AppField.amountIn:
          return 'Cash In';
        case AppField.amountOut:
          return 'Cash Out';
        default:
          return '';
      }
    }
    // Show data from the first 3 rows
    return widget.dataRows
        .take(3)
        .map((row) => row.length > index ? row[index].toString() : '')
        .join(', ');
  }

  /// --- NEW: Rebuilt "build" method ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Field Mapping'),
            Text(
              "Mapping from '${widget.tableName}'",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildMappingRow(
                  field: AppField.date,
                  icon: Icons.calendar_today_outlined,
                  color: _orangeColor,
                ),
                _buildMappingRow(
                  field: AppField.time,
                  icon: Icons.access_time_outlined,
                  color: _orangeColor,
                ),
                _buildMappingRow(
                  field: AppField.remarks,
                  icon: Icons.description_outlined,
                  color: _orangeColor,
                ),
                _buildMappingRow(
                  field: AppField.category,
                  icon: Icons.category_outlined,
                  color: _orangeColor,
                ),
                _buildMappingRow(
                  field: AppField.paymentMethod,
                  icon: Icons.payment_outlined,
                  color: _orangeColor,
                ),
                _buildMappingRow(
                  field: AppField.amountIn,
                  icon: Icons.arrow_upward_rounded,
                  color: _greenColor,
                ),
                _buildMappingRow(
                  field: AppField.amountOut,
                  icon: Icons.arrow_downward_rounded,
                  color: _redColor,
                ),
                // We don't show amountSingleColumn to match the image,
                // but the auto-map and validation logic still support it.
              ],
            ),
          ),

          // --- Bottom "Continue" Button ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _orangeColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _onNextPressed,
              child: const Text(
                'Continue 1/2',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// --- NEW: Custom widget for each mapping row ---
  Widget _buildMappingRow({
    required AppField field,
    required IconData icon,
    required Color color,
  }) {
    final int? mappedIndex = _mapping[field];
    final String buttonText = mappedIndex != null
        ? widget.csvHeaders[mappedIndex].toString()
        : 'Select Field';

    final String exampleText = _getExampleText(field);

    // Style the button based on selection
    final ButtonStyle buttonStyle = mappedIndex != null
        ? OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    field.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    exampleText,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 130, // Give the button a fixed width
              child: ElevatedButton(
                style: buttonStyle,
                onPressed: () => _showFieldPicker(field),
                child: Text(
                  buttonText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
