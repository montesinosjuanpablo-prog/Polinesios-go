import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/auth_service.dart';
import '../models/match_model.dart';

class MatchRepository {
  const MatchRepository();

  static const String tableName = 'matches';

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<MatchModel>> getMatches() async {
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
              training_group_id,
              location_id,
              opponent_name,
              match_date,
              start_time,
              home_away,
              status,
              goals_for,
              goals_against,
              notes,
              created_by,
              training_groups (
                name
              ),
              locations (
                name
              )
              ''')
        .eq('school_id', schoolId)
        .order('match_date', ascending: false)
        .order('start_time', ascending: true);

    return response
        .map(
          (dynamic item) =>
              MatchModel.fromMap(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<MatchModel?> getMatchById(String id) async {
    final Map<String, dynamic>? response = await _client
        .from(tableName)
        .select('''
              id,
              school_id,
              training_group_id,
              location_id,
              opponent_name,
              match_date,
              start_time,
              home_away,
              status,
              goals_for,
              goals_against,
              notes,
              created_by,
              training_groups (
                name
              ),
              locations (
                name
              )
              ''')
        .eq('id', id)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return MatchModel.fromMap(response);
  }

  Future<MatchModel> createMatch(MatchModel match) async {
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

    final Map<String, dynamic> data = Map<String, dynamic>.from(match.toMap());

    data['school_id'] = schoolId;
    data['created_by'] = createdBy;

    final Map<String, dynamic> response = await _client
        .from(tableName)
        .insert(data)
        .select('''
              id,
              school_id,
              training_group_id,
              location_id,
              opponent_name,
              match_date,
              start_time,
              home_away,
              status,
              goals_for,
              goals_against,
              notes,
              created_by,
              training_groups (
                name
              ),
              locations (
                name
              )
              ''')
        .single();

    return MatchModel.fromMap(response);
  }

  Future<MatchModel> updateMatch(MatchModel match) async {
    if (match.id.trim().isEmpty) {
      throw Exception('No fue posible identificar el partido.');
    }

    final Map<String, dynamic> data = Map<String, dynamic>.from(match.toMap());

    // Nunca modificamos estos campos
    // durante una edición normal.
    data.remove('school_id');
    data.remove('created_by');

    final Map<String, dynamic> response = await _client
        .from(tableName)
        .update(data)
        .eq('id', match.id)
        .select('''
              id,
              school_id,
              training_group_id,
              location_id,
              opponent_name,
              match_date,
              start_time,
              home_away,
              status,
              goals_for,
              goals_against,
              notes,
              created_by,
              training_groups (
                name
              ),
              locations (
                name
              )
              ''')
        .single();

    return MatchModel.fromMap(response);
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

  Future<void> updateResult({
    required String id,
    required int goalsFor,
    required int goalsAgainst,
  }) async {
    if (goalsFor < 0 || goalsAgainst < 0) {
      throw Exception('Los goles no pueden ser negativos.');
    }

    await _client
        .from(tableName)
        .update(<String, dynamic>{
          'goals_for': goalsFor,
          'goals_against': goalsAgainst,
          'status': 'completed',
        })
        .eq('id', id);
  }

  Future<void> deleteMatch(String id) async {
    await _client.from(tableName).delete().eq('id', id);
  }
}
