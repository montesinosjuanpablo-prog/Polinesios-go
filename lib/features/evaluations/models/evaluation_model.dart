class EvaluationModel {
  final String id;
  final String schoolId;
  final String playerId;
  final String evaluatorId;

  final DateTime evaluationDate;

  final int technicalScore;
  final int tacticalScore;
  final int physicalScore;
  final int attitudeScore;

  final String strengths;
  final String areasToImprove;
  final String observations;

  final String status;

  final String playerFirstName;
  final String playerLastName;

  final String evaluatorFirstName;
  final String evaluatorLastName;

  const EvaluationModel({
    required this.id,
    required this.schoolId,
    required this.playerId,
    required this.evaluatorId,
    required this.evaluationDate,
    required this.technicalScore,
    required this.tacticalScore,
    required this.physicalScore,
    required this.attitudeScore,
    required this.strengths,
    required this.areasToImprove,
    required this.observations,
    required this.status,
    required this.playerFirstName,
    required this.playerLastName,
    required this.evaluatorFirstName,
    required this.evaluatorLastName,
  });

  bool get isDraft => status == 'draft';

  bool get isCompleted => status == 'completed';

  bool get isArchived => status == 'archived';

  double get averageScore {
    return (technicalScore + tacticalScore + physicalScore + attitudeScore) / 4;
  }

  String get playerName {
    return '$playerFirstName $playerLastName'.trim();
  }

  String get evaluatorName {
    return '$evaluatorFirstName $evaluatorLastName'.trim();
  }

  String get statusLabel {
    switch (status) {
      case 'draft':
        return 'Borrador';

      case 'archived':
        return 'Archivada';

      default:
        return 'Completada';
    }
  }

  factory EvaluationModel.fromMap(Map<String, dynamic> map) {
    final dynamic playerData = map['players'];
    final dynamic evaluatorData = map['profiles'];

    String playerFirstName = '';
    String playerLastName = '';

    String evaluatorFirstName = '';
    String evaluatorLastName = '';

    if (playerData is Map) {
      playerFirstName = playerData['first_name']?.toString().trim() ?? '';

      playerLastName = playerData['last_name']?.toString().trim() ?? '';
    }

    if (evaluatorData is Map) {
      evaluatorFirstName = evaluatorData['first_name']?.toString().trim() ?? '';

      evaluatorLastName = evaluatorData['last_name']?.toString().trim() ?? '';
    }

    return EvaluationModel(
      id: map['id']?.toString() ?? '',
      schoolId: map['school_id']?.toString() ?? '',
      playerId: map['player_id']?.toString() ?? '',
      evaluatorId: map['evaluator_id']?.toString() ?? '',
      evaluationDate: DateTime.parse(map['evaluation_date'].toString()),
      technicalScore:
          int.tryParse(map['technical_score']?.toString() ?? '') ?? 3,
      tacticalScore: int.tryParse(map['tactical_score']?.toString() ?? '') ?? 3,
      physicalScore: int.tryParse(map['physical_score']?.toString() ?? '') ?? 3,
      attitudeScore: int.tryParse(map['attitude_score']?.toString() ?? '') ?? 3,
      strengths: map['strengths']?.toString() ?? '',
      areasToImprove: map['areas_to_improve']?.toString() ?? '',
      observations: map['observations']?.toString() ?? '',
      status: map['status']?.toString() ?? 'completed',
      playerFirstName: playerFirstName,
      playerLastName: playerLastName,
      evaluatorFirstName: evaluatorFirstName,
      evaluatorLastName: evaluatorLastName,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'school_id': schoolId,
      'player_id': playerId,
      'evaluator_id': evaluatorId,
      'evaluation_date': _dateForDatabase(evaluationDate),
      'technical_score': technicalScore,
      'tactical_score': tacticalScore,
      'physical_score': physicalScore,
      'attitude_score': attitudeScore,
      'strengths': strengths.trim(),
      'areas_to_improve': areasToImprove.trim(),
      'observations': observations.trim(),
      'status': status,
    };
  }

  EvaluationModel copyWith({
    String? id,
    String? schoolId,
    String? playerId,
    String? evaluatorId,
    DateTime? evaluationDate,
    int? technicalScore,
    int? tacticalScore,
    int? physicalScore,
    int? attitudeScore,
    String? strengths,
    String? areasToImprove,
    String? observations,
    String? status,
    String? playerFirstName,
    String? playerLastName,
    String? evaluatorFirstName,
    String? evaluatorLastName,
  }) {
    return EvaluationModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      playerId: playerId ?? this.playerId,
      evaluatorId: evaluatorId ?? this.evaluatorId,
      evaluationDate: evaluationDate ?? this.evaluationDate,
      technicalScore: technicalScore ?? this.technicalScore,
      tacticalScore: tacticalScore ?? this.tacticalScore,
      physicalScore: physicalScore ?? this.physicalScore,
      attitudeScore: attitudeScore ?? this.attitudeScore,
      strengths: strengths ?? this.strengths,
      areasToImprove: areasToImprove ?? this.areasToImprove,
      observations: observations ?? this.observations,
      status: status ?? this.status,
      playerFirstName: playerFirstName ?? this.playerFirstName,
      playerLastName: playerLastName ?? this.playerLastName,
      evaluatorFirstName: evaluatorFirstName ?? this.evaluatorFirstName,
      evaluatorLastName: evaluatorLastName ?? this.evaluatorLastName,
    );
  }

  static String _dateForDatabase(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');

    final String day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }
}
