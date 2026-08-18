import '../data/payment_service.dart';
import '../models/payment_account_status.dart';
import '../models/payment_history_item.dart';
import '../models/school_financial_summary.dart';
import '../models/monthly_collection_player.dart';

class PaymentRepository {
  const PaymentRepository();

  // ============================================================
  // NUEVO SISTEMA SIMPLE DE PAGOS
  // ============================================================

  /// Registra manualmente un pago confirmado.
  ///
  /// El administrador define:
  /// - jugador;
  /// - monto;
  /// - fecha;
  /// - método: QR o efectivo;
  /// - observación opcional.
  Future<Map<String, dynamic>> registerManualPayment({
    required String playerId,
    required double amount,
    required DateTime paymentDate,
    required String paymentMethod,
    String? notes,
  }) async {
    final String normalizedPlayerId = playerId.trim();

    if (normalizedPlayerId.isEmpty) {
      throw const FormatException(
        'El identificador del jugador es obligatorio.',
      );
    }

    if (amount <= 0) {
      throw const FormatException('El monto del pago debe ser mayor a cero.');
    }

    final String normalizedMethod = paymentMethod.trim().toLowerCase();

    if (normalizedMethod != 'qr' && normalizedMethod != 'cash') {
      throw const FormatException('El método de pago debe ser QR o efectivo.');
    }

    return PaymentService.registerManualPayment(
      playerId: normalizedPlayerId,
      amount: amount,
      paymentDate: paymentDate,
      paymentMethod: normalizedMethod,
      notes: notes,
    );
  }

  /// Corrige un pago manual ya registrado.
  ///
  /// Se mantiene el mismo identificador del movimiento.
  Future<Map<String, dynamic>> updateManualPayment({
    required String paymentRecordId,
    required double amount,
    required DateTime paymentDate,
    required String paymentMethod,
    String? notes,
  }) async {
    final String normalizedPaymentId = paymentRecordId.trim();

    if (normalizedPaymentId.isEmpty) {
      throw const FormatException('El identificador del pago es obligatorio.');
    }

    if (amount <= 0) {
      throw const FormatException('El monto del pago debe ser mayor a cero.');
    }

    final String normalizedMethod = paymentMethod.trim().toLowerCase();

    if (normalizedMethod != 'qr' && normalizedMethod != 'cash') {
      throw const FormatException('El método de pago debe ser QR o efectivo.');
    }

    return PaymentService.updateManualPayment(
      paymentRecordId: normalizedPaymentId,
      amount: amount,
      paymentDate: paymentDate,
      paymentMethod: normalizedMethod,
      notes: notes,
    );
  }

  /// Obtiene únicamente los pagos confirmados de un jugador.
  Future<List<Map<String, dynamic>>> getPlayerManualPaymentHistory(
    String playerId,
  ) async {
    final String normalizedPlayerId = playerId.trim();

    if (normalizedPlayerId.isEmpty) {
      throw const FormatException(
        'El identificador del jugador es obligatorio.',
      );
    }

    return PaymentService.getPlayerManualPaymentHistory(
      playerId: normalizedPlayerId,
    );
  }

  /// Obtiene todos los pagos confirmados de la escuela.
  Future<List<Map<String, dynamic>>> getSchoolManualPayments() async {
    return PaymentService.getSchoolManualPayments();
  }

  /// Obtiene el resumen financiero real del período.
  ///
  /// No calcula deuda, monto esperado ni mora.
  /// Solo utiliza pagos confirmados.
  Future<Map<String, dynamic>> getSchoolManualFinancialSummary({
    required int year,
    required int month,
  }) async {
    if (year < 2000 || year > 2100) {
      throw const FormatException('El año indicado no es válido.');
    }

    if (month < 1 || month > 12) {
      throw const FormatException('El mes debe estar entre 1 y 12.');
    }

    return PaymentService.getSchoolManualFinancialSummary(
      year: year,
      month: month,
    );
  }

  // ============================================================
  // SISTEMA ANTERIOR
  //
  // Se mantiene TEMPORALMENTE para que las pantallas antiguas
  // continúen compilando mientras realizamos la migración.
  // ============================================================

  Future<PaymentAccountStatus> getCurrentFee(String playerId) async {
    final String normalizedPlayerId = playerId.trim();

    if (normalizedPlayerId.isEmpty) {
      throw const FormatException(
        'El identificador del jugador es obligatorio.',
      );
    }

    final Map<String, dynamic> response =
        await PaymentService.getPlayerCurrentFee(playerId: normalizedPlayerId);

    return PaymentAccountStatus.fromMap(response);
  }

  /// Historial completo del sistema anterior.
  Future<List<PaymentHistoryItem>> getPlayerPaymentHistory(
    String playerId,
  ) async {
    final String normalizedPlayerId = playerId.trim();

    if (normalizedPlayerId.isEmpty) {
      throw const FormatException(
        'El identificador del jugador es obligatorio.',
      );
    }

    final List<Map<String, dynamic>> response =
        await PaymentService.getPlayerPaymentHistory(
          playerId: normalizedPlayerId,
        );

    return response
        .map((Map<String, dynamic> item) => PaymentHistoryItem.fromMap(item))
        .toList();
  }

  /// Resumen financiero del sistema anterior.
  Future<SchoolFinancialSummary> getSchoolFinancialSummary({
    required int year,
    required int month,
  }) async {
    if (year < 2000 || year > 2100) {
      throw const FormatException('El año indicado no es válido.');
    }

    if (month < 1 || month > 12) {
      throw const FormatException('El mes debe estar entre 1 y 12.');
    }

    final Map<String, dynamic> response =
        await PaymentService.getSchoolFinancialSummary(
          year: year,
          month: month,
        );

    return SchoolFinancialSummary.fromMap(response);
  }

  /// Detalle mensual del sistema anterior.
  Future<List<MonthlyCollectionPlayer>> getSchoolMonthlyCollectionDetail({
    required int year,
    required int month,
  }) async {
    if (year < 2000 || year > 2100) {
      throw const FormatException('El año indicado no es válido.');
    }

    if (month < 1 || month > 12) {
      throw const FormatException('El mes debe estar entre 1 y 12.');
    }

    final List<Map<String, dynamic>> response =
        await PaymentService.getSchoolMonthlyCollectionDetail(
          year: year,
          month: month,
        );

    return response
        .map(
          (Map<String, dynamic> item) => MonthlyCollectionPlayer.fromMap(item),
        )
        .toList();
  }

  /// Pago en efectivo del sistema anterior.
  Future<Map<String, dynamic>> registerCashPayment({
    required String playerId,
    required double amount,
    DateTime? paymentDate,
    String? notes,
  }) async {
    final String normalizedPlayerId = playerId.trim();

    if (normalizedPlayerId.isEmpty) {
      throw const FormatException(
        'El identificador del jugador es obligatorio.',
      );
    }

    if (amount <= 0) {
      throw const FormatException('El monto del pago debe ser mayor a cero.');
    }

    return PaymentService.registerCashPayment(
      playerId: normalizedPlayerId,
      amount: amount,
      paymentDate: paymentDate,
      notes: notes,
    );
  }

  /// Reporte QR del sistema anterior.
  Future<Map<String, dynamic>> reportQrPayment({
    required String playerId,
    required double amount,
    required String receiptUrl,
    DateTime? paymentDate,
    String? transactionReference,
    String? notes,
  }) async {
    final String normalizedPlayerId = playerId.trim();
    final String normalizedReceiptUrl = receiptUrl.trim();

    if (normalizedPlayerId.isEmpty) {
      throw const FormatException(
        'El identificador del jugador es obligatorio.',
      );
    }

    if (amount <= 0) {
      throw const FormatException('El monto del pago debe ser mayor a cero.');
    }

    if (normalizedReceiptUrl.isEmpty) {
      throw const FormatException('Debes adjuntar un comprobante de pago.');
    }

    return PaymentService.reportQrPayment(
      playerId: normalizedPlayerId,
      amount: amount,
      receiptUrl: normalizedReceiptUrl,
      paymentDate: paymentDate,
      transactionReference: transactionReference,
      notes: notes,
    );
  }

  /// Bandeja QR administrativa del sistema anterior.
  Future<List<Map<String, dynamic>>> getQrPaymentsForAdmin() async {
    return PaymentService.getQrPaymentsForAdmin();
  }

  /// Confirmación QR del sistema anterior.
  Future<Map<String, dynamic>> confirmQrPayment({
    required String paymentRecordId,
    String? notes,
  }) async {
    final String normalizedId = paymentRecordId.trim();

    if (normalizedId.isEmpty) {
      throw const FormatException('El identificador del pago es obligatorio.');
    }

    return PaymentService.confirmQrPayment(
      paymentRecordId: normalizedId,
      notes: notes,
    );
  }

  /// Rechazo QR del sistema anterior.
  Future<Map<String, dynamic>> rejectQrPayment({
    required String paymentRecordId,
    String? notes,
  }) async {
    final String normalizedId = paymentRecordId.trim();

    if (normalizedId.isEmpty) {
      throw const FormatException('El identificador del pago es obligatorio.');
    }

    return PaymentService.rejectQrPayment(
      paymentRecordId: normalizedId,
      notes: notes,
    );
  }
}
