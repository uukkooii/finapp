class Transaction {
  final int? id;
  final String type; // 'income' or 'expense'
  final double amount;
  final String category;
  final String account;
  final String? note;
  final String date; // 'YYYY-MM-DD'

  const Transaction({
    this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.account,
    this.note,
    required this.date,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      account: map['account'] as String,
      note: map['note'] as String?,
      date: map['date'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    final m = <String, dynamic>{
      'type': type,
      'amount': amount,
      'category': category,
      'account': account,
      'note': note,
      'date': date,
    };
    if (id != null) m['id'] = id;
    return m;
  }

  Transaction copyWith({
    int? id,
    String? type,
    double? amount,
    String? category,
    String? account,
    String? note,
    String? date,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      account: account ?? this.account,
      note: note ?? this.note,
      date: date ?? this.date,
    );
  }
}
