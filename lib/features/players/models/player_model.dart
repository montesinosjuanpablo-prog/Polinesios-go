class PlayerModel {
  const PlayerModel({
    required this.id,
    required this.playerCode,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.registrationDate,
    required this.status,
    this.schoolId,
    this.photoUrl,
    this.ci,
    this.gender,
    this.address,
    this.schoolName,
    this.primaryPosition,
    this.secondaryPosition,
    this.dominantFoot,
    this.heightCm,
    this.weightKg,
    this.shirtSize,
    this.shortsSize,
    this.socksSize,
    this.categoryId,
    this.categoryName,
    this.trainingGroupId,
    this.trainingGroupName,
    this.trainingGroupStartTime,
    this.trainingGroupEndTime,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? schoolId;

  final String playerCode;
  final String? photoUrl;

  final String firstName;
  final String lastName;
  final String? ci;
  final DateTime birthDate;
  final String? gender;
  final String? address;
  final String? schoolName;

  final DateTime registrationDate;
  final String status;

  final String? primaryPosition;
  final String? secondaryPosition;
  final String? dominantFoot;
  final double? heightCm;
  final double? weightKg;
  final String? shirtSize;
  final String? shortsSize;
  final String? socksSize;

  final String? categoryId;
  final String? categoryName;

  final String? trainingGroupId;
  final String? trainingGroupName;
  final String? trainingGroupStartTime;
  final String? trainingGroupEndTime;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get fullName {
    return '$firstName $lastName'.trim();
  }

  String get initials {
    final String firstInitial = firstName.trim().isNotEmpty
        ? firstName.trim()[0].toUpperCase()
        : '';

    final String lastInitial = lastName.trim().isNotEmpty
        ? lastName.trim()[0].toUpperCase()
        : '';

    return '$firstInitial$lastInitial';
  }

  bool get isActive {
    return status.toLowerCase() == 'active';
  }

  int get age {
    final DateTime today = DateTime.now();

    int calculatedAge = today.year - birthDate.year;

    final bool birthdayHasNotOccurred =
        today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day);

    if (birthdayHasNotOccurred) {
      calculatedAge--;
    }

    return calculatedAge;
  }

  String get displayCategory {
    final String value = categoryName?.trim() ?? '';

    return value.isEmpty ? 'Sin categoría' : value;
  }

  String get displayTrainingGroup {
    String value = trainingGroupName?.trim() ?? '';

    if (value.isEmpty) {
      return 'Sin grupo asignado';
    }

    if (value.startsWith('Polinesios ')) {
      value = value.substring('Polinesios '.length);
    }

    return value;
  }

  String get displayPosition {
    final String value = primaryPosition?.trim() ?? '';

    return value.isEmpty ? 'Sin posición definida' : value;
  }

  factory PlayerModel.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic>? sportProfile = _extractSingleMap(
      map['player_sport_profiles'],
    );

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

    final Map<String, dynamic>? category = _extractSingleMap(
      trainingGroup?['categories'],
    );

    return PlayerModel(
      id: _requiredString(map['id'], 'id'),
      schoolId: _nullableString(map['school_id']),
      playerCode: _requiredString(map['player_code'], 'player_code'),
      photoUrl: _nullableString(map['photo_url']),
      firstName: _requiredString(map['first_name'], 'first_name'),
      lastName: _requiredString(map['last_name'], 'last_name'),
      ci: _nullableString(map['ci']),
      birthDate: _requiredDate(map['birth_date'], 'birth_date'),
      gender: _nullableString(map['gender']),
      address: _nullableString(map['address']),
      schoolName: _nullableString(map['school_name']),
      registrationDate: _requiredDate(
        map['registration_date'],
        'registration_date',
      ),
      status: _requiredString(map['status'], 'status'),
      primaryPosition: _nullableString(sportProfile?['primary_position']),
      secondaryPosition: _nullableString(sportProfile?['secondary_position']),
      dominantFoot: _nullableString(sportProfile?['dominant_foot']),
      heightCm: _nullableDouble(sportProfile?['height_cm']),
      weightKg: _nullableDouble(sportProfile?['weight_kg']),
      shirtSize: _nullableString(sportProfile?['shirt_size']),
      shortsSize: _nullableString(sportProfile?['shorts_size']),
      socksSize: _nullableString(sportProfile?['socks_size']),
      trainingGroupId: _nullableString(trainingGroup?['id']),
      trainingGroupName: _nullableString(trainingGroup?['name']),
      trainingGroupStartTime: _nullableString(trainingGroup?['start_time']),
      trainingGroupEndTime: _nullableString(trainingGroup?['end_time']),
      categoryId: _nullableString(category?['id']),
      categoryName: _nullableString(category?['name']),
      createdAt: _nullableDate(map['created_at']),
      updatedAt: _nullableDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toPlayerMap() {
    return <String, dynamic>{
      if (schoolId != null) 'school_id': schoolId,
      'player_code': playerCode.trim(),
      'photo_url': _emptyToNull(photoUrl),
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'ci': _emptyToNull(ci),
      'birth_date': _dateOnly(birthDate),
      'gender': _emptyToNull(gender),
      'address': _emptyToNull(address),
      'school_name': _emptyToNull(schoolName),
      'registration_date': _dateOnly(registrationDate),
      'status': status,
    };
  }

  Map<String, dynamic> toSportProfileMap() {
    return <String, dynamic>{
      'player_id': id,
      'primary_position': _emptyToNull(primaryPosition),
      'secondary_position': _emptyToNull(secondaryPosition),
      'dominant_foot': _emptyToNull(dominantFoot),
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'shirt_size': _emptyToNull(shirtSize),
      'shorts_size': _emptyToNull(shortsSize),
      'socks_size': _emptyToNull(socksSize),
    };
  }

  PlayerModel copyWith({
    String? id,
    String? schoolId,
    String? playerCode,
    String? photoUrl,
    String? firstName,
    String? lastName,
    String? ci,
    DateTime? birthDate,
    String? gender,
    String? address,
    String? schoolName,
    DateTime? registrationDate,
    String? status,
    String? primaryPosition,
    String? secondaryPosition,
    String? dominantFoot,
    double? heightCm,
    double? weightKg,
    String? shirtSize,
    String? shortsSize,
    String? socksSize,
    String? categoryId,
    String? categoryName,
    String? trainingGroupId,
    String? trainingGroupName,
    String? trainingGroupStartTime,
    String? trainingGroupEndTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlayerModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      playerCode: playerCode ?? this.playerCode,
      photoUrl: photoUrl ?? this.photoUrl,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      ci: ci ?? this.ci,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      schoolName: schoolName ?? this.schoolName,
      registrationDate: registrationDate ?? this.registrationDate,
      status: status ?? this.status,
      primaryPosition: primaryPosition ?? this.primaryPosition,
      secondaryPosition: secondaryPosition ?? this.secondaryPosition,
      dominantFoot: dominantFoot ?? this.dominantFoot,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      shirtSize: shirtSize ?? this.shirtSize,
      shortsSize: shortsSize ?? this.shortsSize,
      socksSize: socksSize ?? this.socksSize,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      trainingGroupId: trainingGroupId ?? this.trainingGroupId,
      trainingGroupName: trainingGroupName ?? this.trainingGroupName,
      trainingGroupStartTime:
          trainingGroupStartTime ?? this.trainingGroupStartTime,
      trainingGroupEndTime: trainingGroupEndTime ?? this.trainingGroupEndTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static Map<String, dynamic>? _extractSingleMap(dynamic value) {
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

  static List<dynamic> _extractList(dynamic value) {
    if (value is List) {
      return value;
    }

    return const <dynamic>[];
  }

  static String _requiredString(dynamic value, String fieldName) {
    final String result = value?.toString().trim() ?? '';

    if (result.isEmpty) {
      throw FormatException('El campo obligatorio "$fieldName" está vacío.');
    }

    return result;
  }

  static String? _nullableString(dynamic value) {
    final String result = value?.toString().trim() ?? '';

    return result.isEmpty ? null : result;
  }

  static double? _nullableDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  static DateTime _requiredDate(dynamic value, String fieldName) {
    final DateTime? result = _nullableDate(value);

    if (result == null) {
      throw FormatException('La fecha obligatoria "$fieldName" no es válida.');
    }

    return result;
  }

  static DateTime? _nullableDate(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value.toString());
  }

  static String _dateOnly(DateTime date) {
    final String year = date.year.toString().padLeft(4, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  static dynamic _emptyToNull(String? value) {
    final String result = value?.trim() ?? '';

    return result.isEmpty ? null : result;
  }
}
