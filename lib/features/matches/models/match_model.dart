class MatchModel {
  final String id;
  final String schoolId;

  final String? trainingGroupId;
  final String? locationId;

  final String opponentName;

  final DateTime matchDate;
  final String startTime;

  final String homeAway;
  final String status;

  final int? goalsFor;
  final int? goalsAgainst;

  final String notes;

  final String createdBy;

  // Datos visibles obtenidos mediante relaciones
  // de Supabase.
  final String trainingGroupName;
  final String locationName;

  const MatchModel({
    required this.id,
    required this.schoolId,
    required this.trainingGroupId,
    required this.locationId,
    required this.opponentName,
    required this.matchDate,
    required this.startTime,
    required this.homeAway,
    required this.status,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.notes,
    required this.createdBy,
    required this.trainingGroupName,
    required this.locationName,
  });

  bool get isCompleted => status == 'completed';

  bool get isCancelled => status == 'cancelled';

  bool get hasResult => goalsFor != null && goalsAgainst != null;

  String get homeAwayLabel {
    switch (homeAway) {
      case 'home':
        return 'Local';

      case 'away':
        return 'Visitante';

      case 'neutral':
        return 'Cancha neutral';

      default:
        return 'Sin definir';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'scheduled':
        return 'Programado';

      case 'in_progress':
        return 'En juego';

      case 'completed':
        return 'Finalizado';

      case 'cancelled':
        return 'Cancelado';

      default:
        return 'Sin estado';
    }
  }

  factory MatchModel.fromMap(Map<String, dynamic> map) {
    final dynamic groupData = map['training_groups'];

    final dynamic locationData = map['locations'];

    String resolvedGroupName = '';
    String resolvedLocationName = '';

    if (groupData is Map) {
      resolvedGroupName = groupData['name']?.toString().trim() ?? '';
    }

    if (locationData is Map) {
      resolvedLocationName = locationData['name']?.toString().trim() ?? '';
    }

    return MatchModel(
      id: map['id']?.toString() ?? '',
      schoolId: map['school_id']?.toString() ?? '',
      trainingGroupId: map['training_group_id']?.toString(),
      locationId: map['location_id']?.toString(),
      opponentName: map['opponent_name']?.toString() ?? '',
      matchDate: DateTime.parse(map['match_date'].toString()),
      startTime: map['start_time']?.toString() ?? '',
      homeAway: map['home_away']?.toString() ?? 'home',
      status: map['status']?.toString() ?? 'scheduled',
      goalsFor: _toNullableInt(map['goals_for']),
      goalsAgainst: _toNullableInt(map['goals_against']),
      notes: map['notes']?.toString() ?? '',
      createdBy: map['created_by']?.toString() ?? '',
      trainingGroupName: resolvedGroupName,
      locationName: resolvedLocationName,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'school_id': schoolId,
      'training_group_id': trainingGroupId,
      'location_id': locationId,
      'opponent_name': opponentName.trim(),
      'match_date': _dateForDatabase(matchDate),
      'start_time': startTime.trim().isEmpty ? null : startTime,
      'home_away': homeAway,
      'status': status,
      'goals_for': goalsFor,
      'goals_against': goalsAgainst,
      'notes': notes.trim().isEmpty ? null : notes.trim(),
      'created_by': createdBy,
    };
  }

  MatchModel copyWith({
    String? id,
    String? schoolId,
    String? trainingGroupId,
    String? locationId,
    String? opponentName,
    DateTime? matchDate,
    String? startTime,
    String? homeAway,
    String? status,
    int? goalsFor,
    int? goalsAgainst,
    String? notes,
    String? createdBy,
    String? trainingGroupName,
    String? locationName,
    bool clearGoalsFor = false,
    bool clearGoalsAgainst = false,
  }) {
    return MatchModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      trainingGroupId: trainingGroupId ?? this.trainingGroupId,
      locationId: locationId ?? this.locationId,
      opponentName: opponentName ?? this.opponentName,
      matchDate: matchDate ?? this.matchDate,
      startTime: startTime ?? this.startTime,
      homeAway: homeAway ?? this.homeAway,
      status: status ?? this.status,
      goalsFor: clearGoalsFor ? null : goalsFor ?? this.goalsFor,
      goalsAgainst: clearGoalsAgainst
          ? null
          : goalsAgainst ?? this.goalsAgainst,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      trainingGroupName: trainingGroupName ?? this.trainingGroupName,
      locationName: locationName ?? this.locationName,
    );
  }

  static int? _toNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString());
  }

  static String _dateForDatabase(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');

    final String day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }
}
