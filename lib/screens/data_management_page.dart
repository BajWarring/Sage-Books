import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sage/models/cashbook.dart';
import 'package:sage/screens/import_select_table_page.dart';
import 'package:flutter/services.dart'; // <-- THIS IS THE FIX

class DataManagementPage extends StatefulWidget {
  const DataManagementPage({super.key});
  @override
  State<DataManagementPage> createState() => _DataManagementPageState();
}

class _DataManagementPageState extends State<DataManagementPage> {
  List<Cashbook> _allCashbooks = [];
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _fetchMyCashbooks();
  }

  Future<void> _fetchMyCashbooks() async {
    setState(() => _isLoading = true);
    try {
      final box = await Hive.openBox<Cashbook>('cashbooks');
      _allCashbooks = box.values.toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching cashbooks: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _beginSqliteImport() async {
    // Check if cashbooks exist *before* picking a file
    if (_allCashbooks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot import: No cashbooks are available. Please create one first.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        // Using FileType.any as FileType.custom caused issues
        type: FileType.any,
      );
      if (result != null && result.files.single.path != null) {
        final String filePath = result.files.single.path!;
        // Optional: Add a check here to ensure the selected file *looks* like a database
        // e.g., if (!filePath.toLowerCase().endsWith('.sqlite') && !filePath.toLowerCase().endsWith('.db')) { ... show error ... }
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImportSelectTablePage(
                filePath: filePath,
                allCashbooks: _allCashbooks,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File picking cancelled.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Show a more specific error message based on the exception type if possible
        String errorMessage = 'Error picking file: $e';
        // Now that PlatformException is imported, this check works
        if (e is PlatformException &&
            e.code == 'read_external_storage_denied') {
          errorMessage =
              'Permission denied. Please grant storage access in app settings.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Management')),
      body: Stack(
        children: [
          ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.backup_rounded),
                title: const Text('Data Back-up'),
                subtitle: const Text('Export all data to a single file'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Full backup not implemented yet.'),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.table_view_rounded),
                title: const Text('Import from SQLite'),
                subtitle: const Text(
                  'Import entries from another app\'s .sqlite file',
                ),
                onTap: _beginSqliteImport,
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
