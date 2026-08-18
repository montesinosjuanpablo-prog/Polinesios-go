import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentService {
  PaymentService._();

  static SupabaseClient get _client => Supabase.instance.client;

  // ============================================================
  // NUEVO SISTEMA SIMPLE DE PAGOS
  // ============================================================

  /// Registra manualmente un pago confirmado por administración.
  ///
  /// El monto, fecha y método son definidos directamente
  /// por el administrador.
  static Future<Map<String, dynamic>> registerManualPayment({
    required String playerId,
    required double amount,
    required DateTime paymentDate,
    required String paymentMethod,
    String? notes,
  }) async {
    final String normalizedPlayerId = playerId.trim();
    final String normalizedMethod = paymentMethod.trim().toLowerCase();

    if (normalizedPlayerId.isEmpty) {
      throw const FormatException(
        'El identificador del jugador es obligatorio.',
      );
    }

    if (amount <= 0) {
      throw const FormatException('El monto del pago debe ser mayor a cero.');
    }

    if (normalizedMethod != 'qr' && normalizedMethod != 'cash') {
      throw const FormatException('El método de pago debe ser QR o efectivo.');
    }

    final dynamic response = await _client.rpc(
      'register_manual_payment',
      params: <String, dynamic>{
        'p_player_id': normalizedPlayerId,
        'p_amount': amount,
        'p_payment_date': _formatDate(paymentDate),
        'p_payment_method': normalizedMethod,
        'p_notes': _normalizeNullableText(notes),
      },
    );

    return _extractSingleMap(
      response,
      'Supabase no devolvió información del pago registrado.',
    );
  }

  /// Corrige un pago manual previamente registrado.
  ///
  /// Mantiene el mismo identificador del movimiento.
  static Future<Map<String, dynamic>> updateManualPayment({
    required String paymentRecordId,
    required double amount,
    required DateTime paymentDate,
    required String paymentMethod,
    String? notes,
  }) async {
    final String normalizedPaymentId = paymentRecordId.trim();
    final String normalizedMethod = paymentMethod.trim().toLowerCase();

    if (normalizedPaymentId.isEmpty) {
      throw const FormatException('El identificador del pago es obligatorio.');
    }

    if (amount <= 0) {
      throw const FormatException('El monto del pago debe ser mayor a cero.');
    }

    if (normalizedMethod != 'qr' && normalizedMethod != 'cash') {
      throw const FormatException('El método de pago debe ser QR o efectivo.');
    }

    final dynamic response = await _client.rpc(
      'update_manual_payment',
      params: <String, dynamic>{
        'p_payment_record_id': normalizedPaymentId,
        'p_amount': amount,
        'p_payment_date': _formatDate(paymentDate),
        'p_payment_method': normalizedMethod,
        'p_notes': _normalizeNullableText(notes),
      },
    );

    return _extractSingleMap(
      response,
      'Supabase no devolvió información del pago corregido.',
    );
  }

  /// Obtiene los pagos confirmados de un jugador.
  static Future<List<Map<String, dynamic>>> getPlayerManualPaymentHistory({
    required String playerId,
  }) async {
    final String normalizedPlayerId = playerId.trim();

    if (normalizedPlayerId.isEmpty) {
      throw const FormatException(
        'El identificador del jugador es obligatorio.',
      );
    }

    final dynamic response = await _client.rpc(
      'get_player_manual_payment_history',
      params: <String, dynamic>{'p_player_id': normalizedPlayerId},
    );

    return _extractMapList(
      response,
      'Supabase no devolvió un historial de pagos válido.',
    );
  }

  /// Obtiene todos los pagos confirmados de la escuela.
  static Future<List<Map<String, dynamic>>> getSchoolManualPayments() async {
    final dynamic response = await _client.rpc('get_school_manual_payments');

    return _extractMapList(
      response,
      'Supabase no devolvió un registro general de pagos válido.',
    );
  }

  /// Obtiene el resumen financiero real de un mes.
  ///
  /// Solo considera dinero confirmado en payment_records.
  static Future<Map<String, dynamic>> getSchoolManualFinancialSummary({
    required int year,
    required int month,
  }) async {
    if (year < 2000 || year > 2100) {
      throw const FormatException('El año indicado no es válido.');
    }

    if (month < 1 || month > 12) {
      throw const FormatException('El mes debe estar entre 1 y 12.');
    }

    final dynamic response = await _client.rpc(
      'get_school_manual_financial_summary',
      params: <String, dynamic>{'p_year': year, 'p_month': month},
    );

    return _extractSingleMap(
      response,
      'Supabase no devolvió un resumen financiero válido.',
    );
  }

  // ============================================================
  // SISTEMA ANTERIOR
  //
  // Lo conservamos TEMPORALMENTE mientras sustituimos
  // las pantallas antiguas. Esto evita errores de compilación
  // durante la migración.
  // ============================================================

  /// Obtiene el estado financiero actual de un jugador.
  static Future<Map<String, dynamic>> getPlayerCurrentFee({
    required String playerId,
    DateTime? referenceDate,
  }) async {
    final DateTime date = referenceDate ?? DateTime.now();

    final dynamic response = await _client.rpc(
      'get_player_account_status',
      params: <String, dynamic>{
        'p_player_id': playerId,
        'p_reference_date': _formatDate(date),
      },
    );

    return _extractSingleMap(
      response,
      'No existe un estado de cuenta vigente para este jugador.',
    );
  }

  /// Registra un pago en efectivo mediante el sistema anterior.
  static Future<Map<String, dynamic>> registerCashPayment({
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

    final DateTime date = paymentDate ?? DateTime.now();

    final dynamic response = await _client.rpc(
      'register_cash_payment',
      params: <String, dynamic>{
        'p_player_id': normalizedPlayerId,
        'p_amount': amount,
        'p_payment_date': _formatDate(date),
        'p_notes': _normalizeNullableText(notes),
      },
    );

    return _extractSingleMap(
      response,
      'Supabase no devolvió información del pago registrado.',
    );
  }

  /// Obtiene el detalle mensual anterior de cobranza.
  static Future<List<Map<String, dynamic>>> getSchoolMonthlyCollectionDetail({
    required int year,
    required int month,
  }) async {
    if (year < 2000 || year > 2100) {
      throw const FormatException('El año indicado no es válido.');
    }

    if (month < 1 || month > 12) {
      throw const FormatException('El mes debe estar entre 1 y 12.');
    }

    final dynamic response = await _client.rpc(
      'get_school_monthly_collection_detail',
      params: <String, dynamic>{'p_year': year, 'p_month': month},
    );

    return _extractMapList(
      response,
      'Supabase no devolvió un detalle de cobranza mensual válido.',
    );
  }

  /// Historial anterior de pagos.
  static Future<List<Map<String, dynamic>>> getPlayerPaymentHistory({
    required String playerId,
  }) async {
    final String normalizedPlayerId = playerId.trim();

    if (normalizedPlayerId.isEmpty) {
      throw const FormatException(
        'El identificador del jugador es obligatorio.',
      );
    }

    final dynamic response = await _client.rpc(
      'get_player_payment_history',
      params: <String, dynamic>{'p_player_id': normalizedPlayerId},
    );

    return _extractMapList(
      response,
      'Supabase no devolvió un historial de pagos válido.',
    );
  }

  /// Resumen financiero anterior.
  static Future<Map<String, dynamic>> getSchoolFinancialSummary({
    required int year,
    required int month,
  }) async {
    if (year < 2000 || year > 2100) {
      throw const FormatException('El año indicado no es válido.');
    }

    if (month < 1 || month > 12) {
      throw const FormatException('El mes debe estar entre 1 y 12.');
    }

    final dynamic response = await _client.rpc(
      'get_school_financial_summary',
      params: <String, dynamic>{'p_year': year, 'p_month': month},
    );

    return _extractSingleMap(
      response,
      'Supabase no devolvió un resumen financiero válido.',
    );
  }

  /// Reporte QR del sistema anterior.
  static Future<Map<String, dynamic>> reportQrPayment({
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

    final DateTime date = paymentDate ?? DateTime.now();

    final dynamic response = await _client.rpc(
      'report_qr_payment',
      params: <String, dynamic>{
        'p_player_id': normalizedPlayerId,
        'p_amount': amount,
        'p_receipt_url': normalizedReceiptUrl,
        'p_transaction_reference': _normalizeNullableText(transactionReference),
        'p_payment_date': _formatDate(date),
        'p_notes': _normalizeNullableText(notes),
      },
    );

    return _extractSingleMap(
      response,
      'Supabase no devolvió información del pago QR reportado.',
    );
  }

  /// Bandeja QR anterior.
  static Future<List<Map<String, dynamic>>> getQrPaymentsForAdmin() async {
    final dynamic response = await _client.rpc('get_qr_payments_for_admin');

    return _extractMapList(
      response,
      'Supabase no devolvió una lista válida de pagos QR.',
    );
  }

  /// Confirma QR del sistema anterior.
  static Future<Map<String, dynamic>> confirmQrPayment({
    required String paymentRecordId,
    String? notes,
  }) async {
    final String normalizedId = paymentRecordId.trim();

    if (normalizedId.isEmpty) {
      throw const FormatException('El identificador del pago es obligatorio.');
    }

    final dynamic response = await _client.rpc(
      'confirm_qr_payment',
      params: <String, dynamic>{
        'p_payment_record_id': normalizedId,
        'p_notes': _normalizeNullableText(notes),
      },
    );

    return _extractSingleMap(
      response,
      'Supabase no devolvió información del pago QR confirmado.',
    );
  }

  /// Rechaza QR del sistema anterior.
  static Future<Map<String, dynamic>> rejectQrPayment({
    required String paymentRecordId,
    String? notes,
  }) async {
    final String normalizedId = paymentRecordId.trim();

    if (normalizedId.isEmpty) {
      throw const FormatException('El identificador del pago es obligatorio.');
    }

    final dynamic response = await _client.rpc(
      'reject_qr_payment',
      params: <String, dynamic>{
        'p_payment_record_id': normalizedId,
        'p_notes': _normalizeNullableText(notes),
      },
    );

    return _extractSingleMap(
      response,
      'Supabase no devolvió información del pago QR rechazado.',
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static Map<String, dynamic> _extractSingleMap(
    dynamic response,
    String errorMessage,
  ) {
    if (response is List && response.isNotEmpty) {
      final dynamic first = response.first;

      if (first is Map) {
        return Map<String, dynamic>.from(first);
      }
    }

    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }

    throw PostgrestException(message: errorMessage);
  }

  static List<Map<String, dynamic>> _extractMapList(
    dynamic response,
    String errorMessage,
  ) {
    if (response is! List) {
      throw PostgrestException(message: errorMessage);
    }

    return response.map((dynamic item) {
      if (item is! Map) {
        throw FormatException(errorMessage);
      }

      return Map<String, dynamic>.from(item);
    }).toList();
  }
}

String _formatDate(DateTime date) {
  final String month = date.month.toString().padLeft(2, '0');
  final String day = date.day.toString().padLeft(2, '0');

  return '${date.year}-$month-$day';
}

String? _normalizeNullableText(String? value) {
  final String text = value?.trim() ?? '';

  return text.isEmpty ? null : text;
}
