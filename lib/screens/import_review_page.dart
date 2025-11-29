import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:sage/models/cashbook.dart';
import 'package:sage/models/entry.dart';
import 'package:sage/models/import_field.dart';

// --- HELPER CLASS ---
class ImportableEntry {
  final List<dynamic> rowData;
  final Map<AppField, int> fieldMap;
  bool isSelected;

  // Parsed values
  late DateTime? dateTime;
  late String remarks;
  late String category;
  late String paymentMethod;
  late double amount;
  late String cashFlow; // 'cashIn' or 'cashOut'
  late bool isValid;
  late String errorMessage;

  ImportableEntry(this.rowData, this.fieldMap, {this.isSelected = true}) {
    _parseData();
  }

  String _getStringField(AppField field) {
    if (!fieldMap.containsKey(field)) return '';
    int index = fieldMap[field]!;
    if (index >= rowData.length) return '';
    return rowData[index].toString();
  }

  static double? _parseAmount(String amountStr) {
    if (amountStr.isEmpty) return null;
    // Remove currency symbols, commas, and spaces
    final cleanStr = amountStr.replaceAll(RegExp(r'[\$,€,₹,\s]'), '');
    return double.tryParse(cleanStr);
  }

  // --- *** UPDATED ROBUST PARSER *** ---
  static DateTime? _parseDateTime(String dateStr, String timeStr) {
    if (dateStr.isEmpty) return null;

    // Combine date and time if time is separate
    String combinedStr =
        timeStr.isEmpty ? dateStr.trim() : "${dateStr.trim()} ${timeStr.trim()}";

    // 1. Try to parse as an ISO 8601 string (most reliable)
    final isoParse = DateTime.tryParse(combinedStr);
    if (isoParse != null) return isoParse;

    // 2. Try to parse as a Unix/Epoch timestamp (in seconds)
    final int? unixTimestamp = int.tryParse(combinedStr);
    if (unixTimestamp != null) {
      // Check if it's likely a timestamp (e.g., a 10-digit number)
      if (combinedStr.length == 10) {
        return DateTime.fromMillisecondsSinceEpoch(unixTimestamp * 1000);
      }
    }

    // 3. Try a list of common string formats
    final List<String> formatsToTry = [
      // --- *** FIX IS HERE *** ---
      // Added format for '07 March 2025 5:30 pm'
      "d MMMM y h:m a", // DD Month YYYY hh:mm AM/PM
      "d MMMM y H:m",   // DD Month YYYY HH:MM
      // --- *** END OF FIX *** ---

      // Combined Date + Time (from user list)
      "d/M/y H:m", // DD/MM/YYYY HH:MM
      "d-M-y H:m:s", // DD-MM-YYYY HH:MM:SS
      "y-M-d H:m", // YYYY-MM-DD HH:MM
      "y-M-d H:m:s", // YYYY-MM-DD HH:MM:SS
      "y/M/d H:m:s", // YYYY/MM/DD HH:MM:SS
      "d/M/y h:m a", // DD/MM/YYYY HH:MM AM/PM
      "M/d/y h:m:s a", // MM/DD/YYYY HH:MM:SS AM/PM
      "y:M:d H:m:s", // YYYY:MM:DD HH:MM:SS
      "d-M-yy H.m.s", // DD-MM-YY HH.MM.SS
      "yyyyMMddHHmmss", // YYYYMMDDHHMMSS
      
      // Date Only (from user list)
      "d/M/y", // DD/MM/YYYY
      "d-M-y", // DD-MM-YYYY
      "d.M.y", // DD.MM.YYYY
      "d LLL y", // DD Mon YYYY
      "d-MMM-y", // DD-MMM-YYYY
      "d-LLL-yy", // DD-Mon-YY
      "d/M/yy", // DD/MM/YY
      "M/d/y", // MM/DD/YYYY
      "M-d-y", // MM-DD-YYYY
      "M.d.y", // MM.DD.YYYY
      "LLL d, y", // Mon DD, YYYY
      "MMMM d, y", // MMM DD, YYYY
      "y/M/d", // YYYY/MM/DD
      "y-M-d", // YYYY-MM-DD
      "y.M.d", // YYYY.MM.DD
      "yyyyMMdd", // YYYYMMDD
      "d MMMM y", // DD Month YYYY
    ];

    for (final format in formatsToTry) {
      try {
        return DateFormat(format).parseLoose(combinedStr);
      } catch (e) {
        // Ignore and try next format
      }
    }

    // 4. If all parsing fails
    return null;
  }
  // --- *** END OF DATE PARSER *** ---


  void _parseData() {
    try {
      final dateStr = _getStringField(AppField.date);
      final timeStr = _getStringField(AppField.time);
      dateTime = _parseDateTime(dateStr, timeStr);

      // This is the error from the screenshot
      if (dateTime == null) {
        throw Exception("Invalid date format: '$dateStr'");
      }

      remarks = _getStringField(AppField.remarks);
      category = _getStringField(AppField.category);
      paymentMethod = _getStringField(AppField.paymentMethod);

      final double? amountIn = _parseAmount(_getStringField(AppField.amountIn));
      final double? amountOut = _parseAmount(_getStringField(AppField.amountOut));
      final double? amountSingle =
          _parseAmount(_getStringField(AppField.amountSingleColumn));

      if (amountSingle != null) {
        amount = amountSingle.abs();
        cashFlow = amountSingle < 0 ? 'cashOut' : 'cashIn';
      } else if (amountIn != null) {
        amount = amountIn;
        cashFlow = 'cashIn';
      } else if (amountOut != null) {
        amount = amountOut.abs();
        cashFlow = 'cashOut';
      } else {
        throw Exception("No valid amount found.");
      }

      if (amount == 0) {
        throw Exception("Amount is zero.");
      }

      isValid = true;
      errorMessage = '';
    } catch (e) {
      isValid = false;
      // Use the specific exception message (e.g., "Invalid date format: ...")
      errorMessage = e.toString().replaceFirst("Exception: ", ""); 
      
      // Assign defaults to avoid null errors in UI
      dateTime = DateTime.now();
      remarks = "Error: $errorMessage";
      category = "";
      paymentMethod = "";
      amount = 0;
      cashFlow = "cashOut";
    }
  }

  // Getters for the UI
  String get title => remarks.isNotEmpty ? remarks : '(No Remarks)';
  String get dateString =>
      dateTime != null
          ? DateFormat('dd/MM/yyyy').format(dateTime!)
          : 'Invalid Date';
  String get amountString =>
      NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 0)
          .format(amount);
}

// --- MAIN WIDGET ---

class ImportReviewPage extends StatefulWidget {
  final List<List<dynamic>> dataRows;
  final List<Cashbook> allCashbooks;
  final Map<int, AppField> columnMapping;
  final String tableName; // --- Passed from mapping page ---

  const ImportReviewPage({
    super.key,
    required this.dataRows,
    required this.allCashbooks,
    required this.columnMapping,
    required this.tableName,
  });
  @override
  State<ImportReviewPage> createState() => _ImportReviewPageState();
}

class _ImportReviewPageState extends State<ImportReviewPage> {
  Cashbook? _selectedCashbook;
  bool _isLoading = false;
  bool _selectAll = true;
  List<ImportableEntry> _importableEntries = [];
  late Map<AppField, int> _fieldMap;

  static const Color _orangeColor = Color(0xFFE64A19); // Deep Orange
  static const Color _greenColor = Color(0xFF388E3C); // Green
  static const Color _redColor = Color(0xFFD32F2F); // Red

  @override
  void initState() {
    super.initState();
    if (widget.allCashbooks.isNotEmpty) {
      _selectedCashbook = widget.allCashbooks.first;
    }
    _processMappedEntries();
  }

  void _processMappedEntries() {
    _fieldMap = {};
    widget.columnMapping.forEach((index, field) {
      if (field != AppField.ignore) {
        _fieldMap[field] = index;
      }
    });

    setState(() {
      _importableEntries = widget.dataRows
          .map((row) => ImportableEntry(row, _fieldMap, isSelected: true))
          .toList();
    });
  }

  Future<void> _saveImportedEntries() async {
    if (_selectedCashbook == null) {
      _showError("Please select a cashbook to import into.");
      return;
    }

    final selectedEntries =
        _importableEntries.where((e) => e.isSelected && e.isValid).toList();
        
    if (selectedEntries.isEmpty) {
      _showError("No valid entries are selected to import.");
      return;
    }

    setState(() => _isLoading = true);

    final entryBox = Hive.box<Entry>('entries');
    Cashbook? cashbookToUpdate =
        Hive.box<Cashbook>('cashbooks').get(_selectedCashbook!.key);
    if (cashbookToUpdate == null) {
      _showError("Error: The selected cashbook could not be found.");
      setState(() => _isLoading = false);
      return;
    }

    List<Entry> entriesToSave = [];
    List<String> errorMessages = [];

    for (final entry in selectedEntries) {
      final newEntry = Entry(
        dateTime: entry.dateTime!,
        remarks: entry.remarks.isNotEmpty ? entry.remarks : 'Imported Entry',
        category: entry.category.isNotEmpty ? entry.category : null,
        paymentMethod:
            entry.paymentMethod.isNotEmpty ? entry.paymentMethod : null,
        amount: entry.amount,
        cashFlow: entry.cashFlow,
      );
      entriesToSave.add(newEntry);
    }

    if (entriesToSave.isNotEmpty) {
      try {
        await entryBox.addAll(entriesToSave);
        cashbookToUpdate.entries ??= HiveList(entryBox);
        cashbookToUpdate.entries!.addAll(entriesToSave);
        cashbookToUpdate.updatedAt = DateTime.now();
        await cashbookToUpdate.save();
      } catch (e) {
        errorMessages.add("Error saving to database: ${e.toString()}");
      }
    }

    final failedEntries = _importableEntries.where((e) => e.isSelected && !e.isValid).toList();
    for (var entry in failedEntries) {
        final rowNumber = widget.dataRows.indexOf(entry.rowData) + 2;
        errorMessages.add("Skipped row $rowNumber: ${entry.errorMessage}");
    }

    setState(() => _isLoading = false);
    if (errorMessages.isNotEmpty) {
      _showErrorDialog(
          "Import complete with some entries skipped.", errorMessages.join('\n'));
    } else if (entriesToSave.isEmpty) {
      _showError("No valid entries were found to import.");
    } else {
      _showSuccessAndExit(
          "Successfully imported ${entriesToSave.length} entries into '${cashbookToUpdate.name}'.");
    }
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      // Only select/deselect VALID entries
      for (var entry in _importableEntries) {
        if (entry.isValid) {
          entry.isSelected = _selectAll;
        }
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessAndExit(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- *** FIX IS HERE *** ---
    // Renamed 'Select All' to 'Select All Valid' to match image
    final String selectAllText = 'Select All Valid';
    // --- *** END OF FIX *** ---
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Review & Import'), // <-- Title from image
            Text(
              "Found ${_importableEntries.length} potential entries", // <-- Subtitle from image
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Row(
              children: [
                Text(selectAllText), // <-- Use new text
                const SizedBox(width: 4),
                Checkbox( // <-- Use a standard Checkbox to match image
                  value: _selectAll,
                  onChanged: _toggleSelectAll,
                  activeColor: _orangeColor,
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                margin: const EdgeInsets.all(16.0),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<Cashbook>(
                      initialValue: _selectedCashbook,
                      items: widget.allCashbooks.map((cb) {
                        return DropdownMenuItem(
                            value: cb, child: Text(cb.name));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCashbook = value;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Import into Cashbook',
                        border: InputBorder.none,
                      ),
                      isExpanded: true,
                    ),
                  ),
                ),
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: _importableEntries.length,
                  itemBuilder: (context, index) {
                    final entry = _importableEntries[index];
                    return _buildEntryCard(entry);
                  },
                ),
              ),
            ],
          ),

          // --- *** FIX IS HERE *** ---
          // Updated button text to match image
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
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
                onPressed: _isLoading ? null : _saveImportedEntries,
                child: const Text(
                  'Import Selected Entries', // <-- Text from image
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          // --- *** END OF FIX *** ---

          if (_isLoading)
            Container(
              color: Colors.black.withAlpha(128),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildEntryCard(ImportableEntry entry) {
    // --- *** FIX IS HERE *** ---
    // This now matches the "Invalid Entry" card from the screenshot
    if (!entry.isValid) {
      return Card(
         elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        margin: const EdgeInsets.only(bottom: 12.0),
        color: Colors.red.shade50, // Light red background
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: _redColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invalid Entry: ${entry.errorMessage}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _redColor,
                      ),
                    ),
                     const SizedBox(height: 2),
                    Text(
                      // Show the raw row data
                      entry.rowData.join(', '),
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    // --- *** END OF FIX *** ---


    final bool isCashIn = entry.cashFlow == 'cashIn';
    final Color amountColor = isCashIn ? _greenColor : _redColor;
    final IconData iconData =
        isCashIn ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {
          setState(() {
            entry.isSelected = !entry.isSelected;
            if (!entry.isSelected) _selectAll = false;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: amountColor.withAlpha(26),
                child: Icon(iconData, color: amountColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          entry.dateString,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Text(
                          ', ',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          entry.amountString,
                          style: TextStyle(
                            color: amountColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // --- *** FIX IS HERE *** ---
              // Use a standard Checkbox to match the image
              Checkbox(
                value: entry.isSelected,
                onChanged: (val) {
                  setState(() {
                    entry.isSelected = val ?? false;
                    if (!entry.isSelected) _selectAll = false;
                  });
                },
                activeColor: _orangeColor,
              )
              // --- *** END OF FIX *** ---
            ],
          ),
        ),
      ),
    );
  }
}
