class TrainingSessionModel {
  const TrainingSessionModel({
    required this.id,
    this.trainingGroupId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.categoryName,
    required this.coachName,
    required this.objective,
    required this.materials,
    required this.notes,
    required this.status,
  });

  final String id;
  final String? trainingGroupId;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String location;
  final String categoryName;
  final String coachName;
  final String objective;
  final String materials;
  final String notes;
  final String status;

  bool get isCompleted {
    return status.trim().toLowerCase() == 'completed';
  }

  bool get isCancelled {
    return status.trim().toLowerCase() == 'cancelled';
  }

  bool get isScheduled {
    return status.trim().toLowerCase() == 'scheduled';
  }

  factory TrainingSessionModel.fromMap(Map<String, dynamic> map) {
    return TrainingSessionModel(
      id: map['id']?.toString() ?? '',
      trainingGroupId: map['training_group_id']?.toString(),
      date: DateTime.parse(
        map['training_date']?.toString() ?? DateTime.now().toIso8601String(),
      ),
      startTime: map['start_time']?.toString() ?? '',
      endTime: map['end_time']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
      categoryName: map['category_name']?.toString() ?? '',
      coachName: map['coach_name']?.toString() ?? '',
      objective: map['objective']?.toString() ?? '',
      materials: map['materials']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      status: map['status']?.toString() ?? 'scheduled',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (trainingGroupId != null) 'training_group_id': trainingGroupId,
      'training_date':
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}',
      'session_date':
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}',

      'start_time': startTime,
      'end_time': endTime,
      'location': location,
      'category_name': categoryName,
      'coach_name': coachName,
      'objective': objective,
      'materials': materials,
      'notes': notes,
      'status': status,
    };
  }

  TrainingSessionModel copyWith({
    String? trainingGroupId,
    String? id,
    DateTime? date,
    String? startTime,
    String? endTime,
    String? location,
    String? categoryName,
    String? coachName,
    String? objective,
    String? materials,
    String? notes,
    String? status,
  }) {
    return TrainingSessionModel(
      trainingGroupId: trainingGroupId ?? this.trainingGroupId,
      id: id ?? this.id,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      categoryName: categoryName ?? this.categoryName,
      coachName: coachName ?? this.coachName,
      objective: objective ?? this.objective,
      materials: materials ?? this.materials,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }
}
