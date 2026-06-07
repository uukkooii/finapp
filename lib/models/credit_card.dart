class CreditCard {
  final int? id;
  final String name;
  final String bank;
  final String cardNumber; // last 4 digits
  final double creditLimit;
  final double currentBalance;
  final int billDay; // 1-28
  final int paymentDay; // 1-28
  final String color; // hex without # e.g. 'D4A574'
  final String createdAt; // 'YYYY-MM-DD'

  const CreditCard({
    this.id,
    required this.name,
    required this.bank,
    required this.cardNumber,
    required this.creditLimit,
    required this.currentBalance,
    required this.billDay,
    required this.paymentDay,
    required this.color,
    required this.createdAt,
  });

  double get availableCredit => creditLimit - currentBalance;
  double get utilizationRate =>
      creditLimit > 0 ? (currentBalance / creditLimit).clamp(0.0, 1.0) : 0.0;

  factory CreditCard.fromMap(Map<String, dynamic> map) {
    return CreditCard(
      id: map['id'] as int?,
      name: map['name'] as String,
      bank: map['bank'] as String,
      cardNumber: map['card_number'] as String,
      creditLimit: (map['credit_limit'] as num).toDouble(),
      currentBalance: (map['current_balance'] as num).toDouble(),
      billDay: map['bill_day'] as int,
      paymentDay: map['payment_day'] as int,
      color: map['color'] as String,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    final m = <String, dynamic>{
      'name': name,
      'bank': bank,
      'card_number': cardNumber,
      'credit_limit': creditLimit,
      'current_balance': currentBalance,
      'bill_day': billDay,
      'payment_day': paymentDay,
      'color': color,
      'created_at': createdAt,
    };
    if (id != null) m['id'] = id;
    return m;
  }

  CreditCard copyWith({
    int? id,
    String? name,
    String? bank,
    String? cardNumber,
    double? creditLimit,
    double? currentBalance,
    int? billDay,
    int? paymentDay,
    String? color,
    String? createdAt,
  }) {
    return CreditCard(
      id: id ?? this.id,
      name: name ?? this.name,
      bank: bank ?? this.bank,
      cardNumber: cardNumber ?? this.cardNumber,
      creditLimit: creditLimit ?? this.creditLimit,
      currentBalance: currentBalance ?? this.currentBalance,
      billDay: billDay ?? this.billDay,
      paymentDay: paymentDay ?? this.paymentDay,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Days until next payment, relative to [now]
  int daysUntilPayment(DateTime now) {
    var due = DateTime(now.year, now.month, paymentDay);
    if (due.isBefore(now)) {
      due = DateTime(now.year, now.month + 1, paymentDay);
    }
    return due.difference(DateTime(now.year, now.month, now.day)).inDays;
  }
}
