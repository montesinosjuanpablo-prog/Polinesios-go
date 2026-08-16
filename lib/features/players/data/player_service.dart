import 'package:supabase_flutter/supabase_flutter.dart';

class PlayerService {
  PlayerService._();

  static SupabaseClient get _client => Supabase.instance.client;

  /// Obtiene todos los jugadores de la escuela del
  /// administrador autenticado.
  ///
  /// Las políticas RLS limitan automáticamente los
  /// resultados a su escuela.
  static Future<List<Map<String, dynamic>>> getPlayers() async {
    final List<dynamic> response = await _client
        .from('players')
        .select('''
          id,
          school_id,
          player_code,
          photo_url,
          first_name,
          last_name,
          ci,
          birth_date,
          gender,
          address,
          school_name,
          registration_date,
          status,
          created_at,
          updated_at,
          player_sport_profiles (
            primary_position,
            secondary_position,
            dominant_foot,
            height_cm,
            weight_kg,
            shirt_size,
            shorts_size,
            socks_size
          ),
          player_group_assignments (
            id,
            start_date,
            end_date,
            is_current,
            training_groups (
              id,
              name,
              start_time,
              end_time,
              categories (
                id,
                name
              )
            )
          )
          ''')
        .order('last_name', ascending: true)
        .order('first_name', ascending: true);

    return response
        .map((dynamic item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  /// Obtiene únicamente los jugadores activos.
  static Future<List<Map<String, dynamic>>> getActivePlayers() async {
    final List<dynamic> response = await _client
        .from('players')
        .select('''
          id,
          school_id,
          player_code,
          photo_url,
          first_name,
          last_name,
          birth_date,
          registration_date,
          status
          ''')
        .eq('status', 'active')
        .order('last_name', ascending: true)
        .order('first_name', ascending: true);

    return response
        .map((dynamic item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  /// Obtiene todas las categorías activas.
  static Future<List<Map<String, dynamic>>> getCategories() async {
    final List<dynamic> response = await _client
        .from('categories')
        .select('''
          id,
          name,
          minimum_birth_year,
          maximum_birth_year,
          description,
          status
          ''')
        .eq('status', 'active')
        .order('name', ascending: true);

    return response
        .map((dynamic item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  /// Obtiene todos los grupos activos y su categoría.
  static Future<List<Map<String, dynamic>>> getTrainingGroups() async {
    final List<dynamic> response = await _client
        .from('training_groups')
        .select('''
          id,
          name,
          start_time,
          end_time,
          status,
          category_id,
          categories (
            id,
            name
          ),
          locations (
            id,
            name
          )
          ''')
        .eq('status', 'active')
        .order('name', ascending: true);

    return response
        .map((dynamic item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  /// Obtiene la ficha completa de un jugador por su identificador.
  static Future<Map<String, dynamic>> getPlayerById(String playerId) async {
    final Map<String, dynamic> response = await _client
        .from('players')
        .select('''
        id,
        school_id,
        player_code,
        photo_url,
        first_name,
        last_name,
        ci,
        birth_date,
        gender,
        address,
        school_name,
        registration_date,
        status,
        created_at,
        updated_at,

        player_sport_profiles (
          id,
          primary_position,
          secondary_position,
          dominant_foot,
          height_cm,
          weight_kg,
          shirt_size,
          shorts_size,
          socks_size,
          sport_notes
        ),

        player_medical_profiles (
          id,
          blood_type,
          allergies,
          medications,
          asthma,
          previous_injuries,
          surgeries,
          medical_conditions,
          emergency_notes,
          medical_insurance
        ),

        player_guardians (
          id,
          relationship,
          is_primary,
          can_pick_up,
          receives_notifications,
          has_financial_responsibility,
          guardians (
            id,
            ci,
            first_name,
            last_name,
            phone,
            whatsapp,
            email,
            address,
            status
          )
        ),

        player_group_assignments (
          id,
          start_date,
          end_date,
          is_current,
          training_groups (
            id,
            name,
            start_time,
            end_time,
            categories (
              id,
              name
            ),
            locations (
              id,
              name
            )
          )
        )
      ''')
        .eq('id', playerId)
        .single();

    return response;
  }

  /// Registra en una sola operación:
  ///
  /// - jugador
  /// - perfil deportivo
  /// - perfil médico
  /// - tutor
  /// - relación entre jugador y tutor
  /// - grupo de entrenamiento, cuando corresponda
  ///
  /// Supabase ejecuta la función SQL `register_player`.
  static Future<String> registerPlayer({
    required Map<String, dynamic> player,
    required Map<String, dynamic> sport,
    required Map<String, dynamic> medical,
    required Map<String, dynamic> guardian,
    String? trainingGroupId,
  }) async {
    final dynamic response = await _client.rpc(
      'register_player',
      params: <String, dynamic>{
        'p_player': player,
        'p_sport': sport,
        'p_medical': medical,
        'p_guardian': guardian,
        'p_training_group_id': trainingGroupId,
      },
    );

    final String playerId = response?.toString().trim() ?? '';

    if (playerId.isEmpty) {
      throw const PostgrestException(
        message:
            'Supabase no devolvió el identificador '
            'del jugador registrado.',
      );
    }

    return playerId;
  }

  static Future<void> updatePlayerPhoto({
    required String playerId,
    required String photoUrl,
  }) async {
    final String normalizedPlayerId = playerId.trim();
    final String normalizedPhotoUrl = photoUrl.trim();

    if (normalizedPlayerId.isEmpty) {
      throw const FormatException(
        'El identificador del jugador es obligatorio.',
      );
    }

    if (normalizedPhotoUrl.isEmpty) {
      throw const FormatException('La URL de la fotografía es obligatoria.');
    }

    await _client
        .from('players')
        .update(<String, dynamic>{'photo_url': normalizedPhotoUrl})
        .eq('id', normalizedPlayerId);
  }

  static Future<void> updatePlayer({
    required String playerId,
    required Map<String, dynamic> player,
    required Map<String, dynamic> sport,
    required Map<String, dynamic> medical,
    required Map<String, dynamic> guardian,
    String? trainingGroupId,
  }) async {
    final String normalizedPlayerId = playerId.trim();

    if (normalizedPlayerId.isEmpty) {
      throw const FormatException(
        'El identificador del jugador es obligatorio.',
      );
    }

    // =========================================================
    // 1. DATOS PRINCIPALES DEL JUGADOR
    // =========================================================

    await _client
        .from('players')
        .update(Map<String, dynamic>.from(player))
        .eq('id', normalizedPlayerId);

    // =========================================================
    // 2. PERFIL DEPORTIVO
    // =========================================================

    await _client
        .from('player_sport_profiles')
        .update(Map<String, dynamic>.from(sport))
        .eq('player_id', normalizedPlayerId);

    // =========================================================
    // 3. PERFIL MÉDICO
    // =========================================================

    await _client
        .from('player_medical_profiles')
        .update(Map<String, dynamic>.from(medical))
        .eq('player_id', normalizedPlayerId);

    // =========================================================
    // 4. TUTOR ACTUAL DEL JUGADOR
    // =========================================================

    final Map<String, dynamic>? relation = await _client
        .from('player_guardians')
        .select('''
        id,
        guardian_id,
        is_primary
      ''')
        .eq('player_id', normalizedPlayerId)
        .order('is_primary', ascending: false)
        .limit(1)
        .maybeSingle();

    if (relation != null) {
      final String guardianId =
          relation['guardian_id']?.toString().trim() ?? '';

      final String relationId = relation['id']?.toString().trim() ?? '';

      if (guardianId.isNotEmpty) {
        await _client
            .from('guardians')
            .update(<String, dynamic>{
              'first_name': guardian['first_name'],
              'last_name': guardian['last_name'],
              'ci': guardian['ci'],
              'phone': guardian['phone'],
              'whatsapp': guardian['whatsapp'],
              'email': guardian['email'],
              'address': guardian['address'],
            })
            .eq('id', guardianId);
      }

      if (relationId.isNotEmpty) {
        await _client
            .from('player_guardians')
            .update(<String, dynamic>{
              'relationship': guardian['relationship'],
              'is_primary': guardian['is_primary'],
              'can_pick_up': guardian['can_pick_up'],
            })
            .eq('id', relationId);
      }
    }
    // =========================================================
    // 5. GRUPO DE ENTRENAMIENTO ACTUAL
    // =========================================================

    final String normalizedTrainingGroupId = trainingGroupId?.trim() ?? '';

    if (normalizedTrainingGroupId.isNotEmpty) {
      final Map<String, dynamic>? currentAssignment = await _client
          .from('player_group_assignments')
          .select('''
        id,
        training_group_id,
        is_current
      ''')
          .eq('player_id', normalizedPlayerId)
          .eq('is_current', true)
          .limit(1)
          .maybeSingle();

      final String today = DateTime.now().toIso8601String().split('T').first;

      if (currentAssignment == null) {
        await _client.from('player_group_assignments').insert(<String, dynamic>{
          'player_id': normalizedPlayerId,
          'training_group_id': normalizedTrainingGroupId,
          'start_date': today,
          'end_date': null,
          'is_current': true,
        });
      } else {
        final String currentTrainingGroupId =
            currentAssignment['training_group_id']?.toString().trim() ?? '';

        if (currentTrainingGroupId != normalizedTrainingGroupId) {
          final String assignmentId =
              currentAssignment['id']?.toString().trim() ?? '';

          if (assignmentId.isNotEmpty) {
            await _client
                .from('player_group_assignments')
                .update(<String, dynamic>{
                  'is_current': false,
                  'end_date': today,
                })
                .eq('id', assignmentId);
          }

          await _client
              .from('player_group_assignments')
              .insert(<String, dynamic>{
                'player_id': normalizedPlayerId,
                'training_group_id': normalizedTrainingGroupId,
                'start_date': today,
                'end_date': null,
                'is_current': true,
              });
        }
      }
    }
  }

  /// Cuenta los jugadores activos.
  static Future<int> countActivePlayers() async {
    final PostgrestResponse<List<Map<String, dynamic>>> response = await _client
        .from('players')
        .select('id')
        .eq('status', 'active')
        .count(CountOption.exact);

    return response.count;
  }

  /// Obtiene las estadísticas de asistencia de un jugador.
  static Future<Map<String, dynamic>> getPlayerAttendanceStats(
    String playerId,
  ) async {
    final dynamic response = await _client.rpc(
      'get_player_attendance_stats',
      params: <String, dynamic>{'p_player_id': playerId},
    );

    if (response is List && response.isNotEmpty) {
      final dynamic first = response.first;

      if (first is Map) {
        return Map<String, dynamic>.from(first);
      }
    }

    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }

    return <String, dynamic>{
      'total_sessions': 0,
      'present_count': 0,
      'late_count': 0,
      'absent_count': 0,
      'injured_count': 0,
      'attendance_percentage': 0,
      'last_attendance': null,
    };
  }
}
