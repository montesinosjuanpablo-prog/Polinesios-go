class PaymentAccountStatus {
  const PaymentAccountStatus({
    required this.playerId,
    required this.playerName,
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.dayFrom,
    required this.dayTo,
    required this.validFrom,
    required this.chargeYear,
    required this.chargeMonth,
    required this.concept,
    required this.amountDue,
    required this.amountPaid,
    required this.remainingAmount,
    required this.dueDate,
    required this.chargeStatus,
    this.validUntil,
    this.paymentChargeId,
  });

  final String playerId;
  final String playerName;

  final String categoryId;
  final String categoryName;

  final double amount;

  final int dayFrom;
  final int dayTo;

  final DateTime validFrom;
  final DateTime? validUntil;

  final String? paymentChargeId;

  final int chargeYear;
  final int chargeMonth;

  final String concept;

  final double amountDue;
  final double amountPaid;
  final double remainingAmount;

  final DateTime dueDate;

  final String chargeStatus;

  bool get isPaid {
    return chargeStatus.trim().toLowerCase() == 'paid' || remainingAmount <= 0;
  }

  bool get isPartial {
    return chargeStatus.trim().toLowerCase() == 'partial';
  }

  bool get isPending {
    return chargeStatus.trim().toLowerCase() == 'pending';
  }

  String get paymentWindow {
    return '$dayFrom al $dayTo';
  }

  String get displayAmount {
    return _formatMoney(amount);
  }

  String get displayAmountDue {
    return _formatMoney(amountDue);
  }

  String get displayAmountPaid {
    return _formatMoney(amountPaid);
  }

  String get displayRemainingAmount {
    return _formatMoney(remainingAmount);
  }

  String get displayDueDate {
    final String day = dueDate.day.toString().padLeft(2, '0');
    final String month = dueDate.month.toString().padLeft(2, '0');

    return '$day/$month/${dueDate.year}';
  }

  String get displayPeriod {
    return '${_monthName(chargeMonth)} $chargeYear';
  }

  String get chargeStatusLabel {
    switch (chargeStatus.trim().toLowerCase()) {
      case 'paid':
        return 'Pagado';
      case 'partial':
        return 'Pago parcial';
      case 'overdue':
        return 'Vencido';
      case 'cancelled':
        return 'Cancelado';
      case 'pending':
      default:
        return 'Pendiente';
    }
  }

  int get remainingDays {
    final int today = DateTime.now().day;
    final int days = dayTo - today;

    return days < 0 ? 0 : days;
  }

  String get remainingText {
    if (isPaid) {
      return 'Mensualidad pagada';
    }

    if (remainingDays == 0) {
      return 'Último día de esta tarifa';
    }

    if (remainingDays == 1) {
      return 'Queda 1 día';
    }

    return 'Quedan $remainingDays días';
  }

  String get currentRange {
    return '$dayFrom al $dayTo';
  }

  String get title {
    return 'Estado de cuenta';
  }

  factory PaymentAccountStatus.fromMap(Map<String, dynamic> map) {
    return PaymentAccountStatus(
      playerId: _requiredString(map['player_id'], 'identificador del jugador'),
      playerName: _requiredString(map['player_name'], 'nombre del jugador'),
      categoryId: _requiredString(
        map['category_id'],
        'identificador de la categoría',
      ),
      categoryName: _requiredString(
        map['category_name'],
        'nombre de la categoría',
      ),
      amount: _toDouble(map['amount']),
      dayFrom: _toInt(map['day_from']),
      dayTo: _toInt(map['day_to']),
      validFrom: _requiredDate(map['valid_from'], 'inicio de vigencia'),
      validUntil: _nullableDate(map['valid_until']),
      paymentChargeId: _nullableString(map['payment_charge_id']),
      chargeYear: _toInt(map['charge_year']),
      chargeMonth: _toInt(map['charge_month']),
      concept: _requiredString(map['concept'], 'concepto del pago'),
      amountDue: _toDouble(map['amount_due']),
      amountPaid: _toDouble(map['amount_paid']),
      remainingAmount: _toDouble(map['remaining_amount']),
      dueDate: _requiredDate(map['due_date'], 'fecha de vencimiento'),
      chargeStatus: _requiredString(
        map['charge_status'],
        'estado de la mensualidad',
      ),
    );
  }
}

String _requiredString(dynamic value, String fieldName) {
  final String text = value?.toString().trim() ?? '';

  if (text.isEmpty) {
    throw FormatException('El campo "$fieldName" está vacío.');
  }

  return text;
}

String? _nullableString(dynamic value) {
  final String text = value?.toString().trim() ?? '';

  return text.isEmpty ? null : text;
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

DateTime _requiredDate(dynamic value, String fieldName) {
  final DateTime? date = DateTime.tryParse(value?.toString() ?? '');

  if (date == null) {
    throw FormatException('La fecha "$fieldName" no es válida.');
  }

  return date;
}

DateTime? _nullableDate(dynamic value) {
  final String text = value?.toString().trim() ?? '';

  if (text.isEmpty) {
    return null;
  }

  return DateTime.tryParse(text);
}

String _formatMoney(double value) {
  final bool isWholeNumber = value == value.roundToDouble();

  final String formatted = isWholeNumber
      ? value.toInt().toString()
      : value.toStringAsFixed(2);

  return '$formatted Bs';
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

  if (month < 1 || month > 12) {
    return 'Mes';
  }

  return months[month - 1];
}
