import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/auth_service.dart';
import '../models/training_group_model.dart';

class TrainingGroupRepository {
  const TrainingGroupRepository();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<TrainingGroupModel>> getActiveGroups() async {
    final Map<String, dynamic> profile = await AuthService.getCurrentProfile();

    final String? schoolId = profile['school_id']?.toString();

    if (schoolId == null || schoolId.trim().isEmpty) {
      throw const AuthException(
        'El usuario actual no tiene una escuela asignada.',
      );
    }

    final List<dynamic> response = await _client
        .from('training_groups')
        .select('''
          id,
          school_id,
          category_id,
          location_id,
          coach_id,
          name,
          start_time,
          end_time,
          status,
          locations (
            name
          ),
          profiles!training_groups_coach_id_fkey (
            first_name,
            last_name
          )
          ''')
        .eq('school_id', schoolId)
        .eq('status', 'active')
        .order('name');

    return response
        .map(
          (dynamic item) => TrainingGroupModel.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }
}
