class RecurringBill {
  final int? id;
  final String name;
  final double amount;
  final String category;
  final String frequency; // monthly/quarterly/yearly/custom
  final int? customDays;
  final String? nextDueDate; // 'YYYY-MM-DD'
  final String? account;
  final String? note;
  final String createdAt; // 'YYYY-MM-DD'
  final bool isActive;

  const RecurringBill({
    this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.frequency,
    this.customDays,
    this.nextDueDate,
    this.account,
    this.note,
    required this.createdAt,
    this.isActive = true,
  });

  factory RecurringBill.fromMap(Map<String, dynamic> map) {
    return RecurringBill(
      id: map['id'] as int?,
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      frequency: map['frequency'] as String,
      customDays: map['custom_days'] as int?,
      nextDueDate: map['next_due_date'] as String?,
      account: map['account'] as String?,
      note: map['note'] as String?,
      createdAt: map['created_at'] as String,
      isActive: (map['is_active'] as int? ?? 1) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    final m = <String, dynamic>{
      'name': name,
      'amount': amount,
      'category': category,
      'frequency': frequency,
      'custom_days': customDays,
      'next_due_date': nextDueDate,
      'account': account,
      'note': note,
      'created_at': createdAt,
      'is_active': isActive ? 1 : 0,
    };
    if (id != null) m['id'] = id;
    return m;
  }

  RecurringBill copyWith({
    int? id,
    String? name,
    double? amount,
    String? category,
    String? frequency,
    int? customDays,
    String? nextDueDate,
    String? account,
    String? note,
    String? createdAt,
    bool? isActive,
  }) {
    return RecurringBill(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      customDays: customDays ?? this.customDays,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      account: account ?? this.account,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  String get frequencyLabel {
    switch (frequency) {
      case 'monthly':
        return '月';
      case 'quarterly':
        return '季';
      case 'yearly':
        return '年';
      case 'custom':
        return '${customDays ?? '?'}天';
      default:
        return frequency;
    }
  }

  String? computeNextDueDate() {
    if (nextDueDate == null) return null;
    final current = DateTime.parse(nextDueDate!);
    switch (frequency) {
      case 'monthly':
        return _addMonths(current, 1);
      case 'quarterly':
        return _addMonths(current, 3);
      case 'yearly':
        return _addMonths(current, 12);
      case 'custom':
        if (customDays == null) return null;
        final next = current.add(Duration(days: customDays!));
        return '${next.year}-${next.month.toString().padLeft(2, '0')}-${next.day.toString().padLeft(2, '0')}';
      default:
        return null;
    }
  }

  static String _addMonths(DateTime date, int months) {
    final next = DateTime(date.year, date.month + months, date.day);
    return '${next.year}-${next.month.toString().padLeft(2, '0')}-${next.day.toString().padLeft(2, '0')}';
  }
}
