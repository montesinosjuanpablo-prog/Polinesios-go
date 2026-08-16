import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  const StorageService();

  // =========================================================
  // BUCKETS
  // =========================================================

  static const String paymentReceiptsBucketName = 'payment-receipts';

  static const String playerPhotosBucketName = 'player-photos';

  SupabaseClient get _client => Supabase.instance.client;

  // =========================================================
  // COMPROBANTES DE PAGO
  // =========================================================

  Future<String> uploadPaymentReceipt({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final String filePath =
        'receipts/'
        '${DateTime.now().millisecondsSinceEpoch}_$fileName';

    await _client.storage
        .from(paymentReceiptsBucketName)
        .uploadBinary(
          filePath,
          bytes,
          fileOptions: const FileOptions(upsert: false),
        );

    return _client.storage
        .from(paymentReceiptsBucketName)
        .getPublicUrl(filePath);
  }

  // =========================================================
  // FOTOGRAFÍAS DE JUGADORES
  // =========================================================

  Future<String> uploadPlayerPhoto({
    required Uint8List bytes,
    required String fileName,
    required String playerId,
  }) async {
    final String normalizedPlayerId = playerId.trim();

    if (normalizedPlayerId.isEmpty) {
      throw Exception('No fue posible identificar al jugador.');
    }

    final String normalizedFileName = fileName.trim().isEmpty
        ? 'player_photo.jpg'
        : fileName.trim();

    final String filePath =
        'players/'
        '$normalizedPlayerId/'
        '${DateTime.now().millisecondsSinceEpoch}_'
        '$normalizedFileName';

    await _client.storage
        .from(playerPhotosBucketName)
        .uploadBinary(
          filePath,
          bytes,
          fileOptions: const FileOptions(upsert: false),
        );

    return _client.storage.from(playerPhotosBucketName).getPublicUrl(filePath);
  }
}
