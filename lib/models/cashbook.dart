import 'package:hive/hive.dart';
import 'package:sage/models/entry.dart';

part 'cashbook.g.dart';

@HiveType(typeId: 0)
class Cashbook extends HiveObject {
  @HiveField(0)
  late String name;

  @HiveField(1)
  HiveList<Entry>? entries;

  @HiveField(2) // New field
  late DateTime createdAt;

  @HiveField(3) // New field
  late DateTime updatedAt;

  Cashbook({
    required this.name,
    this.entries,
    required this.createdAt,
    required this.updatedAt,
  });

  // --- New Getter Functions ---

  // Calculate Total In
  double get totalIn {
    if (entries == null) return 0.0;
    return entries!
        .where((e) => e.cashFlow == 'cashIn')
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  // Calculate Total Out
  double get totalOut {
    if (entries == null) return 0.0;
    return entries!
        .where((e) => e.cashFlow == 'cashOut')
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  // Calculate Net Balance
  double get netBalance {
    return totalIn - totalOut;
  }
}

