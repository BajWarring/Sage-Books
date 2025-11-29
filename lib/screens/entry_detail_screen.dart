import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:sage/models/cashbook.dart'; // <-- FIX: Import Cashbook
import 'package:sage/models/entry.dart';
import 'package:sage/screens/entry_form_screen.dart';
import 'package:sage/utils/transitions.dart'; // Import the new transitions

// --- FIX: Added missing color definitions from the new theme ---
const Color _detailOrange = Color(0xFFFF6B00); // Using the new primary orange
const Color _detailGreen = Color(0xFF1EA76D);
const Color _detailRed = Color(0xFFD93025);
const Color _textDark = Color(0xFF212121);
const Color _textMedium = Color(0xFF5F5F5F);
const Color _bgLightGrey = Color(0xFFF9F9F9);
const Color _bgWhite = Color(0xFFFFFFFF);
// --- End of FIX ---

class EntryDetailScreen extends StatelessWidget {
  final dynamic entryKey;
  final String cashbookName;
  final dynamic cashbookKey; // <-- FIX: Added this

  const EntryDetailScreen({
    super.key,
    required this.entryKey,
    required this.cashbookName,
    required this.cashbookKey, // <-- FIX: Added this
  });

  // --- MODIFIED: Delete logic now updates the cashbook ---
  Future<void> _deleteEntry(BuildContext context, Entry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete',
                  style: TextStyle(color: _detailRed))),
        ],
      ),
    );

    if (confirmed ?? false) {
      // --- THIS IS THE FIX ---
      // 1. Find the parent cashbook
      final cashbookBox = Hive.box<Cashbook>('cashbooks');
      Cashbook? cashbook = cashbookBox.get(cashbookKey); // Use the passed-in key

      // 2. Delete the entry
      await entry.delete(); 

      // 3. Update the cashbook to trigger the listener on the previous screen
      if (cashbook != null) {
        cashbook.updatedAt = DateTime.now();
        await cashbook.save();
      }
      // --- END OF FIX ---

      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  // --- Existing changelog logic (unchanged) ---
  Widget _buildChangeLog(Entry entry) {
    final log = entry.changeLog ?? [];

    if (log.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: const ListTile(
          title: Text('None'),
        ),
      );
    }

    final reversedLog = log.reversed.toList();

    return Column(
      children: reversedLog.map((logItem) {
        bool isTimestamp = logItem.startsWith("Edited on:");
        bool isChange = logItem.contains("→");

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          color: isTimestamp ? Colors.grey.shade100 : Colors.white,
          child: ListTile(
            title: Text(
              isTimestamp
                  ? logItem
                  : (isChange
                      ? logItem.split(":")[0]
                      : logItem),
              style: TextStyle(
                fontWeight: isTimestamp ? FontWeight.bold : FontWeight.normal,
                fontSize: isTimestamp ? 14 : 15,
              ),
            ),
            subtitle: isChange
                ? Text(
                    logItem.substring(logItem.indexOf(":") + 1).trim(),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder(
      valueListenable: Hive.box<Entry>('entries').listenable(),
      builder: (context, Box<Entry> box, _) {
        final entry = box.get(entryKey);

        if (entry == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(child: Text('Entry not found.')),
          );
        }

        final bool isCashIn = entry.cashFlow == 'cashIn';
        final Color primaryColor = isCashIn ? _detailGreen : _detailRed;
        
        return Scaffold(
          backgroundColor: _bgLightGrey,
          // --- MODIFIED: AppBar from PNG mockup ---
          appBar: AppBar(
            backgroundColor: _bgLightGrey,
            elevation: 0,
            iconTheme: const IconThemeData(color: _detailOrange),
            title: const Text(
              'Entry Details',
              style: TextStyle(
                color: _detailOrange,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline, color: _detailOrange),
                onPressed: () => _deleteEntry(context, entry),
              ),
            ],
          ),
          // --- MODIFIED: Bottom Share Button from PNG mockup ---
          bottomNavigationBar: _buildShareButton(context),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // --- MODIFIED: Info Card from PNG mockup ---
              _buildInfoCard(context, entry, primaryColor),
              const SizedBox(height: 24),
              // --- MODIFIED: Created On section from PNG mockup ---
              _buildCreatedOnSection(context, entry),
              const SizedBox(height: 24),
              // --- MODIFIED: Changes in Entry section from PNG mockup ---
              Padding(
                padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                child: Text(
                  'Changes in Entry',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold, color: _detailOrange),
                ),
              ),
              _buildChangeLog(entry), // Your existing logic works here
            ],
          ),
        );
      },
    );
  }

  // --- NEW: Info Card from PNG mockup ---
  Widget _buildInfoCard(BuildContext context, Entry entry, Color primaryColor) {
    final currencyFormat = NumberFormat.currency(
        locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final String tag = entry.paymentMethod ?? 'Cash';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _detailOrange, width: 1.0), // Thinner border
      ),
      color: _bgWhite,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Side: Title and Tag
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.cashFlow == 'cashIn' ? 'Cash In' : 'Cash Out',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300)
                      ),
                      child: Text(
                        tag, // Using the dynamic tag
                        style: const TextStyle(
                          color: _detailOrange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                // Right Side: Date and Time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      DateFormat('dd MMMM yyyy').format(entry.dateTime),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15, color: _textDark),
                    ),
                    Text(
                      DateFormat('hh:mm a').format(entry.dateTime),
                      style: const TextStyle(color: _textMedium, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Amount
            Text(
              '${entry.cashFlow == 'cashIn' ? '+' : '−'}${currencyFormat.format(entry.amount)}',
              style: TextStyle(
                color: primaryColor,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Remarks
            Text(
              entry.remarks,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _textDark,
              ),
            ),
            const Divider(height: 32),
            // Edit Button
            Center(
              child: TextButton.icon(
                icon: const Icon(
                  Icons.edit_outlined,
                  color: _detailOrange,
                  size: 18,
                ),
                label: const Text(
                  'Edit Entry >',
                  style: TextStyle(
                    color: _detailOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    SlideRightRoute(
                      page: EntryFormScreen(
                        cashbookName: cashbookName,
                        entryToEdit: entry, // Pass the entry
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- NEW: Created On Section from PNG mockup ---
  Widget _buildCreatedOnSection(BuildContext context, Entry entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Created on',
            style: TextStyle(color: _textMedium, fontSize: 14),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('dd MMMM yyyy').format(entry.dateTime),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _textDark),
              ),
              Text(
                DateFormat('hh:mm a').format(entry.dateTime),
                style: const TextStyle(color: _textMedium, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- NEW: Share Button from PNG mockup ---
  Widget _buildShareButton(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      color: _bgLightGrey,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: _detailOrange,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Share not implemented yet.')),
          );
        },
        child: const Text(
          'Share Entry',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}