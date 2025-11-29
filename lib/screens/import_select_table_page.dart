import 'package:flutter/material.dart';
import 'package:sage/models/cashbook.dart';
import 'package:sage/screens/import_mapping_page.dart';
import 'package:sage/services/sqlite_importer_service.dart';

class ImportSelectTablePage extends StatefulWidget {
  final String filePath;
  final List<Cashbook> allCashbooks;
  const ImportSelectTablePage({
    super.key,
    required this.filePath,
    required this.allCashbooks,
  });
  @override
  State<ImportSelectTablePage> createState() => _ImportSelectTablePageState();
}

class _ImportSelectTablePageState extends State<ImportSelectTablePage> {
  final SqliteImporterService _importerService = SqliteImporterService();
  Future<List<String>>? _tablesFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tablesFuture = _loadTables();
  }

  @override
  void dispose() {
    _importerService.closeDb();
    super.dispose();
  }

  Future<List<String>> _loadTables() async {
    try {
      await _importerService.openDb(widget.filePath);
      return await _importerService.getTables();
    } catch (e) {
      // Show error and pop
      _showErrorAndPop(e.toString());
      return [];
    }
  }

  void _showErrorAndPop(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    Navigator.of(context).pop();
  }

  Future<void> _onTableSelected(String tableName) async {
    setState(() => _isLoading = true);
    try {
      // 1. Get Column Headers for the selected table
      final List<dynamic> columnHeaders =
          await _importerService.getColumnNames(tableName);
      // 2. Get ALL data rows from that table
      final List<List<dynamic>> dataRows =
          await _importerService.getAllData(tableName);
      if (!mounted) return;

      // 3. Navigate to your existing Mapping Page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ImportMappingPage(
            // --- MODIFIED: Pass table name ---
            tableName: tableName,
            csvHeaders: columnHeaders, // Pass SQL columns as headers
            dataRows: dataRows, // Pass SQL data as rows
            allCashbooks: widget.allCashbooks,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Data Table'),
      ),
      body: Stack(
        children: [
          FutureBuilder<List<String>>(
            future: _tablesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No tables found in this file.'));
              }

              final tables = snapshot.data!;
              return ListView.builder(
                itemCount: tables.length,
                itemBuilder: (context, index) {
                  final tableName = tables[index];
                  return ListTile(
                    leading: const Icon(Icons.table_rows_rounded),
                    title: Text(tableName),
                    subtitle: const Text('Tap to map and import'),
                    onTap: () => _onTableSelected(tableName),
                  );
                },
              );
            },
          ),
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
}
