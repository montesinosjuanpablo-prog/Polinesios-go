class SchoolFinancialSummary {
  const SchoolFinancialSummary({
    required this.periodYear,
    required this.periodMonth,
    required this.expectedAmount,
    required this.confirmedAmount,
    required this.pendingAmount,
    required this.qrConfirmedAmount,
    required this.cashConfirmedAmount,
    required this.playersPaid,
    required this.playersPending,
    required this.totalPlayers,
    required this.collectionPercentage,
  });

  final int periodYear;
  final int periodMonth;

  final double expectedAmount;
  final double confirmedAmount;
  final double pendingAmount;

  final double qrConfirmedAmount;
  final double cashConfirmedAmount;

  final int playersPaid;
  final int playersPending;
  final int totalPlayers;

  final double collectionPercentage;

  factory SchoolFinancialSummary.fromMap(Map<String, dynamic> map) {
    return SchoolFinancialSummary(
      periodYear: _toInt(map['period_year']),
      periodMonth: _toInt(map['period_month']),
      expectedAmount: _toDouble(map['expected_amount']),
      confirmedAmount: _toDouble(map['confirmed_amount']),
      pendingAmount: _toDouble(map['pending_amount']),
      qrConfirmedAmount: _toDouble(map['qr_confirmed_amount']),
      cashConfirmedAmount: _toDouble(map['cash_confirmed_amount']),
      playersPaid: _toInt(map['players_paid']),
      playersPending: _toInt(map['players_pending']),
      totalPlayers: _toInt(map['total_players']),
      collectionPercentage: _toDouble(map['collection_percentage']),
    );
  }

  String get periodLabel {
    return '${_monthName(periodMonth)} $periodYear';
  }

  String get expectedAmountLabel {
    return _formatAmount(expectedAmount);
  }

  String get confirmedAmountLabel {
    return _formatAmount(confirmedAmount);
  }

  String get pendingAmountLabel {
    return _formatAmount(pendingAmount);
  }

  String get qrConfirmedAmountLabel {
    return _formatAmount(qrConfirmedAmount);
  }

  String get cashConfirmedAmountLabel {
    return _formatAmount(cashConfirmedAmount);
  }

  String get collectionPercentageLabel {
    final bool isWholeNumber =
        collectionPercentage == collectionPercentage.roundToDouble();

    final String value = isWholeNumber
        ? collectionPercentage.toInt().toString()
        : collectionPercentage.toStringAsFixed(2);

    return '$value%';
  }

  bool get isFullyCollected {
    return expectedAmount > 0 &&
        pendingAmount <= 0 &&
        collectionPercentage >= 100;
  }

  bool get hasPendingAmount {
    return pendingAmount > 0;
  }

  bool get hasPlayers {
    return totalPlayers > 0;
  }

  double get qrSharePercentage {
    if (confirmedAmount <= 0) {
      return 0;
    }

    return (qrConfirmedAmount / confirmedAmount) * 100;
  }

  double get cashSharePercentage {
    if (confirmedAmount <= 0) {
      return 0;
    }

    return (cashConfirmedAmount / confirmedAmount) * 100;
  }

  String get playersPaidLabel {
    if (playersPaid == 1) {
      return '1 jugador';
    }

    return '$playersPaid jugadores';
  }

  String get playersPendingLabel {
    if (playersPending == 1) {
      return '1 jugador';
    }

    return '$playersPending jugadores';
  }

  String get totalPlayersLabel {
    if (totalPlayers == 1) {
      return '1 jugador';
    }

    return '$totalPlayers jugadores';
  }
}

double _toDouble(dynamic value) {
  if (value == null) {
    return 0;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString()) ?? 0;
}

int _toInt(dynamic value) {
  if (value == null) {
    return 0;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString()) ?? 0;
}

String _formatAmount(double amount) {
  final bool isWholeNumber = amount == amount.roundToDouble();

  final String value = isWholeNumber
      ? amount.toInt().toString()
      : amount.toStringAsFixed(2);

  return '$value Bs';
}

String _monthName(int month) {
  const List<String> months = <String>[
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  if (month < 1 || month > months.length) {
    return 'Mes';
  }

  return months[month - 1];
}
