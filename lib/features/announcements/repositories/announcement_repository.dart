import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/auth_service.dart';
import '../models/announcement_model.dart';

class AnnouncementRepository {
  const AnnouncementRepository();

  static const String tableName = 'announcements';

  SupabaseClient get _client => Supabase.instance.client;

  static const String _selectFields = '''
    id,
    school_id,
    training_group_id,
    title,
    message,
    priority,
    audience,
    publish_date,
    expires_on,
    status,
    created_by,
    training_groups (
      name
    )
  ''';

  Future<List<AnnouncementModel>> getAnnouncements() async {
    final Map<String, dynamic> profile = await AuthService.getCurrentProfile();

    final String? schoolId = profile['school_id']?.toString();

    if (schoolId == null || schoolId.trim().isEmpty) {
      throw const AuthException(
        'El usuario actual no tiene una escuela asignada.',
      );
    }

    final List<dynamic> response = await _client
        .from(tableName)
        .select(_selectFields)
        .eq('school_id', schoolId)
        .order('publish_date', ascending: false)
        .order('created_at', ascending: false);

    return response
        .map(
          (dynamic item) =>
              AnnouncementModel.fromMap(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<AnnouncementModel?> getAnnouncementById(String id) async {
    final Map<String, dynamic>? response = await _client
        .from(tableName)
        .select(_selectFields)
        .eq('id', id)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return AnnouncementModel.fromMap(response);
  }

  Future<AnnouncementModel> createAnnouncement(
    AnnouncementModel announcement,
  ) async {
    final Map<String, dynamic> profile = await AuthService.getCurrentProfile();

    final String? schoolId = profile['school_id']?.toString();
    final String? createdBy = _client.auth.currentUser?.id;

    if (schoolId == null || schoolId.trim().isEmpty) {
      throw const AuthException(
        'El usuario actual no tiene una escuela asignada.',
      );
    }

    if (createdBy == null || createdBy.trim().isEmpty) {
      throw Exception('No fue posible identificar al usuario actual.');
    }

    final Map<String, dynamic> data = Map<String, dynamic>.from(
      announcement.toMap(),
    );

    data['school_id'] = schoolId;
    data['created_by'] = createdBy;

    final Map<String, dynamic> response = await _client
        .from(tableName)
        .insert(data)
        .select(_selectFields)
        .single();

    return AnnouncementModel.fromMap(response);
  }

  Future<AnnouncementModel> updateAnnouncement(
    AnnouncementModel announcement,
  ) async {
    if (announcement.id.trim().isEmpty) {
      throw Exception('No fue posible identificar el comunicado.');
    }

    final Map<String, dynamic> data = Map<String, dynamic>.from(
      announcement.toMap(),
    );

    data.remove('school_id');
    data.remove('created_by');

    final Map<String, dynamic> response = await _client
        .from(tableName)
        .update(data)
        .eq('id', announcement.id)
        .select(_selectFields)
        .single();

    return AnnouncementModel.fromMap(response);
  }

  Future<void> updateStatus({
    required String id,
    required String status,
  }) async {
    await _client
        .from(tableName)
        .update(<String, dynamic>{'status': status})
        .eq('id', id);
  }

  Future<void> deleteAnnouncement(String id) async {
    await _client.from(tableName).delete().eq('id', id);
  }
}
