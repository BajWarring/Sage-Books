import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sage/models/cashbook.dart';
import 'package:sage/models/entry.dart';
import 'package:sage/screens/preview_screen.dart';

// --- MODIFIED IMPORTS ---
import 'dart:typed_data'; // <-- FIX: This import was missing
import 'package:sage/services/report_generator.dart'; // <-- Correct: This file does the PDF work

// --- NEW ENUMS & EXTENSIONS ---
// (This section is unchanged)
// Enums to manage report state
enum SortType { dateTime, amountSize }
enum SortOrder { ascending, descending }

/// Enum for Date Filter options
enum DateFilterType {
  allTime,
  today,
  yesterday,
  thisMonth,
  lastMonth,
  singleDay,
  dateRange
}

/// Enum for Entry Type Filter options
enum EntryFilterType { all, cashIn, cashOut }

/// Helper extension to get display names for DateFilterType
extension DateFilterTypeExtension on DateFilterType {
  String get displayName {
    switch (this) {
      case DateFilterType.allTime:
        return 'All Time';
      case DateFilterType.today:
        return 'Today';
      case DateFilterType.yesterday:
        return 'Yesterday';
      case DateFilterType.thisMonth:
        return 'This Month';
      case DateFilterType.lastMonth:
        return 'Last Month';
      case DateFilterType.singleDay:
        return 'Single Day';
      case DateFilterType.dateRange:
        return 'Date Range';
    }
  }
}

/// Helper extension to get display names for EntryFilterType
extension EntryFilterTypeExtension on EntryFilterType {
  String get displayName {
    switch (this) {
      case EntryFilterType.all:
        return 'All';
      case EntryFilterType.cashIn:
        return 'Cash In';
      case EntryFilterType.cashOut:
        return 'Cash Out';
    }
  }
}
// --- END NEW ENUMS & EXTENSIONS ---


class GenerateReportPage extends StatefulWidget {
  final Cashbook cashbook;
  const GenerateReportPage({super.key, required this.cashbook});

  @override
  State<GenerateReportPage> createState() => _GenerateReportPageState();
}

class _GenerateReportPageState extends State<GenerateReportPage> {
  bool _isLoading = false;
  
  // State for sorting (matches image)
  SortType _sortType = SortType.dateTime;
  SortOrder _sortOrder = SortOrder.descending;

  // State for filters
  DateFilterType _dateFilter = DateFilterType.allTime;
  EntryFilterType _entryFilter = EntryFilterType.all;
  String _categoryFilter = 'All';
  String _paymentModeFilter = 'All';

  // State for date pickers
  DateTime? _selectedSingleDay;
  DateTimeRange? _selectedDateRange;
  // State for dynamic filter lists
  List<String> _uniqueCategories = [];
  List<String> _uniquePaymentModes = [];
  // --- END UPDATED STATE --

  @override
  void initState() {
    super.initState();
    _extractUniqueFilters();
  }

  /// NEW: Populates the filter lists based on entries in this cashbook
  void _extractUniqueFilters() {
    final entries = widget.cashbook.entries?.toList().cast<Entry>() ?? [];
    
    // Get unique, non-null, non-empty categories
    final categories = entries
        .where((e) => e.category != null && e.category!.isNotEmpty)
        .map((e) => e.category!)
        .toSet()
        .toList();
    // Get unique, non-null, non-empty payment methods
    final paymentModes = entries
        .where((e) => e.paymentMethod != null && e.paymentMethod!.isNotEmpty)
        .map((e) => e.paymentMethod!)
        .toSet()
        .toList();
    setState(() {
      _uniqueCategories = categories..sort();
      _uniquePaymentModes = paymentModes..sort();
    });
  }


  /// UPDATED: Applies filters and sorting to the cashbook's entries
  List<Entry> _getProcessedEntries() {
    List<Entry> entries = widget.cashbook.entries?.toList().cast<Entry>() ?? [];
    final now = DateTime.now();

    // --- 1. FILTERING (IMPLEMENTED) --

    // A. Date Filter
    switch (_dateFilter) {
      case DateFilterType.today:
        entries = entries.where((e) => DateUtils.isSameDay(e.dateTime, now)).toList();
        break;
      case DateFilterType.yesterday:
        final yesterday = now.subtract(const Duration(days: 1));
        entries = entries.where((e) => DateUtils.isSameDay(e.dateTime, yesterday)).toList();
        break;
      case DateFilterType.thisMonth:
        entries = entries.where((e) => e.dateTime.year == now.year && e.dateTime.month == now.month).toList();
        break;
      case DateFilterType.lastMonth:
        // Handles year change (e.g., Jan -> Dec)
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        entries = entries.where((e) => e.dateTime.year == lastMonth.year && e.dateTime.month == lastMonth.month).toList();
        break;
      case DateFilterType.singleDay:
        if (_selectedSingleDay != null) {
          entries = entries.where((e) => DateUtils.isSameDay(e.dateTime, _selectedSingleDay!)).toList();
        }
        break;
      case DateFilterType.dateRange:
        if (_selectedDateRange != null) {
          // Normalize start and end to cover full days
          final start = DateUtils.dateOnly(_selectedDateRange!.start);
          final end = DateUtils.dateOnly(_selectedDateRange!.end);
          entries = entries.where((e) {
            final entryDate = DateUtils.dateOnly(e.dateTime);
            return (entryDate.isAfter(start) || entryDate.isAtSameMomentAs(start)) &&
                   (entryDate.isBefore(end) || entryDate.isAtSameMomentAs(end));
          }).toList();
        }
        break;
      case DateFilterType.allTime:
        // No date filter
        break;
    }

    // B. Entry Type Filter
    switch (_entryFilter) {
      case EntryFilterType.cashIn:
        entries = entries.where((e) => e.cashFlow == 'cashIn').toList();
        break;
      case EntryFilterType.cashOut:
        entries = entries.where((e) => e.cashFlow == 'cashOut').toList();
        break;
      case EntryFilterType.all:
        // No type filter
        break;
    }

    // C. Category Filter
    if (_categoryFilter != 'All') {
      entries = entries.where((e) => e.category == _categoryFilter).toList();
    }

    // D. Payment Mode Filter
    if (_paymentModeFilter != 'All') {
      entries = entries.where((e) => e.paymentMethod == _paymentModeFilter).toList();
    }

    // --- 2. SORTING (Unchanged) --
    entries.sort((a, b) {
      int comparison;
      if (_sortType == SortType.dateTime) {
        comparison = a.dateTime.compareTo(b.dateTime);
      } else {
        if (a.cashFlow == b.cashFlow) {
          comparison = a.amount.compareTo(b.amount);
        } else {
          comparison = a.cashFlow.compareTo(b.cashFlow);
        }
      }
      return comparison;
    });
    
    // --- 3. ORDER (Unchanged) --
    if (_sortOrder == SortOrder.descending) {
      entries = entries.reversed.toList();
    }

    return entries;
  }

  /// Main function for handling PDF export (UPDATED)
  Future<void> _generatePdfReport() async {
    setState(() => _isLoading = true);
    try {
      final processedEntries = _getProcessedEntries();
      if (processedEntries.isEmpty) {
        _showSnackbar('No entries found matching your filters.', isError: true);
        setState(() => _isLoading = false);
        return;
      }

      // --- Create Duration String (Unchanged) ---
      String durationString;
      if (_dateFilter == DateFilterType.allTime) {
        durationString = 'All Time';
      } else if (_dateFilter == DateFilterType.singleDay && _selectedSingleDay != null) {
        durationString = DateFormat.yMMMMd().format(_selectedSingleDay!);
      } else if (_dateFilter == DateFilterType.dateRange && _selectedDateRange != null) {
        durationString = '${DateFormat.yMMMMd().format(_selectedDateRange!.start)} - ${DateFormat.yMMMMd().format(_selectedDateRange!.end)}';
      } else {
        durationString = _dateFilter.displayName;
      }


      // --- MODIFIED: Call the new ReportGenerator ---
      final Uint8List pdfData = await ReportGenerator.generateReport(
        widget.cashbook,
        processedEntries,
        durationString, // Pass the duration string
      );
      
      // 2. Show the PDF preview screen (Unchanged)
        if (!mounted) return;
      // Check if the widget is still in the tree
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PreviewScreen(pdfData: pdfData),
        ),
      );
    } catch (e) {
      _showSnackbar('An error occurred: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// (Unchanged)
  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Report'),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 150.0), // Added bottom padding
            children: [
    
              // --- 1. Filter Section --
              Text(
                'Report will be generated for',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
    
              // UPDATED to be interactive
              _buildFilterSection(context),
              const SizedBox(height: 24),

              // --- 2. Sorting Type Section (Unchanged) --
              Text(
                'Sorting Type',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              _buildSortingTiles(), // <-- This function is now fixed
              const SizedBox(height: 24),

              // --- 3. Arranging Order Section (Unchanged) --
              Text(
                'Arranging Order',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              _buildOrderingTiles(), // <-- This function is now fixed
            ],
          ),
          // --- 4. Bottom Buttons (Unchanged) --
          _buildBottomButtons(context), // <-- This function is now fixed

          // --- 5. Loading Overlay (Unchanged) --
          if (_isLoading)
            Container(
              color: Colors.black.withAlpha(128),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  // --- UI Helper Widgets --

  /// UPDATED: Filter section is now interactive
  Widget _buildFilterSection(BuildContext context) {
    String dateFilterName = _dateFilter.displayName;
    // Add extra details for single day/date range
    if (_dateFilter == DateFilterType.singleDay && _selectedSingleDay != null) {
      dateFilterName = DateFormat.yMd().format(_selectedSingleDay!);
    } else if (_dateFilter == DateFilterType.dateRange && _selectedDateRange != null) {
      dateFilterName = 
        '${DateFormat.yMd().format(_selectedDateRange!.start)} - ${DateFormat.yMd().format(_selectedDateRange!.end)}';
    }

    return Wrap(
      spacing: 16.0,
      runSpacing: 8.0,
      children: [
        _buildFilterChip('Duration', dateFilterName, () {
          _showDateFilterDialog();
        }),
        _buildFilterChip('Entry Type', _entryFilter.displayName, () {
          _showEntryTypeFilterDialog();
        }),
        _buildFilterChip('Category', _categoryFilter, () {
          _showCategoryFilterDialog();
        }),
        _buildFilterChip('Payment Mode', _paymentModeFilter, () {
          _showPaymentModeFilterDialog();
        }),
        _buildFilterChip('Search Term', 'None', () {
          _showSnackbar('Search Term filter coming soon!', isError: true);
        }),
      ],
    );
  }

  /// UPDATED: Filter chips are now tappable InkWells
  Widget _buildFilterChip(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            Text(value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    )),
          ],
        ),
      ),
    );
  }

  // --- FIX: UPDATED Sorting/Ordering Widgets for Material 3 ---

  Widget _buildSortingTiles() {
    final theme = Theme.of(context);
    final selectedColor = theme.primaryColor.withAlpha(26);
    final selectedBorder = BorderSide(color: theme.primaryColor, width: 1.5);
    final bool isDateTime = _sortType == SortType.dateTime;

    // --- FIX: Wrap in RadioGroup ---
    return RadioGroup<SortType>(
      groupValue: _sortType,
      onChanged: (val) {
        if (val != null) setState(() => _sortType = val);
      },
      child: Column(
        children: [
          RadioListTile<SortType>(
            title: const Text('Date & Time'),
            subtitle: const Text('List of Entries by Date&Time'),
            value: SortType.dateTime,
            // --- REMOVED groupValue and onChanged ---
            selected: isDateTime,
            selectedTileColor: selectedColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isDateTime ? selectedBorder : BorderSide.none,
            ),
          ),
          const SizedBox(height: 8),
          RadioListTile<SortType>(
            title: const Text('Amount Size'),
            subtitle: const Text('Total in, out & balance'),
            value: SortType.amountSize,
            // --- REMOVED groupValue and onChanged ---
            selected: !isDateTime,
            selectedTileColor: selectedColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: !isDateTime ? selectedBorder : BorderSide.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderingTiles() {
    final theme = Theme.of(context);
    final selectedColor = theme.primaryColor.withAlpha(26);
    final selectedBorder = BorderSide(color: theme.primaryColor, width: 1.5);
    final bool isAscending = _sortOrder == SortOrder.ascending;

    // --- FIX: Wrap in RadioGroup ---
    return RadioGroup<SortOrder>(
      groupValue: _sortOrder,
      onChanged: (val) {
        if (val != null) setState(() => _sortOrder = val);
      },
      child: Column(
        children: [
          RadioListTile<SortOrder>(
            title: const Text('Ascending Order'),
            subtitle: const Text('A-Z, 1-9 and Low To High'),
            value: SortOrder.ascending,
            // --- REMOVED groupValue and onChanged ---
            selected: isAscending,
            selectedTileColor: selectedColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isAscending ? selectedBorder : BorderSide.none,
            ),
          ),
          const SizedBox(height: 8),
          RadioListTile<SortOrder>(
            title: const Text('Descending Order'),
            subtitle: const Text('Z-A, 9-1 and High To Low'),
            value: SortOrder.descending,
            // --- REMOVED groupValue and onChanged ---
            selected: !isAscending,
            selectedTileColor: selectedColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: !isAscending ? selectedBorder : BorderSide.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.table_view_rounded),
              label: const Text('GENERATE SQLite'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              // --- Button disabled as function was removed ---
              onPressed: null, 
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('GENERATE PDF'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: _isLoading ? null : _generatePdfReport,
            ),
          ],
        ),
      ),
    );
  }

  // --- NEW DIALOG FUNCTIONS --

  /// Shows the Date Filter dialog, as seen in the image
  Future<void> _showDateFilterDialog() async {
    // Use StatefulBuilder to manage state *inside* the dialog
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        // Temporary state holders for the dialog
        DateFilterType tempFilter = _dateFilter;
        DateTime? tempSingleDay = _selectedSingleDay;
        DateTimeRange? tempDateRange = _selectedDateRange;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            
            // Helper function to update radio buttons and launch pickers
            void onFilterChanged(DateFilterType? value) async {
              if (value == null) return;

              setModalState(() {
                tempFilter = value;
              });

              // Launch pickers immediately
              if (value == DateFilterType.singleDay) {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedSingleDay ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (picked != null) {
                  setModalState(() {
                    tempSingleDay = picked;
                  });
                } else {
                  // User cancelled, revert
                  setModalState(() { tempFilter = _dateFilter; });
                }
              } else if (value == DateFilterType.dateRange) {
                final DateTimeRange? picked = await showDateRangePicker(
                  context: context,
                  initialDateRange: _selectedDateRange,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (picked != null) {
                  setModalState(() {
                    tempDateRange = picked;
                  });
                } else {
                  // User cancelled, revert
                  setModalState(() { tempFilter = _dateFilter; });
                }
              }
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Dialog Header --
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Select Date Filter',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const Divider(),
                  // --- Radio Options --
                  // --- FIX: Wrap in RadioGroup ---
                  RadioGroup<DateFilterType>(
                    groupValue: tempFilter,
                    onChanged: (val) => onFilterChanged(val),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RadioListTile<DateFilterType>(
                          title: const Text('All Time'),
                          value: DateFilterType.allTime,
                          // --- REMOVED groupValue and onChanged ---
                        ),
                        RadioListTile<DateFilterType>(
                          title: const Text('Today'),
                          value: DateFilterType.today,
                          // --- REMOVED groupValue and onChanged ---
                        ),
                        RadioListTile<DateFilterType>(
                          title: const Text('Yesterday'),
                          value: DateFilterType.yesterday,
                          // --- REMOVED groupValue and onChanged ---
                        ),
                        RadioListTile<DateFilterType>(
                          title: const Text('This Month'),
                          value: DateFilterType.thisMonth,
                          // --- REMOVED groupValue and onChanged ---
                        ),
                        RadioListTile<DateFilterType>(
                          title: const Text('Last Month'),
                          value: DateFilterType.lastMonth,
                          // --- REMOVED groupValue and onChanged ---
                        ),
                        RadioListTile<DateFilterType>(
                          title: Text(
                              'Single Day${tempFilter == DateFilterType.singleDay && tempSingleDay != null ? ': ${DateFormat.yMd().format(tempSingleDay!)}' : ''}'),
                          value: DateFilterType.singleDay,
                          // --- REMOVED groupValue and onChanged ---
                        ),
                        RadioListTile<DateFilterType>(
                          title: Text(
                              'Date Range${tempFilter == DateFilterType.dateRange && tempDateRange != null ? ': ${DateFormat.yMd().format(tempDateRange!.start)} - ${DateFormat.yMd().format(tempDateRange!.end)}' : ''}'),
                          value: DateFilterType.dateRange,
                          // --- REMOVED groupValue and onChanged ---
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  // --- Action Buttons --
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        child: const Text('CLEAR'),
                        onPressed: () {
                          setState(() {
                            _dateFilter = DateFilterType.allTime;
                            _selectedSingleDay = null;
                            _selectedDateRange = null;
                          });
                          Navigator.of(context).pop();
                        },
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        child: const Text('APPLY'),
                        onPressed: () {
                          // Apply the temp state to the main page state
                          setState(() {
                            _dateFilter = tempFilter;
                            _selectedSingleDay = tempSingleDay;
                            _selectedDateRange = tempDateRange;
                          });
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Shows the Entry Type filter dialog
  void _showEntryTypeFilterDialog() {
    _showFilterDialog<EntryFilterType>(
      title: 'Select Entry Type',
      currentSelection: _entryFilter,
      options: EntryFilterType.values,
      getDisplayName: (type) => type.displayName,
      onApply: (newFilter) {
        setState(() => _entryFilter = newFilter);
      },
    );
  }

  /// Shows the Category filter dialog
  void _showCategoryFilterDialog() {
    _showFilterDialog<String>(
      title: 'Select Category',
      currentSelection: _categoryFilter,
      options: ['All', ..._uniqueCategories],
      getDisplayName: (category) => category,
      onApply: (newFilter) {
        setState(() => _categoryFilter = newFilter);
      },
    );
  }

  /// Shows the Payment Mode filter dialog
  void _showPaymentModeFilterDialog() {
    _showFilterDialog<String>(
      title: 'Select Payment Mode',
      currentSelection: _paymentModeFilter,
      options: ['All', ..._uniquePaymentModes],
      getDisplayName: (mode) => mode,
      onApply: (newFilter) {
        setState(() => _paymentModeFilter = newFilter);
      },
    );
  }


  /// Generic modal sheet for simple list selection (Entry Type, Category, etc.)
  Future<void> _showFilterDialog<T>({
    required String title,
    required T currentSelection,
    required List<T> options,
    required String Function(T) getDisplayName,
    required void Function(T) onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        T tempSelection = currentSelection;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Dialog Header --
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      Text(title, style: Theme.of(context).textTheme.titleLarge),
                    ],
                  ),
                  const Divider(),
                  // --- Radio Options --
                  // Constrain height in case of many categories
                  // --- FIX: Wrap in RadioGroup ---
                  RadioGroup<T>(
                    groupValue: tempSelection,
                    onChanged: (value) {
                      if (value != null) {
                        setModalState(() {
                          tempSelection = value;
                        });
                      }
                    },
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options[index];
                          return RadioListTile<T>(
                            title: Text(getDisplayName(option)),
                            value: option,
                            // --- REMOVED groupValue and onChanged ---
                          );
                        },
                      ),
                    ),
                  ),
                  const Divider(),
                  // --- Action Buttons --
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FilledButton(
                        child: const Text('APPLY'),
                        onPressed: () {
                          onApply(tempSelection);
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
