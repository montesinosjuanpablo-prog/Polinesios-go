class PaymentHistoryItem {
  const PaymentHistoryItem({
    required this.paymentRecordId,
    required this.paymentChargeId,
    required this.playerId,
    required this.chargeYear,
    required this.chargeMonth,
    required this.concept,
    required this.amountDue,
    required this.paymentAmount,
    required this.paymentDate,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdAt,
    this.transactionReference,
    this.receiptUrl,
    this.notes,
    this.verifiedAt,
  });

  final String paymentRecordId;
  final String paymentChargeId;
  final String playerId;

  final int chargeYear;
  final int chargeMonth;

  final String concept;

  final double amountDue;
  final double paymentAmount;

  final DateTime paymentDate;

  final String paymentMethod;
  final String paymentStatus;

  final String? transactionReference;
  final String? receiptUrl;
  final String? notes;

  final DateTime? verifiedAt;
  final DateTime createdAt;

  factory PaymentHistoryItem.fromMap(Map<String, dynamic> map) {
    return PaymentHistoryItem(
      paymentRecordId: _requiredString(
        map['payment_record_id'],
        'identificador del pago',
      ),
      paymentChargeId: _requiredString(
        map['payment_charge_id'],
        'identificador del cargo',
      ),
      playerId: _requiredString(map['player_id'], 'identificador del jugador'),
      chargeYear: _toInt(map['charge_year']),
      chargeMonth: _toInt(map['charge_month']),
      concept: _requiredString(map['concept'], 'concepto'),
      amountDue: _toDouble(map['amount_due']),
      paymentAmount: _toDouble(map['payment_amount']),
      paymentDate: _requiredDate(map['payment_date'], 'fecha de pago'),
      paymentMethod: _requiredString(map['payment_method'], 'método de pago'),
      paymentStatus: _requiredString(map['payment_status'], 'estado del pago'),
      transactionReference: _nullableString(map['transaction_reference']),
      receiptUrl: _nullableString(map['receipt_url']),
      notes: _nullableString(map['notes']),
      verifiedAt: _nullableDate(map['verified_at']),
      createdAt: _requiredDate(map['created_at'], 'fecha de creación'),
    );
  }

  String get periodLabel {
    return '${_monthName(chargeMonth)} $chargeYear';
  }

  String get amountLabel {
    final bool isWholeNumber = paymentAmount == paymentAmount.roundToDouble();

    final String value = isWholeNumber
        ? paymentAmount.toInt().toString()
        : paymentAmount.toStringAsFixed(2);

    return '$value Bs';
  }

  String get methodLabel {
    switch (paymentMethod) {
      case 'cash':
        return 'Efectivo';

      case 'qr':
        return 'QR';

      case 'bank_transfer':
        return 'Transferencia bancaria';

      case 'other':
        return 'Otro';

      default:
        return paymentMethod;
    }
  }

  String get statusLabel {
    switch (paymentStatus) {
      case 'confirmed':
        return 'Confirmado';

      case 'rejected':
        return 'Rechazado';

      case 'pending_verification':
        return 'Pendiente';

      case 'cancelled':
        return 'Cancelado';

      default:
        return paymentStatus;
    }
  }

  bool get isConfirmed => paymentStatus == 'confirmed';

  bool get isRejected => paymentStatus == 'rejected';

  bool get isPending => paymentStatus == 'pending_verification';

  bool get hasReceipt {
    final String value = receiptUrl?.trim() ?? '';

    return value.isNotEmpty;
  }

  bool get hasNotes {
    final String value = notes?.trim() ?? '';

    return value.isNotEmpty;
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
