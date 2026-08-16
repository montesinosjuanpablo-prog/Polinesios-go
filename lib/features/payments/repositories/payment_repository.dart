import '../data/payment_service.dart';
import '../models/payment_account_status.dart';
import '../models/payment_history_item.dart';
import '../models/school_financial_summary.dart';
import '../models/monthly_collection_player.dart';

class PaymentRepository {
  const PaymentRepository();

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

  /// Obtiene el historial completo de pagos de un jugador.
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

  /// Obtiene el resumen financiero general de la escuela
  /// para un período determinado.
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

  /// Obtiene el detalle mensual de cobranza de la escuela.
  ///
  /// Devuelve un registro consolidado por jugador con:
  /// - monto esperado;
  /// - monto pagado;
  /// - saldo pendiente;
  /// - estado de cobranza;
  /// - pagos confirmados por QR;
  /// - pagos confirmados en efectivo.
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

  /// Obtiene todos los pagos realizados mediante QR
  /// para la revisión administrativa.
  Future<List<Map<String, dynamic>>> getQrPaymentsForAdmin() async {
    return PaymentService.getQrPaymentsForAdmin();
  }

  /// Confirma un pago QR pendiente.
  ///
  /// Supabase actualizará además el monto pagado
  /// y el estado de la mensualidad.
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

  /// Rechaza un pago QR pendiente.
  ///
  /// El rechazo no modifica el saldo de la mensualidad.
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
