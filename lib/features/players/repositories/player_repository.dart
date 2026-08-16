import '../data/player_service.dart';
import '../models/player_detail_model.dart';
import '../models/player_model.dart';
import '../models/player_attendance_stats.dart';

class PlayerRepository {
  const PlayerRepository();

  /// Obtiene todos los jugadores y transforma las respuestas
  /// de Supabase en objetos PlayerModel.
  Future<List<PlayerModel>> getPlayers() async {
    final List<Map<String, dynamic>> response =
        await PlayerService.getPlayers();

    return response
        .map((Map<String, dynamic> playerMap) => PlayerModel.fromMap(playerMap))
        .toList();
  }

  /// Obtiene únicamente los jugadores activos.
  Future<List<PlayerModel>> getActivePlayers() async {
    final List<Map<String, dynamic>> response =
        await PlayerService.getActivePlayers();

    return response
        .map((Map<String, dynamic> playerMap) => PlayerModel.fromMap(playerMap))
        .toList();
  }

  /// Obtiene la ficha completa de un jugador.
  Future<PlayerModel> getPlayerById(String playerId) async {
    final String normalizedPlayerId = playerId.trim();

    if (normalizedPlayerId.isEmpty) {
      throw const FormatException(
        'El identificador del jugador es obligatorio.',
      );
    }

    final Map<String, dynamic> response = await PlayerService.getPlayerById(
      normalizedPlayerId,
    );

    return PlayerModel.fromMap(response);
  }

  /// Obtiene la ficha integral de un jugador:
  ///
  /// - información personal;
  /// - perfil deportivo;
  /// - perfil médico;
  /// - tutores relacionados;
  /// - categoría, grupo y sede de entrenamiento.
  Future<PlayerDetailModel> getPlayerDetailById(String playerId) async {
    final String normalizedPlayerId = playerId.trim();

    if (normalizedPlayerId.isEmpty) {
      throw const FormatException(
        'El identificador del jugador es obligatorio.',
      );
    }

    final Map<String, dynamic> response = await PlayerService.getPlayerById(
      normalizedPlayerId,
    );

    return PlayerDetailModel.fromMap(response);
  }

  /// Obtiene las estadísticas reales de asistencia
  /// correspondientes a un jugador.
  Future<PlayerAttendanceStats> getPlayerAttendanceStats(
    String playerId,
  ) async {
    final String normalizedPlayerId = playerId.trim();

    if (normalizedPlayerId.isEmpty) {
      throw const FormatException(
        'El identificador del jugador es obligatorio.',
      );
    }

    final Map<String, dynamic> response =
        await PlayerService.getPlayerAttendanceStats(normalizedPlayerId);

    return PlayerAttendanceStats.fromMap(response);
  }

  /// Obtiene las categorías activas disponibles.
  Future<List<PlayerCategoryData>> getCategories() async {
    final List<Map<String, dynamic>> response =
        await PlayerService.getCategories();

    return response.map(PlayerCategoryData.fromMap).toList();
  }

  /// Obtiene los grupos de entrenamiento activos.
  Future<List<PlayerTrainingGroupData>> getTrainingGroups() async {
    final List<Map<String, dynamic>> response =
        await PlayerService.getTrainingGroups();

    return response.map(PlayerTrainingGroupData.fromMap).toList();
  }

  /// Registra de manera atómica:
  ///
  /// - jugador;
  /// - perfil deportivo;
  /// - perfil médico;
  /// - tutor;
  /// - relación jugador–tutor;
  /// - grupo de entrenamiento, cuando corresponda.
  Future<String> registerPlayer({
    required Map<String, dynamic> player,
    required Map<String, dynamic> sport,
    required Map<String, dynamic> medical,
    required Map<String, dynamic> guardian,
    required String trainingGroupId,
  }) async {
    _validatePlayerData(player);
    _validateGuardianData(guardian);

    final String normalizedTrainingGroupId = trainingGroupId.trim();

    if (normalizedTrainingGroupId.isEmpty) {
      throw const FormatException(
        'Debes seleccionar un grupo de entrenamiento.',
      );
    }

    return PlayerService.registerPlayer(
      player: Map<String, dynamic>.from(player),
      sport: Map<String, dynamic>.from(sport),
      medical: Map<String, dynamic>.from(medical),
      guardian: Map<String, dynamic>.from(guardian),
      trainingGroupId: normalizedTrainingGroupId,
    );
  }

  /// Cuenta los jugadores activos.
  Future<int> countActivePlayers() {
    return PlayerService.countActivePlayers();
  }

  void _validatePlayerData(Map<String, dynamic> player) {
    _requireText(player['player_code'], 'el código del jugador');

    _requireText(player['first_name'], 'los nombres del jugador');

    _requireText(player['last_name'], 'los apellidos del jugador');

    _requireText(player['birth_date'], 'la fecha de nacimiento');
  }

  void _validateGuardianData(Map<String, dynamic> guardian) {
    _requireText(guardian['first_name'], 'los nombres del tutor');

    _requireText(guardian['last_name'], 'los apellidos del tutor');

    _requireText(guardian['phone'], 'el teléfono del tutor');

    _requireText(guardian['relationship'], 'el parentesco del tutor');
  }

  void _requireText(dynamic value, String fieldName) {
    final String text = value?.toString().trim() ?? '';

    if (text.isEmpty) {
      throw FormatException('Debes ingresar $fieldName.');
    }
  }
}

class PlayerCategoryData {
  const PlayerCategoryData({
    required this.id,
    required this.name,
    required this.status,
    this.minimumBirthYear,
    this.maximumBirthYear,
    this.description,
  });

  final String id;
  final String name;

  final int? minimumBirthYear;
  final int? maximumBirthYear;

  final String? description;

  final String status;

  factory PlayerCategoryData.fromMap(Map<String, dynamic> map) {
    return PlayerCategoryData(
      id: _requiredString(map['id'], 'id de categoría'),
      name: _requiredString(map['name'], 'nombre de categoría'),
      minimumBirthYear: _nullableInt(map['minimum_birth_year']),
      maximumBirthYear: _nullableInt(map['maximum_birth_year']),
      description: _nullableString(map['description']),
      status: _requiredString(map['status'], 'estado de categoría'),
    );
  }
}

class PlayerTrainingGroupData {
  const PlayerTrainingGroupData({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.status,
    this.categoryName,
    this.locationId,
    this.locationName,
    this.startTime,
    this.endTime,
  });

  final String id;
  final String name;

  final String categoryId;
  final String? categoryName;

  final String? locationId;
  final String? locationName;

  final String? startTime;
  final String? endTime;

  final String status;

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

  String get displayCategory {
    final String category = categoryName?.trim() ?? '';

    return category.isEmpty ? 'Sin categoría' : category;
  }

  String get displayLocation {
    final String location = locationName?.trim() ?? '';

    return location.isEmpty ? 'Sin sede asignada' : location;
  }

  factory PlayerTrainingGroupData.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic>? category = _extractMap(map['categories']);

    final Map<String, dynamic>? location = _extractMap(map['locations']);

    return PlayerTrainingGroupData(
      id: _requiredString(map['id'], 'id del grupo'),
      name: _requiredString(map['name'], 'nombre del grupo'),
      categoryId: _requiredString(map['category_id'], 'categoría del grupo'),
      categoryName: _nullableString(category?['name']),
      locationId: _nullableString(location?['id']),
      locationName: _nullableString(location?['name']),
      startTime: _formatTime(map['start_time']),
      endTime: _formatTime(map['end_time']),
      status: _requiredString(map['status'], 'estado del grupo'),
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
    throw FormatException('El campo "$fieldName" está vacío.');
  }

  return text;
}

String? _nullableString(dynamic value) {
  final String text = value?.toString().trim() ?? '';

  return text.isEmpty ? null : text;
}

int? _nullableInt(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString());
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
