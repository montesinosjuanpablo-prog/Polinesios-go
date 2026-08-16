import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/auth_service.dart';
import '../models/training_session_model.dart';

class TrainingRepository {
  const TrainingRepository();

  static const String tableName = 'training_sessions';

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<TrainingSessionModel>> getTrainingSessions() async {
    final List<dynamic> response = await _client
        .from(tableName)
        .select()
        .order('training_date', ascending: false)
        .order('start_time', ascending: true);

    return response
        .map(
          (dynamic item) => TrainingSessionModel.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<TrainingSessionModel?> getTrainingSessionById(String id) async {
    final Map<String, dynamic>? response = await _client
        .from(tableName)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return TrainingSessionModel.fromMap(response);
  }

  Future<TrainingSessionModel> createTrainingSession(
    TrainingSessionModel session,
  ) async {
    final Map<String, dynamic> profile = await AuthService.getCurrentProfile();

    final String? schoolId = profile['school_id']?.toString();

    final String? createdBy = profile['id']?.toString();

    if (schoolId == null || schoolId.trim().isEmpty) {
      throw const AuthException(
        'El usuario actual no tiene una escuela asignada.',
      );
    }

    if (createdBy == null || createdBy.trim().isEmpty) {
      throw Exception('No fue posible identificar al usuario actual.');
    }

    final String? trainingGroupId = session.trainingGroupId;

    if (trainingGroupId == null || trainingGroupId.trim().isEmpty) {
      throw Exception('Debes seleccionar un grupo de entrenamiento.');
    }

    final String trainingDate =
        '${session.date.year.toString().padLeft(4, '0')}-'
        '${session.date.month.toString().padLeft(2, '0')}-'
        '${session.date.day.toString().padLeft(2, '0')}';

    final Map<String, dynamic>? existingSession = await _client
        .from(tableName)
        .select()
        .eq('school_id', schoolId)
        .eq('training_group_id', trainingGroupId)
        .eq('training_date', trainingDate)
        .eq('start_time', session.startTime)
        .maybeSingle();

    final Map<String, dynamic> data = Map<String, dynamic>.from(
      session.toMap(),
    );

    data['school_id'] = schoolId;
    data['training_group_id'] = trainingGroupId;

    if (existingSession != null) {
      final String existingId = existingSession['id']?.toString().trim() ?? '';

      if (existingId.isEmpty) {
        throw Exception(
          'Se encontró una sesión existente, '
          'pero no fue posible identificarla.',
        );
      }

      debugPrint(
        'ENTRENAMIENTO EXISTENTE: '
        'se actualizará la sesión $existingId',
      );

      final Map<String, dynamic> response = await _client
          .from(tableName)
          .update(data)
          .eq('id', existingId)
          .select()
          .single();

      return TrainingSessionModel.fromMap(response);
    }

    data['created_by'] = createdBy;

    debugPrint('NUEVO ENTRENAMIENTO: $data');

    final Map<String, dynamic> response = await _client
        .from(tableName)
        .insert(data)
        .select()
        .single();

    return TrainingSessionModel.fromMap(response);
  }

  Future<TrainingSessionModel> updateTrainingSession(
    TrainingSessionModel session,
  ) async {
    if (session.id.trim().isEmpty) {
      throw Exception('No fue posible identificar el entrenamiento.');
    }

    final Map<String, dynamic> data = Map<String, dynamic>.from(
      session.toMap(),
    );

    final Map<String, dynamic> response = await _client
        .from(tableName)
        .update(data)
        .eq('id', session.id)
        .select()
        .single();

    return TrainingSessionModel.fromMap(response);
  }

  Future<void> deleteTrainingSession(String id) async {
    await _client.from(tableName).delete().eq('id', id);
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
}
