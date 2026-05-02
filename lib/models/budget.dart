class Budget {
  final String category;
  final double limit;
  final double currentAmount;
  final bool isIncome;

  Budget({
    required this.category,
    required this.limit,
    this.currentAmount = 0,
    this.isIncome = false,
  });

  bool get isExceeded => !isIncome && currentAmount > limit;
  bool get isAchieved => isIncome && currentAmount >= limit;
  double get progress => currentAmount / limit;
  bool get isNearingLimit => !isIncome && progress >= 0.8;

  Budget copyWith({
    double? limit,
    double? currentAmount,
    bool? isIncome,
  }) {
    return Budget(
      category: category,
      limit: limit ?? this.limit,
      currentAmount: currentAmount ?? this.currentAmount,
      isIncome: isIncome ?? this.isIncome,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'limit': limit,
      'isIncome': isIncome,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map, String id) {
    return Budget(
      category: map['category']?.toString() ?? 'Other',
      limit: (map['limit'] ?? 0).toDouble(),
      isIncome: map['isIncome'] ?? false,
    );
  }
}
