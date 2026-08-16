class TrainingGroupModel {
  final String id;
  final String schoolId;
  final String categoryId;
  final String locationId;
  final String coachId;

  final String name;

  final String startTime;
  final String endTime;

  final String status;

  // Nombre visible de la sede/cancha obtenido
  // desde la tabla locations de Supabase.
  final String locationName;

  // Nombre visible del entrenador obtenido
  // desde la tabla profiles de Supabase.
  final String coachName;

  const TrainingGroupModel({
    required this.id,
    required this.schoolId,
    required this.categoryId,
    required this.locationId,
    required this.coachId,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.locationName,
    required this.coachName,
  });

  factory TrainingGroupModel.fromMap(Map<String, dynamic> map) {
    final dynamic locationData = map['locations'];
    final dynamic coachData = map['profiles'];

    String resolvedLocationName = '';
    String resolvedCoachName = '';

    // Resolver nombre del lugar.
    if (locationData is Map) {
      resolvedLocationName = locationData['name']?.toString().trim() ?? '';
    }

    // Resolver nombre completo del entrenador.
    if (coachData is Map) {
      final String firstName = coachData['first_name']?.toString().trim() ?? '';

      final String lastName = coachData['last_name']?.toString().trim() ?? '';

      resolvedCoachName = [
        firstName,
        lastName,
      ].where((String value) => value.isNotEmpty).join(' ');
    }

    return TrainingGroupModel(
      id: map['id']?.toString() ?? '',
      schoolId: map['school_id']?.toString() ?? '',
      categoryId: map['category_id']?.toString() ?? '',
      locationId: map['location_id']?.toString() ?? '',
      coachId: map['coach_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      startTime: map['start_time']?.toString() ?? '',
      endTime: map['end_time']?.toString() ?? '',
      status: map['status']?.toString() ?? '',
      locationName: resolvedLocationName,
      coachName: resolvedCoachName,
    );
  }
}
