import '../data/attendance_service.dart';
import '../models/attendance_model.dart';

class AttendanceRepository {
  const AttendanceRepository();

  /// Obtiene los grupos activos disponibles para pasar asistencia.
  Future<List<AttendanceTrainingGroup>> getTrainingGroups() async {
    final List<Map<String, dynamic>> response =
        await AttendanceService.getTrainingGroups();

    return response.map(AttendanceTrainingGroup.fromMap).toList();
  }

  /// Obtiene los jugadores actualmente asignados a un grupo.
  ///
  /// Todos comienzan como presentes para que el entrenador
  /// solamente cambie a quienes faltaron, llegaron tarde
  /// o están lesionados.
  Future<List<AttendanceModel>> getPlayersByTrainingGroup(
    String trainingGroupId,
  ) async {
    final String normalizedGroupId = trainingGroupId.trim();

    if (normalizedGroupId.isEmpty) {
      throw const FormatException(
        'Debes seleccionar un grupo de entrenamiento.',
      );
    }

    final List<Map<String, dynamic>> response =
        await AttendanceService.getPlayersByTrainingGroup(normalizedGroupId);

    final List<AttendanceModel> players = <AttendanceModel>[];

    for (final Map<String, dynamic> assignment in response) {
      final Map<String, dynamic>? player = _extractMap(assignment['players']);

      if (player == null) {
        continue;
      }

      final String status =
          _nullableString(player['status'])?.toLowerCase() ?? '';

      if (status != 'active') {
        continue;
      }

      final String firstName = _requiredString(
        player['first_name'],
        'nombres del jugador',
      );

      final String lastName = _requiredString(
        player['last_name'],
        'apellidos del jugador',
      );

      players.add(
        AttendanceModel(
          playerId: _requiredString(player['id'], 'id del jugador'),
          playerName: '$firstName $lastName'.trim(),
          playerCode: _requiredString(
            player['player_code'],
            'código del jugador',
          ),
          status: AttendanceStatus.present,
        ),
      );
    }

    players.sort((AttendanceModel first, AttendanceModel second) {
      return first.playerName.toLowerCase().compareTo(
        second.playerName.toLowerCase(),
      );
    });

    return players;
  }

  /// Guarda una sesión completa de asistencia.
  ///
  /// La función SQL crea o actualiza la sesión y registra
  /// todos los estados en una sola operación atómica.
  Future<String> saveTrainingAttendance({
    required AttendanceTrainingGroup trainingGroup,
    required DateTime sessionDate,
    required List<AttendanceModel> attendance,
    String? sessionNotes,
  }) async {
    if (trainingGroup.id.trim().isEmpty) {
      throw const FormatException(
        'Debes seleccionar un grupo de entrenamiento.',
      );
    }

    if (attendance.isEmpty) {
      throw const FormatException('No hay jugadores para guardar.');
    }

    final List<Map<String, dynamic>> attendanceData = attendance.map((
      AttendanceModel item,
    ) {
      return <String, dynamic>{
        'player_id': item.playerId,
        'status': _statusToDatabase(item.status),
        'notes': _normalizeNullableText(item.observation),
      };
    }).toList();

    return AttendanceService.saveTrainingAttendance(
      trainingGroupId: trainingGroup.id,
      sessionDate: sessionDate,
      attendance: attendanceData,
      sessionNotes: _normalizeNullableText(sessionNotes),
    );
  }

  /// Obtiene los estados de asistencia ya guardados
  /// para un grupo y una fecha.
  Future<Map<String, SavedAttendanceRecord>> getSavedAttendance({
    required String trainingGroupId,
    required DateTime sessionDate,
  }) async {
    final String normalizedGroupId = trainingGroupId.trim();

    if (normalizedGroupId.isEmpty) {
      throw const FormatException(
        'Debes seleccionar un grupo de entrenamiento.',
      );
    }

    final List<Map<String, dynamic>> response =
        await AttendanceService.getSavedAttendance(
          trainingGroupId: normalizedGroupId,
          sessionDate: sessionDate,
        );

    final Map<String, SavedAttendanceRecord> saved =
        <String, SavedAttendanceRecord>{};

    for (final Map<String, dynamic> item in response) {
      final String playerId = _requiredString(
        item['player_id'],
        'id del jugador',
      );

      final String rawStatus = _requiredString(
        item['attendance_status'],
        'estado de asistencia',
      );

      saved[playerId] = SavedAttendanceRecord(
        playerId: playerId,
        status: _statusFromDatabase(rawStatus),
        observation: _nullableString(item['notes']),
      );
    }

    return saved;
  }

  /// Obtiene las sesiones más recientes.
  Future<List<AttendanceSessionSummary>> getRecentTrainingSessions({
    int limit = 20,
  }) async {
    final int safeLimit = limit <= 0 ? 20 : limit;

    final List<Map<String, dynamic>> response =
        await AttendanceService.getRecentTrainingSessions(limit: safeLimit);

    return response.map(AttendanceSessionSummary.fromMap).toList();
  }
}

class SavedAttendanceRecord {
  const SavedAttendanceRecord({
    required this.playerId,
    required this.status,
    this.observation,
  });

  final String playerId;
  final AttendanceStatus status;
  final String? observation;
}

class AttendanceTrainingGroup {
  const AttendanceTrainingGroup({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.status,
    this.categoryId,
    this.categoryName,
    this.locationId,
    this.locationName,
    this.locationAddress,
    this.startTime,
    this.endTime,
  });

  final String id;
  final String schoolId;
  final String name;
  final String status;

  final String? categoryId;
  final String? categoryName;

  final String? locationId;
  final String? locationName;
  final String? locationAddress;

  final String? startTime;
  final String? endTime;

  String get displayCategory {
    final String value = categoryName?.trim() ?? '';

    return value.isEmpty ? 'Sin categoría' : value;
  }

  String get displayLocation {
    final String value = locationName?.trim() ?? '';

    return value.isEmpty ? 'Sin sede asignada' : value;
  }

  String get displaySchedule {
    final String start = startTime?.trim() ?? '';

    final String end = endTime?.trim() ?? '';

    if (start.isEmpty && end.isEmpty) {
      return 'Horario no definido';
    }

    if (start.isEmpty) {
      return 'Hasta $end';
    }

    if (end.isEmpty) {
      return 'Desde $start';
    }

    return '$start - $end';
  }

  factory AttendanceTrainingGroup.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic>? category = _extractMap(map['categories']);

    final Map<String, dynamic>? location = _extractMap(map['locations']);

    return AttendanceTrainingGroup(
      id: _requiredString(map['id'], 'id del grupo'),
      schoolId: _requiredString(map['school_id'], 'id de la escuela'),
      categoryId: _nullableString(map['category_id']),
      locationId: _nullableString(map['location_id']),
      name: _requiredString(map['name'], 'nombre del grupo'),
      startTime: _formatTime(map['start_time']),
      endTime: _formatTime(map['end_time']),
      status: _requiredString(map['status'], 'estado del grupo'),
      categoryName: _nullableString(category?['name']),
      locationName: _nullableString(location?['name']),
      locationAddress: _nullableString(location?['address']),
    );
  }
}

class AttendanceSessionSummary {
  const AttendanceSessionSummary({
    required this.id,
    required this.schoolId,
    required this.trainingGroupId,
    required this.sessionDate,
    required this.title,
    required this.status,
    this.locationId,
    this.trainingGroupName,
    this.locationName,
    this.startTime,
    this.endTime,
    this.notes,
  });

  final String id;
  final String schoolId;
  final String trainingGroupId;
  final String? locationId;

  final DateTime sessionDate;
  final String? startTime;
  final String? endTime;

  final String title;
  final String? notes;
  final String status;

  final String? trainingGroupName;
  final String? locationName;

  String get displayTrainingGroup {
    final String value = trainingGroupName?.trim() ?? '';

    return value.isEmpty ? 'Grupo no disponible' : value;
  }

  String get displayLocation {
    final String value = locationName?.trim() ?? '';

    return value.isEmpty ? 'Sin sede' : value;
  }

  factory AttendanceSessionSummary.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic>? trainingGroup = _extractMap(
      map['training_groups'],
    );

    final Map<String, dynamic>? location = _extractMap(map['locations']);

    return AttendanceSessionSummary(
      id: _requiredString(map['id'], 'id de la sesión'),
      schoolId: _requiredString(map['school_id'], 'id de la escuela'),
      trainingGroupId: _requiredString(
        map['training_group_id'],
        'id del grupo',
      ),
      locationId: _nullableString(map['location_id']),
      sessionDate: _requiredDate(map['session_date'], 'fecha de la sesión'),
      startTime: _formatTime(map['start_time']),
      endTime: _formatTime(map['end_time']),
      title: _requiredString(map['title'], 'título de la sesión'),
      notes: _nullableString(map['notes']),
      status: _requiredString(map['status'], 'estado de la sesión'),
      trainingGroupName: _nullableString(trainingGroup?['name']),
      locationName: _nullableString(location?['name']),
    );
  }
}

Map<String, dynamic>? _extractMap(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  if (value is List && value.isNotEmpty) {
    final dynamic first = value.first;

    if (first is Map) {
      return Map<String, dynamic>.from(first);
    }
  }

  return null;
}

String _requiredString(dynamic value, String fieldName) {
  final String text = value?.toString().trim() ?? '';

  if (text.isEmpty) {
    throw FormatException(
      'El campo obligatorio "$fieldName" '
      'está vacío.',
    );
  }

  return text;
}

String? _nullableString(dynamic value) {
  final String text = value?.toString().trim() ?? '';

  return text.isEmpty ? null : text;
}

String? _normalizeNullableText(String? value) {
  final String text = value?.trim() ?? '';

  return text.isEmpty ? null : text;
}

DateTime _requiredDate(dynamic value, String fieldName) {
  final DateTime? date = DateTime.tryParse(value?.toString() ?? '');

  if (date == null) {
    throw FormatException(
      'La fecha obligatoria "$fieldName" '
      'no es válida.',
    );
  }

  return date;
}

String? _formatTime(dynamic value) {
  final String? time = _nullableString(value);

  if (time == null) {
    return null;
  }

  final List<String> parts = time.split(':');

  if (parts.length < 2) {
    return time;
  }

  return '${parts[0]}:${parts[1]}';
}

AttendanceStatus _statusFromDatabase(String value) {
  switch (value.trim().toLowerCase()) {
    case 'present':
      return AttendanceStatus.present;
    case 'late':
      return AttendanceStatus.late;
    case 'absent':
      return AttendanceStatus.absent;
    case 'injured':
      return AttendanceStatus.injured;
    default:
      throw FormatException('El estado de asistencia "$value" no es válido.');
  }
}

String _statusToDatabase(AttendanceStatus status) {
  switch (status) {
    case AttendanceStatus.present:
      return 'present';

    case AttendanceStatus.late:
      return 'late';

    case AttendanceStatus.absent:
      return 'absent';

    case AttendanceStatus.injured:
      return 'injured';
  }
}
