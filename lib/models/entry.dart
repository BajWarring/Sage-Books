import 'package:hive/hive.dart';

part 'entry.g.dart';

@HiveType(typeId: 1) // <-- FIX: Was '2', mismatching entry.g.dart
class Entry extends HiveObject {
  @HiveField(0)
  String cashFlow;
  @HiveField(1)
  DateTime dateTime;

  @HiveField(2)
  double amount;

  @HiveField(3)
  String remarks;

  @HiveField(4)
  String? category;

  @HiveField(5)
  String? paymentMethod;

  // --- NEW: Added field for edit history ---
  @HiveField(6)
  List<String>? changeLog;

  Entry({
    required this.cashFlow,
    required this.dateTime,
    required this.amount,
    required this.remarks,
    this.category,
    this.paymentMethod,
    this.changeLog, // Add to constructor
  });
}

