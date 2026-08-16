class MonthlyCollectionPlayer {
  const MonthlyCollectionPlayer({
    required this.playerId,
    required this.playerCode,
    required this.firstName,
    required this.lastName,
    required this.categoryName,
    required this.amountDue,
    required this.amountPaid,
    required this.pendingAmount,
    required this.collectionStatus,
    required this.qrConfirmedAmount,
    required this.cashConfirmedAmount,
  });

  final String playerId;
  final String playerCode;
  final String firstName;
  final String lastName;
  final String? categoryName;

  final double amountDue;
  final double amountPaid;
  final double pendingAmount;

  final String collectionStatus;

  final double qrConfirmedAmount;
  final double cashConfirmedAmount;

  factory MonthlyCollectionPlayer.fromMap(Map<String, dynamic> map) {
    return MonthlyCollectionPlayer(
      playerId: _readString(map['player_id']),
      playerCode: _readString(map['player_code']),
      firstName: _readString(map['first_name']),
      lastName: _readString(map['last_name']),
      categoryName: _readNullableString(map['category_name']),
      amountDue: _readDouble(map['amount_due']),
      amountPaid: _readDouble(map['amount_paid']),
      pendingAmount: _readDouble(map['pending_amount']),
      collectionStatus: _readString(map['collection_status']),
      qrConfirmedAmount: _readDouble(map['qr_confirmed_amount']),
      cashConfirmedAmount: _readDouble(map['cash_confirmed_amount']),
    );
  }

  String get fullName {
    return '$firstName $lastName'.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String get displayCategory {
    final String value = categoryName?.trim() ?? '';

    return value.isEmpty ? 'Sin categoría' : value;
  }

  bool get isPaid {
    return collectionStatus.toLowerCase() == 'paid';
  }

  bool get isPending {
    return !isPaid;
  }

  bool get hasQrPayment {
    return qrConfirmedAmount > 0;
  }

  bool get hasCashPayment {
    return cashConfirmedAmount > 0;
  }

  bool get hasMixedPayment {
    return hasQrPayment && hasCashPayment;
  }

  String get paymentMethodLabel {
    if (hasMixedPayment) {
      return 'QR + Efectivo';
    }

    if (hasQrPayment) {
      return 'QR';
    }

    if (hasCashPayment) {
      return 'Efectivo';
    }

    if (amountPaid > 0) {
      return 'Otro';
    }

    return 'Sin pagos';
  }

  String get statusLabel {
    return isPaid ? 'AL DÍA' : 'PENDIENTE';
  }

  double get collectionPercentage {
    if (amountDue <= 0) {
      return 0;
    }

    final double percentage = (amountPaid / amountDue) * 100;

    if (percentage < 0) {
      return 0;
    }

    if (percentage > 100) {
      return 100;
    }

    return percentage;
  }

  static String _readString(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  static String? _readNullableString(dynamic value) {
    final String text = value?.toString().trim() ?? '';

    return text.isEmpty ? null : text;
  }

  static double _readDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }
}
