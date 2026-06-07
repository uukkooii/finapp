class Goal {
  final int? id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final String? deadline; // 'YYYY-MM-DD'
  final String createdAt; // 'YYYY-MM-DD'
  final String? account;
  final String? icon;
  final String? color;

  const Goal({
    this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    this.deadline,
    required this.createdAt,
    this.account,
    this.icon,
    this.color,
  });

  double get progress =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'] as int?,
      name: map['name'] as String,
      targetAmount: (map['target_amount'] as num).toDouble(),
      currentAmount: (map['current_amount'] as num).toDouble(),
      deadline: map['deadline'] as String?,
      createdAt: map['created_at'] as String,
      account: map['account'] as String?,
      icon: map['icon'] as String?,
      color: map['color'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final m = <String, dynamic>{
      'name': name,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'deadline': deadline,
      'created_at': createdAt,
      'account': account,
      'icon': icon,
      'color': color,
    };
    if (id != null) m['id'] = id;
    return m;
  }

  Goal copyWith({
    int? id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    String? deadline,
    String? createdAt,
    String? account,
    String? icon,
    String? color,
  }) {
    return Goal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
      account: account ?? this.account,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }
}
