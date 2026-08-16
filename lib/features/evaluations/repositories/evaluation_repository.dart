import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/auth_service.dart';
import '../models/evaluation_model.dart';

class EvaluationRepository {
  const EvaluationRepository();

  static const String tableName = 'player_evaluations';

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<EvaluationModel>> getEvaluations() async {
    final Map<String, dynamic> profile = await AuthService.getCurrentProfile();

    final String? schoolId = profile['school_id']?.toString();

    if (schoolId == null || schoolId.trim().isEmpty) {
      throw const AuthException(
        'El usuario actual no tiene una escuela asignada.',
      );
    }

    final List<dynamic> response = await _client
        .from(tableName)
        .select('''
              id,
              school_id,
              player_id,
              evaluator_id,
              evaluation_date,
              technical_score,
              tactical_score,
              physical_score,
              attitude_score,
              strengths,
              areas_to_improve,
              observations,
              status,
              players (
                first_name,
                last_name
              ),
              profiles (
                first_name,
                last_name
              )
              ''')
        .eq('school_id', schoolId)
        .order('evaluation_date', ascending: false)
        .order('created_at', ascending: false);

    return response
        .map(
          (dynamic item) =>
              EvaluationModel.fromMap(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<EvaluationModel?> getEvaluationById(String id) async {
    final Map<String, dynamic>? response = await _client
        .from(tableName)
        .select('''
              id,
              school_id,
              player_id,
              evaluator_id,
              evaluation_date,
              technical_score,
              tactical_score,
              physical_score,
              attitude_score,
              strengths,
              areas_to_improve,
              observations,
              status,
              players (
                first_name,
                last_name
              ),
              profiles (
                first_name,
                last_name
              )
              ''')
        .eq('id', id)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return EvaluationModel.fromMap(response);
  }

  Future<EvaluationModel> createEvaluation(EvaluationModel evaluation) async {
    final Map<String, dynamic> profile = await AuthService.getCurrentProfile();

    final String? schoolId = profile['school_id']?.toString();

    final String? evaluatorId = _client.auth.currentUser?.id;

    if (schoolId == null || schoolId.trim().isEmpty) {
      throw const AuthException(
        'El usuario actual no tiene una escuela asignada.',
      );
    }

    if (evaluatorId == null || evaluatorId.trim().isEmpty) {
      throw Exception('No fue posible identificar al evaluador.');
    }

    final Map<String, dynamic> data = Map<String, dynamic>.from(
      evaluation.toMap(),
    );

    data['school_id'] = schoolId;
    data['evaluator_id'] = evaluatorId;

    final Map<String, dynamic> response = await _client
        .from(tableName)
        .insert(data)
        .select('''
              id,
              school_id,
              player_id,
              evaluator_id,
              evaluation_date,
              technical_score,
              tactical_score,
              physical_score,
              attitude_score,
              strengths,
              areas_to_improve,
              observations,
              status,
              players (
                first_name,
                last_name
              ),
              profiles (
                first_name,
                last_name
              )
              ''')
        .single();

    return EvaluationModel.fromMap(response);
  }

  Future<EvaluationModel> updateEvaluation(EvaluationModel evaluation) async {
    if (evaluation.id.trim().isEmpty) {
      throw Exception('No fue posible identificar la evaluación.');
    }

    final Map<String, dynamic> data = Map<String, dynamic>.from(
      evaluation.toMap(),
    );

    data.remove('school_id');
    data.remove('evaluator_id');

    final Map<String, dynamic> response = await _client
        .from(tableName)
        .update(data)
        .eq('id', evaluation.id)
        .select('''
              id,
              school_id,
              player_id,
              evaluator_id,
              evaluation_date,
              technical_score,
              tactical_score,
              physical_score,
              attitude_score,
              strengths,
              areas_to_improve,
              observations,
              status,
              players (
                first_name,
                last_name
              ),
              profiles (
                first_name,
                last_name
              )
              ''')
        .single();

    return EvaluationModel.fromMap(response);
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

  Future<void> deleteEvaluation(String id) async {
    await _client.from(tableName).delete().eq('id', id);
  }
}
