import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentRecordService {
  const PaymentRecordService();

  SupabaseClient get _client => Supabase.instance.client;

  Future<String> registerCashPayment({
    required String schoolId,
    required String playerId,
    required String paymentChargeId,
    required double amount,
    String? notes,
  }) async {
    final String normalizedSchoolId = schoolId.trim();
    final String normalizedPlayerId = playerId.trim();
    final String normalizedChargeId = paymentChargeId.trim();

    if (normalizedSchoolId.isEmpty) {
      throw Exception('No se pudo identificar la escuela.');
    }

    if (normalizedPlayerId.isEmpty) {
      throw Exception('No se pudo identificar al jugador.');
    }

    if (normalizedChargeId.isEmpty) {
      throw Exception('No se pudo identificar el cargo.');
    }

    if (amount <= 0) {
      throw Exception('El importe del pago debe ser mayor a cero.');
    }

    final String? currentUserId = _client.auth.currentUser?.id;

    if (currentUserId == null || currentUserId.trim().isEmpty) {
      throw Exception('No se pudo identificar al usuario actual.');
    }

    final DateTime now = DateTime.now();

    final String paymentDate =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    final Map<String, dynamic> response = await _client
        .from('payment_records')
        .insert(<String, dynamic>{
          'school_id': normalizedSchoolId,
          'payment_charge_id': normalizedChargeId,
          'player_id': normalizedPlayerId,
          'amount': amount,
          'payment_date': paymentDate,
          'payment_method': 'cash',
          'transaction_reference': null,
          'receipt_url': null,
          'status': 'confirmed',
          'notes': notes?.trim(),
          'reported_by': currentUserId,
          'verified_by': currentUserId,
          'verified_at': DateTime.now().toUtc().toIso8601String(),
        })
        .select('id')
        .single();

    final String paymentRecordId = response['id']?.toString().trim() ?? '';

    if (paymentRecordId.isEmpty) {
      throw Exception('No fue posible obtener el identificador del pago.');
    }

    return paymentRecordId;
  }
}
