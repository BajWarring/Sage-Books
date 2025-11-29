import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:sage/models/cashbook.dart';
import 'package:sage/models/entry.dart';
import 'package:sage/models/running_balance_entry.dart';
import 'package:sage/screens/entry_detail_screen.dart';
import 'package:sage/screens/entry_form_screen.dart';
import 'package:sage/screens/generate_report_page.dart';
import 'package:sage/main.dart'; // Import for textPrimary, textSecondary
import 'package:sage/utils/transitions.dart'; // Import the new transitions
import 'package:sage/models/cashflow.dart'; // Import the new enum file

// --- NEW: Colors from HTML mockup ---
const Color _primaryOrange = Color(0xFFFF6B00);
const Color _creditGreen = Color(0xFF1EA76D);
const Color _debitRed = Color(0xFFD93025);
const Color _buttonGreen = Color(0xFF2DB934);
const Color _buttonRed = Color(0xFFE53935);
const Color _textMedium = Color(0xFF5F5F5F);
const Color _textLight = Color(0xFF757575);
const Color _bgLightGrey = Color(0xFFF9F9F9);
const Color _borderLight = Color(0xFFECECEC);
const Color _tagBg = Color(0xFFFEF3E8);
const Color _tagText = Color(0xFFD9832E);
const Color _bgWhite = Color(0xFFFFFFFF);
// --- End New Colors ---

class CashbookDetailScreen extends StatefulWidget {
  final dynamic cashbookKey;
  const CashbookDetailScreen({super.key, required this.cashbookKey});
  @override
  State<CashbookDetailScreen> createState() => _CashbookDetailScreenState();
}

class _CashbookDetailScreenState extends State<CashbookDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchTerm = _searchController.text;
    });
  }

  // --- Logic for navigation (unchanged) ---
  void _navigateToAddEntry(BuildContext context, CashFlow defaultFlow) {
    Navigator.of(context).push(
      SlideRightRoute(
        page: EntryFormScreen(
          cashbookName:
              Hive.box<Cashbook>('cashbooks').get(widget.cashbookKey)!.name,
          initialCashFlow: defaultFlow,
        ),
      ),
    );
  }

  // --- Logic for running balance (unchanged) ---
  List<RunningBalanceEntry> _getRunningBalanceEntries(
      List<Entry> allEntries) {
    List<Entry> sortedEntries = List.from(allEntries);
    sortedEntries.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    List<RunningBalanceEntry> runningBalanceEntries = [];
    double currentBalance = 0.0;
    for (Entry entry in sortedEntries) {
      if (entry.cashFlow == 'cashIn') {
        currentBalance += entry.amount;
      } else if (entry.cashFlow == 'cashOut') {
        currentBalance -= entry.amount;
      }
      runningBalanceEntries.add(RunningBalanceEntry(
        entry: entry,
        runningBalance: currentBalance,
      ));
    }

    return runningBalanceEntries.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return ValueListenableBuilder<Box<Cashbook>>(
      valueListenable: Hive.box<Cashbook>('cashbooks').listenable(),
      builder: (context, box, _) {
        final currentCashbook = box.get(widget.cashbookKey);

        if (currentCashbook == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(child: Text('Cashbook not found.')),
          );
        }

        final String cashbookName = currentCashbook.name;

        // --- All existing data/filter/group logic is preserved ---
        List<Entry> allEntries =
            currentCashbook.entries?.cast<Entry>().toList() ?? [];
        List<Entry> filteredEntries = allEntries.where((entry) {
          final remarkMatch =
              entry.remarks.toLowerCase().contains(_searchTerm.toLowerCase());
          final categoryMatch = entry.category
                  ?.toLowerCase()
                  .contains(_searchTerm.toLowerCase()) ??
              false;
          final dateMatch = DateFormat('dd MMMM yyyy')
              .format(entry.dateTime)
              .toLowerCase()
              .contains(_searchTerm.toLowerCase());
          return remarkMatch || categoryMatch || dateMatch;
        }).toList();

        List<RunningBalanceEntry> displayedEntries =
            _getRunningBalanceEntries(filteredEntries);

        filteredEntries.sort((a, b) => b.dateTime.compareTo(a.dateTime));
        final Map<DateTime, List<RunningBalanceEntry>> groupedEntries = {};
        for (var rbEntry in displayedEntries) {
          if (filteredEntries.any((fe) => fe.key == rbEntry.entry.key)) {
            final dateOnly = DateTime(rbEntry.entry.dateTime.year,
                rbEntry.entry.dateTime.month, rbEntry.entry.dateTime.day);
            if (!groupedEntries.containsKey(dateOnly)) {
              groupedEntries[dateOnly] = [];
            }
            groupedEntries[dateOnly]!.add(rbEntry);
          }
        }
        final sortedDates = groupedEntries.keys.toList()
          ..sort((a, b) => b.compareTo(a));
        // --- End of existing logic ---

        return Scaffold(
          backgroundColor: _bgLightGrey,
          // --- MODIFIED: AppBar from HTML ---
          appBar: _buildAppBar(currentCashbook, theme),
          // --- MODIFIED: Bottom bar from HTML ---
          bottomNavigationBar: _buildBottomFabBar(context),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          // --- MODIFIED: Body layout from HTML (using CustomScrollView) ---
          body: CustomScrollView(
            slivers: [
              // Sliver 1: Search Bar
              SliverToBoxAdapter(
                child: _buildSearchBar(),
              ),
              // Sliver 2: Summary Card
              SliverToBoxAdapter(
                child: _buildSummaryCard(currentCashbook, currencyFormat, theme),
              ),
              // Sliver 3: "Showing X entries" text
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
                  child: Align(
                    alignment: Alignment.centerLeft, // As per HTML
                    child: Text(
                      'Showing ${displayedEntries.length} of ${allEntries.length} entries',
                      style: const TextStyle(
                        fontSize: 13,
                        color: _textLight,
                      ),
                    ),
                  ),
                ),
              ),
              // Sliver 4: The list of entries
              _buildSliverEntryList(
                  displayedEntries, _searchTerm, sortedDates, groupedEntries,
                  currencyFormat, cashbookName),
            ],
          ),
        );
      },
    );
  }

  // --- NEW: AppBar from HTML ---
  PreferredSize _buildAppBar(Cashbook currentCashbook, ThemeData theme) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(65.0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
        decoration: const BoxDecoration(
          color: _bgLightGrey,
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: textPrimary),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Text(
                currentCashbook.name,
                style: const TextStyle(
                  color: _primaryOrange,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: textPrimary),
                onSelected: (value) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$value not implemented yet.')),
                  );
                },
                itemBuilder: (BuildContext context) {
                  return [
                    const PopupMenuItem(
                      value: 'Book Details',
                      child: Text('Book Details'),
                    ),
                    const PopupMenuItem(
                      value: 'Book History',
                      child: Text('Book History'),
                    ),
                    const PopupMenuItem(
                      value: 'Delete Book',
                      child: Text('Delete Book',
                          style: TextStyle(color: _debitRed)),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- NEW: Search Bar from HTML ---
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: _bgLightGrey,
          border: Border.all(color: _borderLight),
          borderRadius: BorderRadius.circular(10),
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search By Remarks & Date',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: const Icon(Icons.search, size: 20, color: _textMedium),
            suffixIcon:
                const Icon(Icons.calendar_today, size: 16, color: _textMedium),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          ),
        ),
      ),
    );
  }

  // --- NEW: Summary Card from HTML ---
  Widget _buildSummaryCard(Cashbook currentCashbook,
      NumberFormat currencyFormat, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bgWhite,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.05 * 255).round()),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: _primaryOrange.withAlpha((0.1 * 255).round()),
            blurRadius: 10,
            spreadRadius: 0,
          )
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Net Balance',
            style: TextStyle(
              color: _textMedium,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currencyFormat.format(currentCashbook.netBalance),
            style: const TextStyle(
              color: textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total In ( + )',                        style: TextStyle(fontSize: 14, color: _textMedium)),
                    Text(
                      currencyFormat.format(currentCashbook.totalIn),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _creditGreen),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Total Out ( - )',                        style: TextStyle(fontSize: 14, color: _textMedium)),
                    Text(
                      currencyFormat.format(currentCashbook.totalOut),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _debitRed),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(color: _borderLight, height: 1),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                SlideRightRoute(
                  page: GenerateReportPage(cashbook: currentCashbook),
                ),
              );
            },
            child: const Text(
              'View Reports >',
              style: TextStyle(
                color: _primaryOrange,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        ],
      ),
    );
  }

  // --- NEW: Helper function to build the SliverList or SliverFillRemaining ---
  Widget _buildSliverEntryList(
    List<RunningBalanceEntry> displayedEntries,
    String searchTerm,
    List<DateTime> sortedDates,
    Map<DateTime, List<RunningBalanceEntry>> groupedEntries,
    NumberFormat currencyFormat,
    String cashbookName,
  ) {
    if (displayedEntries.isEmpty && searchTerm.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text('No entries yet. Tap + to add one!')),
      );
    }
    if (displayedEntries.isEmpty && searchTerm.isNotEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text('No entries found for your search.')),
      );
    }

    // --- This is the main list of entries ---
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, dateIndex) {
          final date = sortedDates[dateIndex];
          final entriesOnDate = groupedEntries[date]!
            ..sort(
                (a, b) => b.entry.dateTime.compareTo(a.entry.dateTime));

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateGroupHeader(date, Theme.of(context)),
                const SizedBox(height: 10),
                ...entriesOnDate.map((rbEntry) {
                  return _buildTransactionItem(
                      rbEntry, currencyFormat, cashbookName);
                }),
                if (dateIndex == sortedDates.length - 1)
                  const SizedBox(height: 100), // Padding at the end
              ],
            ),
          );
        },
        childCount: sortedDates.length,
      ),
    );
  }

  // --- NEW: Date Group Header from HTML ---
  Widget _buildDateGroupHeader(DateTime date, ThemeData theme) {
    String formattedDate = DateFormat('dd MMMM yyyy').format(date);
    // Note: The HTML shows full dates, so I am not using "Today/Yesterday"
    // to match it exactly.

    return Padding(
      padding: const EdgeInsets.only(top: 15.0),
      child: Text(
        formattedDate,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _primaryOrange,
        ),
      ),
    );
  }

  // --- NEW: Entry Row from HTML ---
  Widget _buildTransactionItem(RunningBalanceEntry rbEntry,
      NumberFormat currencyFormat, String cashbookName) {
    final entry = rbEntry.entry;
    final isCashIn = entry.cashFlow == 'cashIn';
    final Color amountColor = isCashIn ? _creditGreen : _debitRed;
    final String tag = entry.paymentMethod ?? 'Cash';

    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      decoration: BoxDecoration(
        color: _bgWhite,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.03 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: _primaryOrange.withAlpha((0.08 * 255).round()),
            blurRadius: 8,
            spreadRadius: 0,
          )
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Navigator.of(context).push(
            SlideRightRoute(
              page: EntryDetailScreen(
                entryKey: entry.key,
                cashbookName: cashbookName,
                cashbookKey: widget.cashbookKey, // <-- FIX: Pass the key
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Side: Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          DateFormat('hh:mm a').format(entry.dateTime),
                          style: const TextStyle(
                            color: _textLight,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _tagBg,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              color: _tagText,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.remarks,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Right Side: Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isCashIn ? '+' : '−'}${currencyFormat.format(entry.amount)}',
                    style: TextStyle(
                      color: amountColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Balance: ${currencyFormat.format(rbEntry.runningBalance)}',
                    style: const TextStyle(
                      color: _textLight,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- NEW: Bottom App Bar from HTML ---
  Widget _buildBottomFabBar(BuildContext context) {
    return BottomAppBar(
      height: 75,
      color: _bgLightGrey,
      elevation: 0,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: _borderLight, width: 1)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Row(
          children: [
            Expanded(
              child: _buildGradientButton(
                context: context,
                label: 'Cash In',
                icon: Icons.add,
                color: _buttonGreen,
                onTap: () => _navigateToAddEntry(context, CashFlow.cashIn),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildGradientButton(
                context: context,
                label: 'Cash Out',
                icon: Icons.remove,
                color: _buttonRed,
                onTap: () => _navigateToAddEntry(context, CashFlow.cashOut),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- NEW: Button Style from HTML (WITH FIX) ---
  Widget _buildGradientButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    // --- FIX: Replaced ElevatedButton with a more flexible Row ---
    // This gives us full control and fixes the layout/overflow bug.
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: Colors.white),
              const SizedBox(width: 8), // Reduced space
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}