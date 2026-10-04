enum TransactionType {
  expense,
  income,
}

class Transaction {
  String id;
  String title;
  double amount;
  String category;
  DateTime date;
  TransactionType type;
  String? barcode;
  String? note;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.type = TransactionType.expense,
    this.barcode,
    this.note,
  });

  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'category': category,
    'date': date.toIso8601String(),
    'type': type.name,
    'barcode': barcode,
    'note': note,
  };

  factory Transaction.fromJson(Map<String, dynamic> json) {
    // Backward compatibility with legacy 'Expense' json structure
    TransactionType detectedType = TransactionType.expense;
    if (json.containsKey('type') && json['type'] != null) {
      detectedType = json['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense;
    }

    return Transaction(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] ?? 'Lainnya',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      type: detectedType,
      barcode: json['barcode'],
      note: json['note'],
    );
  }
}

