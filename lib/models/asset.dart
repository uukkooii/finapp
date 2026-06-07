class Asset {
  final int? id;
  final String name;
  final String type; // 现金, 银行存款, 理财, 股票, 基金, 房产, 车辆, 其他
  final double amount; // current value
  final double? costBasis; // original cost (for profit tracking)
  final String? note;
  final String createdAt;
  final String? updatedAt;
  final String icon;

  const Asset({
    this.id,
    required this.name,
    required this.type,
    required this.amount,
    this.costBasis,
    this.note,
    required this.createdAt,
    this.updatedAt,
    this.icon = '💰',
  });

  double get profit => costBasis != null ? amount - costBasis! : 0;
  double get profitRate => costBasis != null && costBasis! > 0 ? profit / costBasis! : 0;

  factory Asset.fromMap(Map<String, dynamic> map) {
    return Asset(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      costBasis: map['cost_basis'] != null ? (map['cost_basis'] as num).toDouble() : null,
      note: map['note'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String?,
      icon: map['icon'] as String? ?? _typeIcon(map['type'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    final m = <String, dynamic>{
      'name': name,
      'type': type,
      'amount': amount,
      'cost_basis': costBasis,
      'note': note,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'icon': icon,
    };
    if (id != null) m['id'] = id;
    return m;
  }

  Asset copyWith({
    int? id,
    String? name,
    String? type,
    double? amount,
    double? costBasis,
    String? note,
    String? createdAt,
    String? updatedAt,
    String? icon,
  }) {
    return Asset(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      costBasis: costBasis ?? this.costBasis,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      icon: icon ?? this.icon,
    );
  }

  static String _typeIcon(String type) {
    switch (type) {
      case '现金': return '💵';
      case '银行存款': return '🏦';
      case '理财': return '📊';
      case '股票': return '📈';
      case '基金': return '💼';
      case '房产': return '🏠';
      case '车辆': return '🚗';
      case '黄金': return '🥇';
      case '数字货币': return '₿';
      default: return '💰';
    }
  }

  static const List<String> typeOptions = [
    '现金', '银行存款', '理财', '股票', '基金', '房产', '车辆', '黄金', '数字货币', '其他',
  ];

  static String typeIcon(String type) => _typeIcon(type);
}
