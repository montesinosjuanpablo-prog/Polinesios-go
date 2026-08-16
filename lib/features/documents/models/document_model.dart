class DocumentModel {
  final String id;
  final String schoolId;
  final String? playerId;

  final String title;
  final String description;

  final String documentType;
  final String scope;

  final DateTime documentDate;
  final String status;

  final String? fileName;
  final String? filePath;

  final String createdBy;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Datos visibles obtenidos mediante relaciones de Supabase.
  final String playerName;
  final String creatorName;

  const DocumentModel({
    required this.id,
    required this.schoolId,
    required this.playerId,
    required this.title,
    required this.description,
    required this.documentType,
    required this.scope,
    required this.documentDate,
    required this.status,
    required this.fileName,
    required this.filePath,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.playerName,
    required this.creatorName,
  });

  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    final dynamic playerData = map['players'];
    final dynamic creatorData = map['profiles'];

    String resolvedPlayerName = '';
    String resolvedCreatorName = '';

    if (playerData is Map) {
      final String firstName =
          playerData['first_name']?.toString().trim() ?? '';

      final String lastName = playerData['last_name']?.toString().trim() ?? '';

      resolvedPlayerName = [
        firstName,
        lastName,
      ].where((String value) => value.isNotEmpty).join(' ');
    }

    if (creatorData is Map) {
      final String firstName =
          creatorData['first_name']?.toString().trim() ?? '';

      final String lastName = creatorData['last_name']?.toString().trim() ?? '';

      resolvedCreatorName = [
        firstName,
        lastName,
      ].where((String value) => value.isNotEmpty).join(' ');
    }

    return DocumentModel(
      id: map['id']?.toString() ?? '',
      schoolId: map['school_id']?.toString() ?? '',
      playerId: map['player_id']?.toString(),
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      documentType: map['document_type']?.toString() ?? 'other',
      scope: map['scope']?.toString() ?? 'school',
      documentDate:
          DateTime.tryParse(map['document_date']?.toString() ?? '') ??
          DateTime.now(),
      status: map['status']?.toString() ?? 'active',
      fileName: map['file_name']?.toString(),
      filePath: map['file_path']?.toString(),
      createdBy: map['created_by']?.toString() ?? '',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? ''),
      playerName: resolvedPlayerName,
      creatorName: resolvedCreatorName,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'player_id': playerId,
      'title': title.trim(),
      'description': description.trim(),
      'document_type': documentType,
      'scope': scope,
      'document_date': documentDate.toIso8601String().split('T').first,
      'status': status,
      'file_name': fileName,
      'file_path': filePath,
    };
  }

  DocumentModel copyWith({
    String? id,
    String? schoolId,
    String? playerId,
    bool clearPlayerId = false,
    String? title,
    String? description,
    String? documentType,
    String? scope,
    DateTime? documentDate,
    String? status,
    String? fileName,
    String? filePath,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? playerName,
    String? creatorName,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      playerId: clearPlayerId ? null : playerId ?? this.playerId,
      title: title ?? this.title,
      description: description ?? this.description,
      documentType: documentType ?? this.documentType,
      scope: scope ?? this.scope,
      documentDate: documentDate ?? this.documentDate,
      status: status ?? this.status,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      playerName: playerName ?? this.playerName,
      creatorName: creatorName ?? this.creatorName,
    );
  }

  bool get isPlayerDocument => scope == 'player';

  bool get isSchoolDocument => scope == 'school';

  bool get isActive => status == 'active';

  bool get isArchived => status == 'archived';

  String get typeLabel {
    switch (documentType) {
      case 'registration':
        return 'Inscripción';

      case 'identity':
        return 'Identidad';

      case 'medical':
        return 'Médico';

      case 'authorization':
        return 'Autorización';

      case 'contract':
        return 'Contrato';

      case 'payment':
        return 'Pago';

      case 'institutional':
        return 'Institucional';

      default:
        return 'Otro';
    }
  }

  String get scopeLabel {
    switch (scope) {
      case 'player':
        return 'Jugador';

      default:
        return 'Escuela';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'archived':
        return 'Archivado';

      default:
        return 'Activo';
    }
  }
}
