import 'package:supabase_flutter/supabase_flutter.dart';

class AttendanceService {
  AttendanceService._();

  static SupabaseClient get _client => Supabase.instance.client;

  /// Obtiene los grupos de entrenamiento activos,
  /// junto con su categoría y sede.
  static Future<List<Map<String, dynamic>>> getTrainingGroups() async {
    final List<dynamic> response = await _client
        .from('training_groups')
        .select('''
          id,
          school_id,
          category_id,
          location_id,
          name,
          start_time,
          end_time,
          status,
          categories (
            id,
            name
          ),
          locations (
            id,
            name,
            address
          )
        ''')
        .eq('status', 'active')
        .order('start_time', ascending: true);

    return response
        .map((dynamic item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  /// Obtiene los jugadores activos asignados actualmente
  /// a un grupo de entrenamiento.
  static Future<List<Map<String, dynamic>>> getPlayersByTrainingGroup(
    String trainingGroupId,
  ) async {
    final List<dynamic> response = await _client
        .from('player_group_assignments')
        .select('''
          id,
          player_id,
          training_group_id,
          start_date,
          end_date,
          is_current,
          players (
            id,
            player_code,
            photo_url,
            first_name,
            last_name,
            birth_date,
            status
          )
        ''')
        .eq('training_group_id', trainingGroupId)
        .eq('is_current', true)
        .order('start_date', ascending: true);

    return response
        .map((dynamic item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  /// Obtiene la asistencia ya guardada para un grupo y una fecha.
  static Future<List<Map<String, dynamic>>> getSavedAttendance({
    required String trainingGroupId,
    required DateTime sessionDate,
  }) async {
    final String normalizedGroupId = trainingGroupId.trim();

    if (normalizedGroupId.isEmpty) {
      throw const FormatException(
        'Debes seleccionar un grupo de entrenamiento.',
      );
    }

    final List<dynamic> sessions = await _client
        .from('training_sessions')
        .select('id, session_date, training_group_id, created_at')
        .eq('training_group_id', normalizedGroupId)
        .eq('session_date', _formatDate(sessionDate))
        .order('created_at', ascending: false)
        .limit(1);

    if (sessions.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final Map<String, dynamic> session = Map<String, dynamic>.from(
      sessions.first as Map,
    );

    final String sessionId = session['id']?.toString().trim() ?? '';

    if (sessionId.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final List<dynamic> response = await _client
        .from('attendance_records')
        .select('''
          id,
          training_session_id,
          player_id,
          attendance_status,
          notes,
          created_at,
          updated_at
        ''')
        .eq('training_session_id', sessionId);

    return response
        .map((dynamic item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  /// Obtiene las sesiones de entrenamiento más recientes.
  static Future<List<Map<String, dynamic>>> getRecentTrainingSessions({
    int limit = 20,
  }) async {
    final List<dynamic> response = await _client
        .from('training_sessions')
        .select('''
          id,
          school_id,
          training_group_id,
          location_id,
          session_date,
          start_time,
          end_time,
          title,
          notes,
          status,
          created_at,
          training_groups (
            id,
            name
          ),
          locations (
            id,
            name
          )
        ''')
        .order('session_date', ascending: false)
        .order('start_time', ascending: false)
        .limit(limit);

    return response
        .map((dynamic item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  /// Crea o actualiza una sesión de entrenamiento
  /// y guarda toda la lista de asistencia.
  static Future<String> saveTrainingAttendance({
    required String trainingGroupId,
    required DateTime sessionDate,
    required List<Map<String, dynamic>> attendance,
    String? sessionNotes,
  }) async {
    final dynamic response = await _client.rpc(
      'save_training_attendance',
      params: <String, dynamic>{
        'p_training_group_id': trainingGroupId,
        'p_session_date': _formatDate(sessionDate),
        'p_attendance': attendance,
        'p_session_notes': _normalizeNullableText(sessionNotes),
      },
    );

    final String sessionId = response?.toString().trim() ?? '';

    if (sessionId.isEmpty) {
      throw const PostgrestException(
        message:
            'Supabase no devolvió el identificador '
            'de la sesión de entrenamiento.',
      );
    }

    return sessionId;
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
