class Transaction {
  final String id;
  final String category;
  final double amount;
  final DateTime date;
  final String type; // "income" or "expense"

  Transaction({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
    required this.type,
  });

  // Firebase用のデータ変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type,
    };
  }

  static Transaction fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      category: map['category'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      type: map['type'],
    );
  }

  // copyWithメソッドの追加
  Transaction copyWith({
    String? id,
    String? category,
    double? amount,
    DateTime? date,
    String? type,
  }) {
    return Transaction(
      id: id ?? this.id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
    );
  }
}
