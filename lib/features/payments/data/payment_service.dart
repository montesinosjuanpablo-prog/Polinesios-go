import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentService {
  PaymentService._();

  static SupabaseClient get _client => Supabase.instance.client;

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
      'No existe un estado de cuenta vigente '
      'para este jugador.',
    );
  }

  /// Registra un pago en efectivo y lo confirma
  /// inmediatamente.
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
      'Supabase no devolvió información '
      'del pago registrado.',
    );
  }

  /// Obtiene el detalle de cobranza de todos los jugadores
  /// para un período mensual determinado.
  ///
  /// Devuelve un registro consolidado por jugador con:
  /// - monto esperado;
  /// - monto pagado;
  /// - saldo pendiente;
  /// - estado de cobranza;
  /// - pagos confirmados por QR;
  /// - pagos confirmados en efectivo.
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

    if (response is! List) {
      throw const PostgrestException(
        message:
            'Supabase no devolvió un detalle '
            'de cobranza mensual válido.',
      );
    }

    return response.map((dynamic item) {
      if (item is! Map) {
        throw const FormatException(
          'Supabase devolvió un registro de cobranza '
          'con formato inválido.',
        );
      }

      return Map<String, dynamic>.from(item);
    }).toList();
  }

  /// Obtiene el historial completo de pagos de un jugador.
  ///
  /// Incluye pagos:
  /// - confirmados;
  /// - rechazados;
  /// - pendientes de verificación;
  /// - realizados por QR, efectivo u otros métodos.
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

    if (response is List) {
      return response
          .map((dynamic item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    throw const PostgrestException(
      message: 'Supabase no devolvió un historial de pagos válido.',
    );
  }

  /// Obtiene el resumen financiero general de la escuela
  /// para un mes y año determinados.
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

  /// Reporta un pago realizado mediante QR.
  ///
  /// El pago queda pendiente de verificación
  /// administrativa y todavía no modifica
  /// el monto pagado de la mensualidad.
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
      'Supabase no devolvió información '
      'del pago QR reportado.',
    );
  }

  /// Obtiene todos los pagos QR de la escuela
  /// para su revisión administrativa.
  ///
  /// La seguridad real de acceso está también
  /// validada dentro de la RPC.
  static Future<List<Map<String, dynamic>>> getQrPaymentsForAdmin() async {
    final dynamic response = await _client.rpc('get_qr_payments_for_admin');

    if (response is! List) {
      throw const PostgrestException(
        message:
            'Supabase no devolvió una lista válida '
            'de pagos QR.',
      );
    }

    return response.map((dynamic item) {
      if (item is! Map) {
        throw const FormatException(
          'Supabase devolvió un pago QR '
          'con formato inválido.',
        );
      }

      return Map<String, dynamic>.from(item);
    }).toList();
  }

  /// Confirma administrativamente un pago QR.
  ///
  /// Al confirmarse, la RPC incrementa
  /// payment_charges.amount_paid y actualiza
  /// el estado de la mensualidad.
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
      'Supabase no devolvió información '
      'del pago QR confirmado.',
    );
  }

  /// Rechaza administrativamente un pago QR.
  ///
  /// El rechazo NO modifica el monto pagado
  /// de la mensualidad.
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
      'Supabase no devolvió información '
      'del pago QR rechazado.',
    );
  }

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
