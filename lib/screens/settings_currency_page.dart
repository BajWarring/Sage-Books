import 'package:flutter/material.dart';
import 'package:sage/main.dart'; // Import main.dart to get 'prefs'

// Simple model for our currency list
class Currency {
  final String code;
  final String name;
  final String symbol;

  Currency({required this.code, required this.name, required this.symbol});
}

class SettingsCurrencyPage extends StatefulWidget {
  const SettingsCurrencyPage({super.key});

  @override
  State<SettingsCurrencyPage> createState() => _SettingsCurrencyPageState();
}

class _SettingsCurrencyPageState extends State<SettingsCurrencyPage> {
  // A sample list of currencies. You can expand this.
  final List<Currency> _currencies = [
    Currency(code: 'USD', name: 'US Dollar', symbol: '\$'),
    Currency(code: 'EUR', name: 'Euro', symbol: '€'),
    Currency(code: 'JPY', name: 'Japanese Yen', symbol: '¥'),
    Currency(code: 'GBP', name: 'British Pound', symbol: '£'),
    Currency(code: 'INR', name: 'Indian Rupee', symbol: '₹'),
    Currency(code: 'AUD', name: 'Australian Dollar', symbol: '\$'),
    Currency(code: 'CAD', name: 'Canadian Dollar', symbol: '\$'),
    Currency(code: 'CHF', name: 'Swiss Franc', symbol: 'CHF'),
  ];

  String _selectedCurrencyCode = 'USD';

  @override
  void initState() {
    super.initState();
    _loadCurrency();
  }

  void _loadCurrency() {
    setState(() {
      _selectedCurrencyCode = prefs.getString('currency_code') ?? 'USD';
    });
  }

  Future<void> _selectCurrency(String code) async {
    await prefs.setString('currency_code', code);
    setState(() {
      _selectedCurrencyCode = code;
    });

    // Pop back to settings after selection
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Currency set to $code')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Currency'),
      ),
      body: ListView.builder(
        itemCount: _currencies.length,
        itemBuilder: (context, index) {
          final currency = _currencies[index];
          final bool isSelected = currency.code == _selectedCurrencyCode;

          return ListTile(
            leading: Text(
              currency.symbol,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            title: Text(currency.name),
            subtitle: Text(currency.code),
            trailing:
                isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
            onTap: () => _selectCurrency(currency.code),
          );
        },
      ),
    );
  }
}
