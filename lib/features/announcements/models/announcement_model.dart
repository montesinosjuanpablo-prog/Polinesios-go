class AnnouncementModel {
  final String id;
  final String schoolId;
  final String? trainingGroupId;

  final String title;
  final String message;

  final String priority;
  final String audience;

  final DateTime publishDate;
  final DateTime? expiresOn;
  final String status;

  final String createdBy;

  final String trainingGroupName;

  const AnnouncementModel({
    required this.id,
    required this.schoolId,
    required this.trainingGroupId,
    required this.title,
    required this.message,
    required this.priority,
    required this.audience,
    required this.publishDate,
    required this.expiresOn,
    required this.status,
    required this.createdBy,
    required this.trainingGroupName,
  });

  bool get isPublished => status == 'published';

  bool get isDraft => status == 'draft';

  bool get isArchived => status == 'archived';

  String get priorityLabel {
    switch (priority) {
      case 'important':
        return 'Importante';

      case 'urgent':
        return 'Urgente';

      default:
        return 'Normal';
    }
  }

  String get audienceLabel {
    if (audience == 'group') {
      return trainingGroupName.trim().isEmpty
          ? 'Grupo específico'
          : trainingGroupName;
    }

    return 'Toda la Familia Polinesios';
  }

  String get statusLabel {
    switch (status) {
      case 'draft':
        return 'Borrador';

      case 'archived':
        return 'Archivado';

      default:
        return 'Publicado';
    }
  }

  factory AnnouncementModel.fromMap(Map<String, dynamic> map) {
    final dynamic groupData = map['training_groups'];

    String resolvedGroupName = '';

    if (groupData is Map) {
      resolvedGroupName = groupData['name']?.toString().trim() ?? '';
    }

    final String? expiresText = map['expires_on']?.toString();

    return AnnouncementModel(
      id: map['id']?.toString() ?? '',
      schoolId: map['school_id']?.toString() ?? '',
      trainingGroupId: map['training_group_id']?.toString(),
      title: map['title']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      priority: map['priority']?.toString() ?? 'normal',
      audience: map['audience']?.toString() ?? 'all',
      publishDate: DateTime.parse(map['publish_date'].toString()),
      expiresOn: expiresText == null || expiresText.trim().isEmpty
          ? null
          : DateTime.tryParse(expiresText),
      status: map['status']?.toString() ?? 'published',
      createdBy: map['created_by']?.toString() ?? '',
      trainingGroupName: resolvedGroupName,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'school_id': schoolId,
      'training_group_id': audience == 'group' ? trainingGroupId : null,
      'title': title.trim(),
      'message': message.trim(),
      'priority': priority,
      'audience': audience,
      'publish_date': _dateForDatabase(publishDate),
      'expires_on': expiresOn == null ? null : _dateForDatabase(expiresOn!),
      'status': status,
      'created_by': createdBy,
    };
  }

  AnnouncementModel copyWith({
    String? id,
    String? schoolId,
    String? trainingGroupId,
    String? title,
    String? message,
    String? priority,
    String? audience,
    DateTime? publishDate,
    DateTime? expiresOn,
    String? status,
    String? createdBy,
    String? trainingGroupName,
    bool clearTrainingGroup = false,
    bool clearExpiresOn = false,
  }) {
    return AnnouncementModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      trainingGroupId: clearTrainingGroup
          ? null
          : trainingGroupId ?? this.trainingGroupId,
      title: title ?? this.title,
      message: message ?? this.message,
      priority: priority ?? this.priority,
      audience: audience ?? this.audience,
      publishDate: publishDate ?? this.publishDate,
      expiresOn: clearExpiresOn ? null : expiresOn ?? this.expiresOn,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      trainingGroupName: trainingGroupName ?? this.trainingGroupName,
    );
  }

  static String _dateForDatabase(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }
}
