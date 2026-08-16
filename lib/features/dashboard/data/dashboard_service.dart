import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/auth_service.dart';

class DashboardPlayerSummary {
  const DashboardPlayerSummary({
    required this.totalPlayers,
    required this.groupCounts,
    required this.withoutGroup,
  });

  final int totalPlayers;
  final Map<String, int> groupCounts;
  final int withoutGroup;

  int countFor(String groupName) {
    return groupCounts[groupName.trim().toLowerCase()] ?? 0;
  }
}

class DashboardActivity {
  const DashboardActivity({
    required this.id,
    required this.type,
    required this.date,
    required this.startTime,
    required this.title,
    required this.location,
  });

  final String id;

  /// training | match
  final String type;

  final DateTime date;
  final String startTime;
  final String title;
  final String location;

  bool get isTraining => type == 'training';

  bool get isMatch => type == 'match';

  DateTime get dateTime {
    final List<String> parts = startTime.split(':');

    final int hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;

    final int minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

    return DateTime(date.year, date.month, date.day, hour, minute);
  }
}

class DashboardBirthday {
  const DashboardBirthday({
    required this.playerId,
    required this.playerName,
    required this.birthDate,
    required this.nextBirthday,
    required this.daysUntilBirthday,
  });

  final String playerId;
  final String playerName;
  final DateTime birthDate;
  final DateTime nextBirthday;
  final int daysUntilBirthday;

  bool get isToday => daysUntilBirthday == 0;
}

class DashboardAnnouncement {
  const DashboardAnnouncement({
    required this.id,
    required this.title,
    required this.message,
    required this.publishDate,
    required this.expiresOn,
  });

  final String id;
  final String title;
  final String message;
  final DateTime publishDate;
  final DateTime expiresOn;

  int daysUntilExpiry(DateTime referenceDate) {
    final DateTime today = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    );

    final DateTime expiry = DateTime(
      expiresOn.year,
      expiresOn.month,
      expiresOn.day,
    );

    return expiry.difference(today).inDays;
  }
}

class DashboardService {
  const DashboardService();

  SupabaseClient get _client => Supabase.instance.client;

  /// Obtiene el resumen de jugadores ACTIVOS
  /// de la escuela del usuario actual.
  ///
  /// Incluye:
  /// - total de jugadores activos;
  /// - cantidad por grupo actual;
  /// - jugadores activos todavía sin grupo.
  Future<DashboardPlayerSummary> playerSummary() async {
    final Map<String, dynamic> profile = await AuthService.getCurrentProfile();

    final String schoolId = profile['school_id']?.toString().trim() ?? '';

    if (schoolId.isEmpty) {
      throw const AuthException(
        'El usuario actual no tiene '
        'una escuela asignada.',
      );
    }

    // --------------------------------------------------------
    // JUGADORES ACTIVOS
    // --------------------------------------------------------

    final List<dynamic> playersResponse = await _client
        .from('players')
        .select('id')
        .eq('school_id', schoolId)
        .eq('status', 'active');

    final Set<String> playerIds = playersResponse
        .whereType<Map>()
        .map((Map item) => item['id']?.toString().trim() ?? '')
        .where((String id) => id.isNotEmpty)
        .toSet();

    if (playerIds.isEmpty) {
      return const DashboardPlayerSummary(
        totalPlayers: 0,
        groupCounts: <String, int>{},
        withoutGroup: 0,
      );
    }

    // --------------------------------------------------------
    // GRUPOS ACTUALES
    // --------------------------------------------------------

    final List<dynamic> assignmentsResponse = await _client
        .from('player_group_assignments')
        .select('''
              player_id,
              is_current,
              training_groups (
                id,
                name
              )
            ''')
        .eq('is_current', true);

    final Map<String, int> groupCounts = <String, int>{};

    final Set<String> groupedPlayerIds = <String>{};

    for (final dynamic item in assignmentsResponse) {
      if (item is! Map) {
        continue;
      }

      final String playerId = item['player_id']?.toString().trim() ?? '';

      // Solo contamos jugadores ACTIVOS
      // pertenecientes a esta escuela.
      if (!playerIds.contains(playerId)) {
        continue;
      }

      final dynamic groupData = item['training_groups'];

      if (groupData is! Map) {
        continue;
      }

      String groupName = groupData['name']?.toString().trim() ?? '';

      if (groupName.isEmpty) {
        continue;
      }

      groupedPlayerIds.add(playerId);

      // Ej.:
      // Polinesios Junior PM
      // pasa a:
      // Junior PM
      if (groupName.toLowerCase().startsWith('polinesios ')) {
        groupName = groupName.substring('Polinesios '.length).trim();
      }

      final String key = groupName.toLowerCase();

      groupCounts[key] = (groupCounts[key] ?? 0) + 1;
    }

    return DashboardPlayerSummary(
      totalPlayers: playerIds.length,
      groupCounts: groupCounts,
      withoutGroup: playerIds.length - groupedPlayerIds.length,
    );
  }

  /// Obtiene las próximas actividades:
  ///
  /// - entrenamientos;
  /// - partidos.
  ///
  /// Se ordenan cronológicamente.
  Future<List<DashboardActivity>> upcomingActivities({int limit = 3}) async {
    final Map<String, dynamic> profile = await AuthService.getCurrentProfile();

    final String? schoolId = profile['school_id']?.toString();

    if (schoolId == null || schoolId.trim().isEmpty) {
      throw const AuthException(
        'El usuario actual no tiene '
        'una escuela asignada.',
      );
    }

    final DateTime now = DateTime.now();

    final String today =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    // --------------------------------------------------------
    // ENTRENAMIENTOS
    // --------------------------------------------------------

    final List<dynamic> trainingResponse = await _client
        .from('training_sessions')
        .select('''
              id,
              school_id,
              training_group_id,
              training_date,
              start_time,
              location,
              category_name,
              status
            ''')
        .eq('school_id', schoolId)
        .gte('training_date', today)
        .neq('status', 'completed')
        .order('training_date', ascending: true)
        .order('start_time', ascending: true);

    // --------------------------------------------------------
    // PARTIDOS
    // --------------------------------------------------------

    final List<dynamic> matchResponse = await _client
        .from('matches')
        .select('''
              id,
              school_id,
              match_date,
              start_time,
              opponent_name,
              home_away,
              status,
              training_groups (
                name
              ),
              locations (
                name
              )
            ''')
        .eq('school_id', schoolId)
        .gte('match_date', today)
        .eq('status', 'scheduled')
        .order('match_date', ascending: true)
        .order('start_time', ascending: true);

    final List<DashboardActivity> activities = <DashboardActivity>[];

    // --------------------------------------------------------
    // NORMALIZAR ENTRENAMIENTOS
    // --------------------------------------------------------

    for (final dynamic item in trainingResponse) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(item as Map);

      final DateTime? date = DateTime.tryParse(
        data['training_date']?.toString() ?? '',
      );

      if (date == null) {
        continue;
      }

      final String startTime = data['start_time']?.toString() ?? '';

      final String categoryName =
          data['category_name']?.toString().trim() ?? '';

      final String location = data['location']?.toString().trim() ?? '';

      final DashboardActivity activity = DashboardActivity(
        id: data['id']?.toString() ?? '',
        type: 'training',
        date: date,
        startTime: startTime,
        title: categoryName.isEmpty
            ? 'Entrenamiento'
            : 'Entrenamiento '
                  '$categoryName',
        location: location.isEmpty ? 'Lugar no registrado' : location,
      );

      if (!activity.dateTime.isBefore(now)) {
        activities.add(activity);
      }
    }

    // --------------------------------------------------------
    // NORMALIZAR PARTIDOS
    // --------------------------------------------------------

    for (final dynamic item in matchResponse) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(item as Map);

      final DateTime? date = DateTime.tryParse(
        data['match_date']?.toString() ?? '',
      );

      if (date == null) {
        continue;
      }

      final String startTime = data['start_time']?.toString() ?? '';

      final String opponent = data['opponent_name']?.toString().trim() ?? '';

      final String homeAway =
          data['home_away']?.toString().trim().toLowerCase() ?? '';

      final dynamic groupData = data['training_groups'];

      final dynamic locationData = data['locations'];

      String groupName = '';
      String locationName = '';

      if (groupData is Map) {
        groupName = groupData['name']?.toString().trim() ?? '';
      }

      if (locationData is Map) {
        locationName = locationData['name']?.toString().trim() ?? '';
      }

      String title;

      if (opponent.isEmpty) {
        title = 'Partido';

        if (groupName.isNotEmpty) {
          title += ' · $groupName';
        }
      } else if (homeAway == 'away') {
        title = '$opponent vs Polinesios';
      } else {
        title = 'Polinesios vs $opponent';
      }

      final DashboardActivity activity = DashboardActivity(
        id: data['id']?.toString() ?? '',
        type: 'match',
        date: date,
        startTime: startTime,
        title: title,
        location: locationName.isEmpty ? 'Lugar no registrado' : locationName,
      );

      if (!activity.dateTime.isBefore(now)) {
        activities.add(activity);
      }
    }

    // --------------------------------------------------------
    // ORDEN CRONOLÓGICO
    // --------------------------------------------------------

    activities.sort((DashboardActivity a, DashboardActivity b) {
      return a.dateTime.compareTo(b.dateTime);
    });

    if (activities.length <= limit) {
      return activities;
    }

    return activities.take(limit).toList();
  }

  /// Obtiene cumpleaños de jugadores ACTIVOS que ocurren
  /// hoy o dentro de los próximos [daysAhead] días.
  Future<List<DashboardBirthday>> upcomingBirthdays({
    int daysAhead = 3,
    int limit = 3,
  }) async {
    final Map<String, dynamic> profile = await AuthService.getCurrentProfile();

    final String schoolId = profile['school_id']?.toString().trim() ?? '';

    if (schoolId.isEmpty) {
      throw const AuthException(
        'El usuario actual no tiene '
        'una escuela asignada.',
      );
    }

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    final List<dynamic> response = await _client
        .from('players')
        .select('id, first_name, last_name, birth_date, status')
        .eq('school_id', schoolId)
        .eq('status', 'active');

    final List<DashboardBirthday> birthdays = <DashboardBirthday>[];

    for (final dynamic item in response) {
      if (item is! Map) {
        continue;
      }

      final String playerId = item['id']?.toString().trim() ?? '';
      final DateTime? birthDate = DateTime.tryParse(
        item['birth_date']?.toString() ?? '',
      );

      if (playerId.isEmpty || birthDate == null) {
        continue;
      }

      final String firstName = item['first_name']?.toString().trim() ?? '';
      final String lastName = item['last_name']?.toString().trim() ?? '';

      DateTime nextBirthday = _birthdayForYear(
        birthDate: birthDate,
        year: today.year,
      );

      if (nextBirthday.isBefore(today)) {
        nextBirthday = _birthdayForYear(
          birthDate: birthDate,
          year: today.year + 1,
        );
      }

      final int daysUntilBirthday = nextBirthday.difference(today).inDays;

      if (daysUntilBirthday < 0 || daysUntilBirthday > daysAhead) {
        continue;
      }

      final String playerName = '$firstName $lastName'
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      birthdays.add(
        DashboardBirthday(
          playerId: playerId,
          playerName: playerName,
          birthDate: birthDate,
          nextBirthday: nextBirthday,
          daysUntilBirthday: daysUntilBirthday,
        ),
      );
    }

    birthdays.sort((DashboardBirthday a, DashboardBirthday b) {
      final int byDays = a.daysUntilBirthday.compareTo(b.daysUntilBirthday);

      if (byDays != 0) {
        return byDays;
      }

      return a.playerName.compareTo(b.playerName);
    });

    if (birthdays.length <= limit) {
      return birthdays;
    }

    return birthdays.take(limit).toList();
  }

  /// Obtiene los comunicados próximos a vencer.
  ///
  /// Cada comunicado aparece en PULSO POLINESIOS solamente durante
  /// sus últimos [daysBeforeExpiry] días de vigencia, incluido el
  /// propio día de vencimiento. Al día siguiente desaparece
  /// automáticamente porque deja de cumplir el filtro de fecha.
  Future<List<DashboardAnnouncement>> expiringAnnouncements({
    int daysBeforeExpiry = 3,
    int limit = 2,
  }) async {
    final Map<String, dynamic> profile = await AuthService.getCurrentProfile();

    final String schoolId = profile['school_id']?.toString().trim() ?? '';

    if (schoolId.isEmpty) {
      throw const AuthException(
        'El usuario actual no tiene '
        'una escuela asignada.',
      );
    }

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime maximumExpiry = today.add(Duration(days: daysBeforeExpiry));

    final List<dynamic> response = await _client
        .from('announcements')
        .select('id, title, message, publish_date, expires_on, status')
        .eq('school_id', schoolId)
        .gte('expires_on', _formatDate(today))
        .lte('expires_on', _formatDate(maximumExpiry))
        .order('expires_on', ascending: true)
        .order('publish_date', ascending: false);

    final List<DashboardAnnouncement> announcements = <DashboardAnnouncement>[];

    for (final dynamic item in response) {
      if (item is! Map) {
        continue;
      }

      final String status =
          item['status']?.toString().trim().toLowerCase() ?? '';

      if (status != 'active' && status != 'published') {
        continue;
      }

      final DateTime? publishDate = DateTime.tryParse(
        item['publish_date']?.toString() ?? '',
      );

      final DateTime? expiresOn = DateTime.tryParse(
        item['expires_on']?.toString() ?? '',
      );

      if (publishDate == null || expiresOn == null) {
        continue;
      }

      final DateTime publishDay = DateTime(
        publishDate.year,
        publishDate.month,
        publishDate.day,
      );

      if (publishDay.isAfter(today)) {
        continue;
      }

      announcements.add(
        DashboardAnnouncement(
          id: item['id']?.toString().trim() ?? '',
          title: item['title']?.toString().trim() ?? '',
          message: item['message']?.toString().trim() ?? '',
          publishDate: publishDate,
          expiresOn: expiresOn,
        ),
      );

      if (announcements.length >= limit) {
        break;
      }
    }

    return announcements;
  }

  DateTime _birthdayForYear({required DateTime birthDate, required int year}) {
    if (birthDate.month == 2 && birthDate.day == 29 && !_isLeapYear(year)) {
      return DateTime(year, 2, 28);
    }

    return DateTime(year, birthDate.month, birthDate.day);
  }

  bool _isLeapYear(int year) {
    return year % 400 == 0 || (year % 4 == 0 && year % 100 != 0);
  }

  String _formatDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }
}
