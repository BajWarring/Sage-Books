import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:sage/models/cashbook.dart';
import 'package:sage/screens/cashbook_detail_screen.dart';
import 'package:sage/utils/transitions.dart';

// --- NEW: Colors from HTML mockup ---
const Color _primaryOrange = Color(0xFFFF6B00);
const Color _creditGreen = Color(0xFF1EA76D);
const Color _debitRed = Color(0xFFD93025);
const Color _textDark = Color(0xFF212121);
const Color _textMedium = Color(0xFF5F5F5F);
const Color _textLight = Color(0xFF757575);
const Color _bgLightGrey = Color(0xFFF9F9F9);
const Color _bgWhite = Color(0xFFFFFFFF);
// --- End New Colors ---

class CashbookTab extends StatelessWidget {
  // This controller is passed from the HomeScreen AppBar
  final TextEditingController searchController;

  const CashbookTab({super.key, required this.searchController});

  // --- Logic moved to HomeScreen or rebuilt as stateless widgets ---
  // (Dialogs for create/edit/delete would need to be called
  // from the HomeScreen or passed in as callbacks)

  // --- Re-using your existing dialog logic (now static or passed) ---
  // For demonstration, I'll keep the navigation logic here.
  // Edit/Delete would be in the PopupMenu.
  
  void _viewDetails(BuildContext context, Cashbook cashbook) {
    Navigator.of(context).push(
      SlideRightRoute(
        page: CashbookDetailScreen(cashbookKey: cashbook.key),
      ),
    );
  }
  
  // NOTE: You will need to refactor _showEditCashbookDialog and
  // _showDeleteCashbookDialog to be accessible here, e.g., by
  // passing them from HomeScreen or making them static helpers.
  // For now, I will just show a snackbar.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLightGrey,
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Cashbook>('cashbooks').listenable(),
        builder: (context, Box<Cashbook> box, _) {
          if (box.values.isEmpty) {
            return const Center(
              child: Text(
                'No cashbooks yet.\nTap "+" to create one!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: _textMedium),
              ),
            );
          }

          final cashbooks = box.values.toList();
          cashbooks.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          
          // Note: You would need to hook up the searchController
          // to this filter logic if you want live filtering.
          // This requires making this a StatefulWidget and adding a listener.

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            itemCount: cashbooks.length + 1, // +1 for title
            separatorBuilder: (context, index) => const SizedBox(height: 15),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildSectionHeader(context);
              }
              
              final cashbook = cashbooks[index - 1];
              return _buildCashbookCard(context, cashbook);
            },
          );
        },
      ),
    );
  }

  // --- NEW: "My Cashbooks" Header ---
  Widget _buildSectionHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 15.0, bottom: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'My Cashbooks',
            style: TextStyle(
              color: _textDark,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Icon(
            Icons.grid_view, // Placeholder for toggle icon
            color: _primaryOrange,
            size: 20,
          ),
        ],
      ),
    );
  }

  // --- NEW: Cashbook Card from HTML ---
  Widget _buildCashbookCard(BuildContext context, Cashbook cashbook) {
    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return InkWell(
      onTap: () => _viewDetails(context, cashbook),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _bgWhite,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            const BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.05),
              blurRadius: 15,
              offset: Offset(0, 4),
            ),
            BoxShadow(
              color: _primaryOrange.withAlpha((0.25 * 255).round()),
              blurRadius: 12,
              spreadRadius: 0,
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section: Title and Menu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cashbook.name,
                        style: const TextStyle(
                          color: _textDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Last updated: ${DateFormat.yMd().add_jm().format(cashbook.updatedAt)}',
                        style: const TextStyle(
                          color: _textLight,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: _textLight),
                  onSelected: (value) {
                    if (value == 'details') {
                      _viewDetails(context, cashbook);
                    } else if (value == 'edit') {
                      // Placeholder - requires refactoring
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Edit logic goes here!')));
                    } else if (value == 'delete') {
                      // Placeholder - requires refactoring
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Delete logic goes here!')));
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'details',
                      child: Text('View Details'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('Edit Info'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Delete Book',
                          style: TextStyle(color: _debitRed)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 15),
            // Bottom Section: Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Cash In',
                  currencyFormat.format(cashbook.totalIn),
                  _creditGreen,
                ),
                _buildStatItem(
                  'Cash Out',
                  currencyFormat.format(cashbook.totalOut),
                  _debitRed,
                ),
                _buildStatItem(
                  'Net Balance',
                  currencyFormat.format(cashbook.netBalance),
                  _textDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- NEW: Helper for the 3 stats on the card ---
  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _textMedium,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}