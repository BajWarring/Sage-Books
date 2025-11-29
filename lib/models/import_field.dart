// You can put this in its own file or at the top of import_mapping_page.dart

enum AppField {
  ignore,
  date,
  time,
  remarks,
  category,
  paymentMethod,
  amountIn,
  amountOut,
  amountSingleColumn, // For CSVs with positive/negative numbers in one column
}

extension AppFieldExtension on AppField {
  String get displayName {
    switch (this) {
      case AppField.ignore:
        return '(Ignore This Column)';
      case AppField.date:
        return 'Date';
      case AppField.time:
        return 'Time';
      case AppField.remarks:
        return 'Remarks';
      case AppField.category:
        return 'Category';
      case AppField.paymentMethod:
        return 'Payment Method';
      case AppField.amountIn:
        return 'Amount In (Credit)';
      case AppField.amountOut:
        return 'Amount Out (Debit)';
      case AppField.amountSingleColumn:
        return 'Amount (Single Column)';
    }
  }
}
