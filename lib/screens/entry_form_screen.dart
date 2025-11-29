import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'package:sage/models/cashbook.dart';
import 'package:sage/models/entry.dart';
import 'package:sage/models/cashflow.dart'; // Import the enum file
// --- NEW: Import for the new date/time picker ---
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    // ignore: library_prefixes
    as Dtp;

// --- NEW: Colors from HTML mockup ---
const Color _primaryOrange = Color(0xFFFF6B00);
const Color _buttonGreen = Color(0xFF2DB934);
const Color _buttonRed = Color(0xFFE53935);
const Color _textDark = Color(0xFF212121);
const Color _textMedium = Color(0xFF5F5F5F);
const Color _bgLightGrey = Color(0xFFF9F9F9);
const Color _bgWhite = Color(0xFFFFFFFF);
const Color _borderLight = Color(0xFFECECEC);
const Color _inactiveOrangeBg = Color(0xFFFEF3E8);
const Color _activeOrangeDark = Color(0xFFE65100);
// --- End New Colors ---

class EntryFormScreen extends StatefulWidget {
  final String cashbookName;
  final CashFlow? initialCashFlow;
  final Entry? entryToEdit;

  const EntryFormScreen({
    super.key,
    required this.cashbookName,
    this.initialCashFlow,
    this.entryToEdit,
  });

  @override
  State<EntryFormScreen> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends State<EntryFormScreen> {
  final _formKey = GlobalKey<FormState>();

  CashFlow _cashFlow = CashFlow.cashIn;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String? _selectedCategory;
  String _selectedPaymentMethod = 'Cash';

  final _amountController = TextEditingController();
  final _remarksController = TextEditingController();
  // --- FIX: Add controllers for date and time fields ---
  late TextEditingController _dateController;
  late TextEditingController _timeController;

  final _categories = [
    '💼 Salary',
    '🍔 Food & Dining',
    '🏠 Rent',
    '⚡ Utilities',
    '🚗 Transportation',
    '🛒 Shopping',
    '💊 Healthcare',
    '🎓 Education',
    '🎉 Entertainment',
    '📱 Subscriptions',
    '💰 Investment',
    '📦 Supplies',
  ];
  final _paymentMethods = ['Cash', 'Online', 'UPI', 'Cheque'];

  bool get _isEditing => widget.entryToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final entry = widget.entryToEdit!;
      _cashFlow =
          entry.cashFlow == 'cashIn' ? CashFlow.cashIn : CashFlow.cashOut;
      _selectedDate = entry.dateTime;
      _selectedTime = TimeOfDay.fromDateTime(entry.dateTime);
      _amountController.text = entry.amount.toStringAsFixed(0);
      _remarksController.text = entry.remarks;
      _selectedCategory = entry.category;
      _selectedPaymentMethod = entry.paymentMethod ?? 'Cash';
    } else if (widget.initialCashFlow != null) {
      _cashFlow = widget.initialCashFlow!;
    }

    // --- FIX: Initialize controllers ---
    _dateController =
        TextEditingController(text: DateFormat.yMd().format(_selectedDate));
    _timeController =
        TextEditingController(text: _selectedTime.format(context));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _remarksController.dispose();
    // --- FIX: Dispose new controllers ---
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  // --- NEW: Date/Time Picker function using the new package ---
  Future<void> _pickDateTime() async {
    final DateTime initialDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    Dtp.DatePicker.showDateTimePicker(
      context,
      showTitleActions: true,
      minTime: DateTime(2000),
      maxTime: DateTime(2101),
      onConfirm: (date) {
        // --- FIX: Update state AND controllers ---
        setState(() {
          _selectedDate = date;
          _selectedTime = TimeOfDay.fromDateTime(date);
          // This will update the UI live
          _dateController.text = DateFormat.yMd().format(_selectedDate);
          _timeController.text = _selectedTime.format(context);
        });
      },
      currentTime: initialDateTime,
      locale: Dtp.LocaleType.en,
    );
  }

  // --- Existing logic for resetting form is unchanged ---
  void _resetForm() {
    if (_isEditing) return;
    _formKey.currentState?.reset();
    _amountController.clear();
    _remarksController.clear();
    setState(() {
      _selectedCategory = null;
      _selectedPaymentMethod = 'Cash';
      // Reset controllers to now
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
      _dateController.text = DateFormat.yMd().format(_selectedDate);
      _timeController.text = _selectedTime.format(context);
    });
  }

  // --- Existing logic for saving/updating is 100% unchanged ---
  void _saveEntry({bool saveAndNew = false}) async {
    if (_formKey.currentState!.validate()) {
      final combinedDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      final newAmount = double.tryParse(_amountController.text) ?? 0.0;
      final newRemarks = _remarksController.text;
      final newCategory = _selectedCategory;
      final newPaymentMethod = _selectedPaymentMethod;
      final newCashFlow = _cashFlow.name;

      if (_isEditing) {
        // --- UPDATE LOGIC ---
        final entry = widget.entryToEdit!;
        List<String> changes = entry.changeLog ?? [];
        bool hasChanges = false;

        String formatDateTime(DateTime dt) =>
            DateFormat.yMd().add_jm().format(dt);

        if (entry.cashFlow != newCashFlow) {
          changes.add('Type: "${entry.cashFlow}" → "$newCashFlow"');
          hasChanges = true;
        }
        if (entry.dateTime != combinedDateTime) {
          changes.add(
              'Date: "${formatDateTime(entry.dateTime)}" → "${formatDateTime(combinedDateTime)}"');
          hasChanges = true;
        }
        if (entry.amount != newAmount) {
          changes.add('Amount: ${entry.amount} → $newAmount');
          hasChanges = true;
        }
        if (entry.remarks != newRemarks) {
          changes.add('Remarks: "${entry.remarks}" → "$newRemarks"');
          hasChanges = true;
        }
        if (entry.category != newCategory) {
          changes.add(
              'Category: "${entry.category ?? 'None'}" → "${newCategory ?? 'None'}"');
          hasChanges = true;
        }
        if (entry.paymentMethod != newPaymentMethod) {
          changes.add(
              'Payment Mode: "${entry.paymentMethod ?? 'None'}" → "$newPaymentMethod"');
          hasChanges = true;
        }

        entry.cashFlow = newCashFlow;
        entry.dateTime = combinedDateTime;
        entry.amount = newAmount;
        entry.remarks = newRemarks;
        entry.category = newCategory;
        entry.paymentMethod = newPaymentMethod;

        if (hasChanges) {
          changes.add("Edited on: ${formatDateTime(DateTime.now())}");
          entry.changeLog = changes;
        }

        await entry.save();
      } else {
        // --- CREATE LOGIC (Original) ---
        final entryBox = Hive.box<Entry>('entries');
        final newEntry = Entry(
          cashFlow: newCashFlow,
          dateTime: combinedDateTime,
          amount: newAmount,
          remarks: newRemarks,
          category: newCategory,
          paymentMethod: newPaymentMethod,
          changeLog: [],
        );
        await entryBox.add(newEntry);

        final cashbookBox = Hive.box<Cashbook>('cashbooks');
        Cashbook? cashbook = cashbookBox.values.firstWhere(
          (cb) => cb.name == widget.cashbookName,
        );
        cashbook.entries ??= HiveList(entryBox);
        cashbook.entries!.add(newEntry);
        cashbook.updatedAt = DateTime.now();
        await cashbook.save();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Entry ${_isEditing ? 'Updated' : 'Saved'}!')),
      );

      if (saveAndNew && !_isEditing) {
        _resetForm();
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  // --- Main build method for new UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLightGrey,
      appBar: _buildAppBar(context),
      floatingActionButton: _buildFab(context),
      bottomNavigationBar: _buildBottomBar(context),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            _buildCashFlowToggle(context),
            const SizedBox(height: 25),
            _buildDateTimeRow(context), // This widget is now updated
            const SizedBox(height: 20),
            _buildFormGroup(
              context,
              label: 'AMOUNT',
              child: _buildAmountField(context, _cashFlow),
            ),
            _buildFormGroup(
              context,
              label: 'REMARK / DESCRIPTION',
              child: _buildRemarksField(context),
            ),
            _buildFormGroup(
              context,
              label: 'CATEGORY',
              child: _buildCategoryField(context),
            ),
            _buildFormGroup(
              context,
              label: 'PAYMENT MODE',
              child: _buildPaymentModeChips(context),
            ),
            _buildQuickTip(context),
            const SizedBox(height: 80), // Padding for FAB
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60.0),
      child: AppBar(
        backgroundColor: _bgWhite,
        elevation: 1.0,
        shadowColor: Colors.black.withAlpha((0.05 * 255).round()),
        title: Text(
          _isEditing ? 'Edit Entry' : 'Add New Entry',
          style: const TextStyle(
            color: _textDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: _textDark),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('History (coming soon!)')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Preview running balance (coming soon!)')),
          );
        },
        backgroundColor: _primaryOrange,
        shape: const CircleBorder(),
        elevation: 8.0,
        child: const Icon(Icons.remove_red_eye, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return BottomAppBar(
      height: 65,
      color: _bgWhite,
      elevation: 0,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: _borderLight, width: 1)),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))
          ],
          color: _bgWhite,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          children: [
            if (!_isEditing)
              Expanded(
                child: _buildFooterButton(
                  context,
                  label: 'Save & Add New',
                  icon: Icons.add,
                  isPrimary: false,
                  onPressed: () => _saveEntry(saveAndNew: true),
                ),
              ),
            if (!_isEditing) const SizedBox(width: 8),
            Expanded(
              child: _buildFooterButton(
                context,
                label: _isEditing ? 'Update' : 'Save',
                icon: Icons.check,
                isPrimary: true,
                onPressed: () => _saveEntry(saveAndNew: false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    // --- FIX: Increased height to 70 ---
    return SizedBox(
      height: 70, // Increased from 44
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? _primaryOrange : _bgWhite,
          foregroundColor: isPrimary ? _bgWhite : _primaryOrange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          side: isPrimary ? null : const BorderSide(color: _primaryOrange, width: 2),
          elevation: isPrimary ? 4 : 0,
          shadowColor: isPrimary ? _primaryOrange.withAlpha((0.3 * 255).round()) : null,
        ),
      ),
    );
  }


  Widget _buildCashFlowToggle(BuildContext context) {
    bool isCashIn = _cashFlow == CashFlow.cashIn;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _bgWhite,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleChip(
              label: 'Cash In',
              isActive: isCashIn,
              activeColor: _buttonGreen,
              onTap: () => setState(() => _cashFlow = CashFlow.cashIn),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildToggleChip(
              label: 'Cash Out',
              isActive: !isCashIn,
              activeColor: _buttonRed,
              onTap: () => setState(() => _cashFlow = CashFlow.cashOut),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleChip({
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? activeColor : _inactiveOrangeBg,
          borderRadius: BorderRadius.circular(25),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: activeColor.withAlpha((0.3 * 255).round()),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : _primaryOrange,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormGroup(BuildContext context, {required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _primaryOrange,
            ),
          ),
          const SizedBox(height: 5),
          child,
        ],
      ),
    );
  }

  InputDecoration _formFieldDecoration({String? hintText, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: _bgWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _borderLight, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _borderLight, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _primaryOrange, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      suffixIcon: suffixIcon,
    );
  }

  // --- MODIFIED: Date/Time Row using controllers ---
  Widget _buildDateTimeRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildFormGroup(
            context,
            label: 'DATE',
            child: GestureDetector(
              onTap: _pickDateTime,
              child: AbsorbPointer( 
                child: TextFormField(
                  controller: _dateController, // <-- USE CONTROLLER
                  decoration: _formFieldDecoration(
                    suffixIcon: const Icon(Icons.calendar_today, size: 18, color: _primaryOrange),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildFormGroup(
            context,
            label: 'TIME',
            child: GestureDetector(
              onTap: _pickDateTime,
              child: AbsorbPointer(
                child: TextFormField(
                  controller: _timeController, // <-- USE CONTROLLER
                  decoration: _formFieldDecoration(
                    suffixIcon: const Icon(Icons.access_time, size: 18, color: _primaryOrange),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- MODIFIED: Amount Field with dynamic color ---
  Widget _buildAmountField(BuildContext context, CashFlow cashFlow) {
    final Color amountColor =
        cashFlow == CashFlow.cashIn ? _buttonGreen : _buttonRed;

    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      style: TextStyle(
        fontSize: 18, 
        fontWeight: FontWeight.w600, 
        color: amountColor // <-- DYNAMIC COLOR
      ),
      decoration: _formFieldDecoration(hintText: '0.00'),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter an amount';
        }
        if (double.tryParse(value) == null) {
          return 'Please enter a valid number';
        }
        return null;
      },
    );
  }

  Widget _buildRemarksField(BuildContext context) {
    return TextFormField(
      controller: _remarksController,
      maxLines: 3,
      textCapitalization: TextCapitalization.sentences,
      decoration: _formFieldDecoration(
        hintText: 'Enter transaction details...',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter remarks';
        }
        return null;
      },
    );
  }

  Widget _buildCategoryField(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory,
      items: _categories.map((category) {
        return DropdownMenuItem(value: category, child: Text(category));
      }).toList(),
      onChanged: (value) => setState(() => _selectedCategory = value),
      decoration: _formFieldDecoration(
        hintText: 'Select Category',
        suffixIcon: const Icon(Icons.keyboard_arrow_down, size: 20, color: _primaryOrange),
      ),
    );
  }

  Widget _buildPaymentModeChips(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.5,
      children: _paymentMethods.map((method) {
        final bool isSelected = _selectedPaymentMethod == method;
        return GestureDetector(
          onTap: () {
            setState(() => _selectedPaymentMethod = method);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? _activeOrangeDark : _inactiveOrangeBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                method,
                style: TextStyle(
                  color: isSelected ? _bgWhite : _primaryOrange,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickTip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 25.0),
      decoration: BoxDecoration(
        color: _inactiveOrangeBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderLight),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: _primaryOrange,
            child: Icon(Icons.info_outline, color: Colors.white, size: 14),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Add detailed remarks for better tracking',
              style: TextStyle(
                fontSize: 13,
                color: _textMedium,
              ),
            ),
          )
        ],
      ),
    );
  }
}