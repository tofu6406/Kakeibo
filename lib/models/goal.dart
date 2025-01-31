class Goal {
  final String id;
  final double targetAmount;
  final double savedAmount;
  final DateTime deadline;

  Goal({
    required this.id,
    required this.targetAmount,
    required this.savedAmount,
    required this.deadline,
  });

  // Firebase用のデータ変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'targetAmount': targetAmount,
      'savedAmount': savedAmount,
      'deadline': deadline.toIso8601String(),
    };
  }

  static Goal fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'],
      targetAmount: map['targetAmount'],
      savedAmount: map['savedAmount'],
      deadline: DateTime.parse(map['deadline']),
    );
  }
}
