class Budget {
  final int? id;
  final String category; // 'total' for overall budget
  final double amount;
  final String month; // 'YYYY-MM'

  const Budget({
    this.id,
    required this.category,
    required this.amount,
    required this.month,
  });

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as int?,
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      month: map['month'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    final m = <String, dynamic>{
      'category': category,
      'amount': amount,
      'month': month,
    };
    if (id != null) m['id'] = id;
    return m;
  }
}
