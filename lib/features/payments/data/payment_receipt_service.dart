import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentReceiptService {
  const PaymentReceiptService();

  static const String _bucketName = 'payment-receipts';

  SupabaseClient get _client => Supabase.instance.client;

  Future<String> createPendingReceipt({
    required String playerId,
    required String playerName,
    required String categoryName,
    required String paymentPeriod,
    required double amount,
    required String receiptUrl,
  }) async {
    final Map<String, dynamic> response = await _client
        .from('payment_receipts')
        .insert(<String, dynamic>{
          'player_id': playerId,
          'player_name': playerName.trim(),
          'category_name': categoryName.trim(),
          'payment_period': paymentPeriod.trim(),
          'amount': amount,
          'receipt_url': receiptUrl.trim(),
          'status': 'pending',
        })
        .select('id')
        .single();

    final String receiptId = response['id']?.toString().trim() ?? '';

    if (receiptId.isEmpty) {
      throw const PostgrestException(
        message:
            'No se pudo obtener el identificador '
            'del comprobante.',
      );
    }

    return receiptId;
  }

  Future<List<Map<String, dynamic>>> getAllReceipts() async {
    final List<dynamic> response = await _client
        .from('payment_receipts')
        .select('''
              id,
              player_id,
              player_name,
              category_name,
              payment_period,
              amount,
              receipt_url,
              status,
              submitted_at,
              reviewed_at,
              review_notes
              ''')
        .order('submitted_at', ascending: false);

    return response
        .map((dynamic item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> approveReceipt({required String receiptId}) async {
    await _updateReceiptStatus(
      receiptId: receiptId,
      status: 'approved',
      reviewNotes: 'Pago aprobado por administración.',
    );
  }

  Future<void> rejectReceipt({
    required String receiptId,
    String? reviewNotes,
  }) async {
    final String normalizedNotes = reviewNotes?.trim() ?? '';

    await _updateReceiptStatus(
      receiptId: receiptId,
      status: 'rejected',
      reviewNotes: normalizedNotes.isEmpty
          ? 'Comprobante rechazado '
                'por administración.'
          : normalizedNotes,
    );
  }

  Future<void> deleteReceipt({
    required String receiptId,
    required String receiptUrl,
  }) async {
    final String normalizedId = receiptId.trim();

    if (normalizedId.isEmpty) {
      throw const PostgrestException(
        message:
            'El identificador del comprobante '
            'no es válido.',
      );
    }

    final String storagePath = _extractStoragePath(receiptUrl);

    if (storagePath.isNotEmpty) {
      await _client.storage.from(_bucketName).remove(<String>[storagePath]);
    }

    await _client.from('payment_receipts').delete().eq('id', normalizedId);
  }

  Future<void> _updateReceiptStatus({
    required String receiptId,
    required String status,
    required String reviewNotes,
  }) async {
    final String normalizedId = receiptId.trim();

    if (normalizedId.isEmpty) {
      throw const PostgrestException(
        message:
            'El identificador del comprobante '
            'no es válido.',
      );
    }

    await _client
        .from('payment_receipts')
        .update(<String, dynamic>{
          'status': status,
          'reviewed_at': DateTime.now().toUtc().toIso8601String(),
          'review_notes': reviewNotes,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', normalizedId);
  }

  Future<void> updateReceiptStatus({
    required String id,
    required String status,
  }) async {
    await _client
        .from('payment_receipts')
        .update(<String, dynamic>{'status': status})
        .eq('id', id);
  }

  String _extractStoragePath(String publicUrl) {
    final String normalizedUrl = publicUrl.trim();

    if (normalizedUrl.isEmpty) {
      return '';
    }

    final Uri? uri = Uri.tryParse(normalizedUrl);

    if (uri == null) {
      return '';
    }

    final List<String> segments = uri.pathSegments;

    final int publicIndex = segments.indexOf('public');

    if (publicIndex == -1 || publicIndex + 1 >= segments.length) {
      return '';
    }

    final String bucket = segments[publicIndex + 1];

    if (bucket != _bucketName) {
      return '';
    }

    final List<String> objectSegments = segments.sublist(publicIndex + 2);

    if (objectSegments.isEmpty) {
      return '';
    }

    return objectSegments.map(Uri.decodeComponent).join('/');
  }
}
