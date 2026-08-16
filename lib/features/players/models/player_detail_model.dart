import 'player_model.dart';

class PlayerDetailModel {
  const PlayerDetailModel({
    required this.player,
    required this.medical,
    required this.guardians,
    this.sportNotes,
    this.trainingLocationName,
  });

  final PlayerModel player;
  final PlayerMedicalData medical;
  final List<PlayerGuardianData> guardians;
  final String? sportNotes;
  final String? trainingLocationName;

  PlayerGuardianData? get primaryGuardian {
    for (final PlayerGuardianData guardian in guardians) {
      if (guardian.isPrimary) {
        return guardian;
      }
    }

    return guardians.isEmpty ? null : guardians.first;
  }

  factory PlayerDetailModel.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic>? sportProfile = _extractSingleMap(
      map['player_sport_profiles'],
    );

    final Map<String, dynamic>? medicalProfile = _extractSingleMap(
      map['player_medical_profiles'],
    );

    final List<dynamic> guardianRelations = _extractList(
      map['player_guardians'],
    );

    final List<PlayerGuardianData> guardians = guardianRelations
        .whereType<Map>()
        .map(
          (Map relation) => PlayerGuardianData.fromRelationMap(
            Map<String, dynamic>.from(relation),
          ),
        )
        .toList();

    final List<dynamic> groupAssignments = _extractList(
      map['player_group_assignments'],
    );

    Map<String, dynamic>? currentAssignment;

    for (final dynamic assignment in groupAssignments) {
      if (assignment is! Map) {
        continue;
      }

      final Map<String, dynamic> assignmentMap = Map<String, dynamic>.from(
        assignment,
      );

      if (assignmentMap['is_current'] == true) {
        currentAssignment = assignmentMap;
        break;
      }
    }

    currentAssignment ??=
        groupAssignments.isNotEmpty && groupAssignments.first is Map
        ? Map<String, dynamic>.from(groupAssignments.first as Map)
        : null;

    final Map<String, dynamic>? trainingGroup = _extractSingleMap(
      currentAssignment?['training_groups'],
    );

    final Map<String, dynamic>? location = _extractSingleMap(
      trainingGroup?['locations'],
    );

    return PlayerDetailModel(
      player: PlayerModel.fromMap(map),
      medical: PlayerMedicalData.fromMap(
        medicalProfile ?? const <String, dynamic>{},
      ),
      guardians: guardians,
      sportNotes: _nullableString(sportProfile?['sport_notes']),
      trainingLocationName: _nullableString(location?['name']),
    );
  }
}

class PlayerMedicalData {
  const PlayerMedicalData({
    this.id,
    this.bloodType,
    this.allergies,
    this.medications,
    this.hasAsthma = false,
    this.previousInjuries,
    this.surgeries,
    this.medicalConditions,
    this.emergencyNotes,
    this.medicalInsurance,
  });

  final String? id;
  final String? bloodType;
  final String? allergies;
  final String? medications;
  final bool hasAsthma;
  final String? previousInjuries;
  final String? surgeries;
  final String? medicalConditions;
  final String? emergencyNotes;
  final String? medicalInsurance;

  bool get hasRelevantInformation {
    return bloodType != null ||
        allergies != null ||
        medications != null ||
        hasAsthma ||
        previousInjuries != null ||
        surgeries != null ||
        medicalConditions != null ||
        emergencyNotes != null ||
        medicalInsurance != null;
  }

  factory PlayerMedicalData.fromMap(Map<String, dynamic> map) {
    return PlayerMedicalData(
      id: _nullableString(map['id']),
      bloodType: _nullableString(map['blood_type']),
      allergies: _nullableString(map['allergies']),
      medications: _nullableString(map['medications']),
      hasAsthma: _toBool(map['asthma']),
      previousInjuries: _nullableString(map['previous_injuries']),
      surgeries: _nullableString(map['surgeries']),
      medicalConditions: _nullableString(map['medical_conditions']),
      emergencyNotes: _nullableString(map['emergency_notes']),
      medicalInsurance: _nullableString(map['medical_insurance']),
    );
  }
}

class PlayerGuardianData {
  const PlayerGuardianData({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.relationship,
    required this.isPrimary,
    required this.canPickUp,
    required this.receivesNotifications,
    required this.hasFinancialResponsibility,
    this.ci,
    this.phone,
    this.whatsapp,
    this.email,
    this.address,
    this.status,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String relationship;
  final bool isPrimary;
  final bool canPickUp;
  final bool receivesNotifications;
  final bool hasFinancialResponsibility;

  final String? ci;
  final String? phone;
  final String? whatsapp;
  final String? email;
  final String? address;
  final String? status;

  String get fullName => '$firstName $lastName'.trim();

  String get relationshipLabel {
    switch (relationship.trim().toLowerCase()) {
      case 'father':
        return 'Padre';
      case 'mother':
        return 'Madre';
      case 'legal_guardian':
        return 'Tutor legal';
      case 'grandfather':
        return 'Abuelo';
      case 'grandmother':
        return 'Abuela';
      case 'sibling':
        return 'Hermano/a';
      default:
        return 'Otro';
    }
  }

  factory PlayerGuardianData.fromRelationMap(Map<String, dynamic> relation) {
    final Map<String, dynamic>? guardian = _extractSingleMap(
      relation['guardians'],
    );

    if (guardian == null) {
      throw const FormatException(
        'No se encontraron los datos del tutor relacionado.',
      );
    }

    return PlayerGuardianData(
      id: _requiredString(guardian['id'], 'id del tutor'),
      firstName: _requiredString(guardian['first_name'], 'nombres del tutor'),
      lastName: _requiredString(guardian['last_name'], 'apellidos del tutor'),
      relationship: _nullableString(relation['relationship']) ?? 'other',
      isPrimary: _toBool(relation['is_primary']),
      canPickUp: _toBool(relation['can_pick_up']),
      receivesNotifications: _toBool(relation['receives_notifications']),
      hasFinancialResponsibility: _toBool(
        relation['has_financial_responsibility'],
      ),
      ci: _nullableString(guardian['ci']),
      phone: _nullableString(guardian['phone']),
      whatsapp: _nullableString(guardian['whatsapp']),
      email: _nullableString(guardian['email']),
      address: _nullableString(guardian['address']),
      status: _nullableString(guardian['status']),
    );
  }
}

Map<String, dynamic>? _extractSingleMap(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  if (value is List && value.isNotEmpty && value.first is Map) {
    return Map<String, dynamic>.from(value.first as Map);
  }

  return null;
}

List<dynamic> _extractList(dynamic value) {
  return value is List ? value : const <dynamic>[];
}

String _requiredString(dynamic value, String fieldName) {
  final String text = value?.toString().trim() ?? '';

  if (text.isEmpty) {
    throw FormatException('El campo obligatorio "$fieldName" está vacío.');
  }

  return text;
}

String? _nullableString(dynamic value) {
  final String text = value?.toString().trim() ?? '';

  return text.isEmpty ? null : text;
}

bool _toBool(dynamic value) {
  if (value is bool) {
    return value;
  }

  final String text = value?.toString().trim().toLowerCase() ?? '';

  return text == 'true' || text == '1';
}
