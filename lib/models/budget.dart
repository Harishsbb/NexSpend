class Budget {
  final String category;
  final double limit;
  final double currentSpending;

  Budget({
    required this.category,
    required this.limit,
    this.currentSpending = 0,
  });

  bool get isExceeded => currentSpending > limit;
  double get progress => currentSpending / limit;
  bool get isNearingLimit => progress >= 0.8;

  Budget copyWith({
    double? limit,
    double? currentSpending,
  }) {
    return Budget(
      category: category,
      limit: limit ?? this.limit,
      currentSpending: currentSpending ?? this.currentSpending,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'limit': limit,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map, String id) {
    return Budget(
      category: map['category']?.toString() ?? 'Other',
      limit: (map['limit'] ?? 0).toDouble(),
    );
  }
}
