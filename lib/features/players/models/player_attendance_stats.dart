class PlayerAttendanceStats {
  const PlayerAttendanceStats({
    required this.totalSessions,
    required this.presentCount,
    required this.lateCount,
    required this.absentCount,
    required this.injuredCount,
    required this.attendancePercentage,
    this.lastAttendance,
  });

  final int totalSessions;
  final int presentCount;
  final int lateCount;
  final int absentCount;
  final int injuredCount;

  final double attendancePercentage;

  final DateTime? lastAttendance;

  bool get hasAttendance {
    return totalSessions > 0;
  }

  int get attendedCount {
    return presentCount + lateCount;
  }

  int get missedCount {
    return absentCount + injuredCount;
  }

  String get displayPercentage {
    final double percentage = attendancePercentage.clamp(0, 100);

    if (percentage == percentage.roundToDouble()) {
      return '${percentage.toInt()}%';
    }

    return '${percentage.toStringAsFixed(1)}%';
  }

  String get displayLastAttendance {
    final DateTime? date = lastAttendance;

    if (date == null) {
      return 'Sin registros';
    }

    final String day = date.day.toString().padLeft(2, '0');

    final String month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  factory PlayerAttendanceStats.empty() {
    return const PlayerAttendanceStats(
      totalSessions: 0,
      presentCount: 0,
      lateCount: 0,
      absentCount: 0,
      injuredCount: 0,
      attendancePercentage: 0,
    );
  }

  factory PlayerAttendanceStats.fromMap(Map<String, dynamic> map) {
    return PlayerAttendanceStats(
      totalSessions: _toInt(map['total_sessions']),
      presentCount: _toInt(map['present_count']),
      lateCount: _toInt(map['late_count']),
      absentCount: _toInt(map['absent_count']),
      injuredCount: _toInt(map['injured_count']),
      attendancePercentage: _toDouble(map['attendance_percentage']),
      lastAttendance: _toNullableDate(map['last_attendance']),
    );
  }
}

int _toInt(dynamic value) {
  if (value == null) {
    return 0;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString()) ?? 0;
}

double _toDouble(dynamic value) {
  if (value == null) {
    return 0;
  }

  if (value is double) {
    return value;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString()) ?? 0;
}

DateTime? _toNullableDate(dynamic value) {
  final String text = value?.toString().trim() ?? '';

  if (text.isEmpty) {
    return null;
  }

  return DateTime.tryParse(text);
}
