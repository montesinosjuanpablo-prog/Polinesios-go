import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/attendance_model.dart';
import '../repositories/attendance_repository.dart';

class AttendanceController extends ChangeNotifier {
  AttendanceController({this._repository = const AttendanceRepository()});

  final AttendanceRepository _repository;

  final List<AttendanceTrainingGroup> _groups = <AttendanceTrainingGroup>[];

  final List<AttendanceModel> _attendance = <AttendanceModel>[];

  AttendanceTrainingGroup? _selectedGroup;

  bool _isLoadingGroups = false;
  bool _isLoadingPlayers = false;
  bool _isSaving = false;

  String? _errorMessage;
  String? _lastSavedSessionId;

  DateTime _sessionDate = _dateOnly(DateTime.now());

  List<AttendanceTrainingGroup> get groups =>
      List<AttendanceTrainingGroup>.unmodifiable(_groups);

  List<AttendanceModel> get attendance =>
      List<AttendanceModel>.unmodifiable(_attendance);

  AttendanceTrainingGroup? get selectedGroup => _selectedGroup;

  bool get isLoadingGroups => _isLoadingGroups;
  bool get isLoadingPlayers => _isLoadingPlayers;
  bool get isSaving => _isSaving;

  bool get isBusy {
    return _isLoadingGroups || _isLoadingPlayers || _isSaving;
  }

  String? get errorMessage => _errorMessage;

  String? get lastSavedSessionId => _lastSavedSessionId;

  DateTime get sessionDate => _sessionDate;

  bool get hasGroups => _groups.isNotEmpty;
  bool get hasPlayers => _attendance.isNotEmpty;

  int get totalPlayers => _attendance.length;

  int get presentCount {
    return _countByStatus(AttendanceStatus.present);
  }

  int get lateCount {
    return _countByStatus(AttendanceStatus.late);
  }

  int get absentCount {
    return _countByStatus(AttendanceStatus.absent);
  }

  int get injuredCount {
    return _countByStatus(AttendanceStatus.injured);
  }

  Future<void> initialize() async {
    if (_isLoadingGroups) {
      return;
    }

    _isLoadingGroups = true;
    _errorMessage = null;
    _sessionDate = _dateOnly(DateTime.now());
    notifyListeners();

    try {
      final List<AttendanceTrainingGroup> loadedGroups = await _repository
          .getTrainingGroups();

      _groups
        ..clear()
        ..addAll(loadedGroups);

      if (_groups.isEmpty) {
        _selectedGroup = null;
        _attendance.clear();
        return;
      }

      final String groupId = _selectedGroup?.id ?? _groups.first.id;

      await selectGroup(groupId);
    } on AuthException catch (error) {
      _errorMessage = _authErrorMessage(error);
    } on PostgrestException catch (error) {
      _errorMessage = _databaseErrorMessage(error);
    } on FormatException catch (error) {
      _errorMessage = error.message;
    } catch (error, stackTrace) {
      debugPrint('Error inesperado al cargar asistencia: $error');
      debugPrintStack(stackTrace: stackTrace);

      _errorMessage = 'No fue posible cargar el módulo de asistencia.';
    } finally {
      _isLoadingGroups = false;
      notifyListeners();
    }
  }

  Future<void> selectGroup(String trainingGroupId) async {
    final String normalizedGroupId = trainingGroupId.trim();

    if (normalizedGroupId.isEmpty) {
      return;
    }

    AttendanceTrainingGroup? group;

    for (final AttendanceTrainingGroup item in _groups) {
      if (item.id == normalizedGroupId) {
        group = item;
        break;
      }
    }

    if (group == null) {
      _errorMessage = 'El grupo seleccionado no está disponible.';
      notifyListeners();
      return;
    }

    _selectedGroup = group;
    _isLoadingPlayers = true;
    _errorMessage = null;
    _lastSavedSessionId = null;

    _attendance.clear();
    notifyListeners();

    try {
      final List<AttendanceModel> players = await _repository
          .getPlayersByTrainingGroup(normalizedGroupId);

      final Map<String, SavedAttendanceRecord> savedAttendance =
          await _repository.getSavedAttendance(
            trainingGroupId: normalizedGroupId,
            sessionDate: _sessionDate,
          );

      final List<AttendanceModel> mergedAttendance = players.map((
        AttendanceModel player,
      ) {
        final SavedAttendanceRecord? saved = savedAttendance[player.playerId];

        if (saved == null) {
          return player;
        }

        return player.copyWith(
          status: saved.status,
          observation: saved.observation,
        );
      }).toList();

      _attendance
        ..clear()
        ..addAll(mergedAttendance);
    } on AuthException catch (error) {
      _errorMessage = _authErrorMessage(error);
    } on PostgrestException catch (error) {
      _errorMessage = _databaseErrorMessage(error);
    } on FormatException catch (error) {
      _errorMessage = error.message;
    } catch (error, stackTrace) {
      debugPrint('Error al cargar jugadores del grupo: $error');
      debugPrintStack(stackTrace: stackTrace);

      _errorMessage = 'No fue posible cargar los jugadores del grupo.';
    } finally {
      _isLoadingPlayers = false;
      notifyListeners();
    }
  }

  Future<bool> saveAttendance({
    DateTime? sessionDate,
    String? sessionNotes,
  }) async {
    if (_isSaving) {
      return false;
    }

    final AttendanceTrainingGroup? group = _selectedGroup;

    if (group == null) {
      _errorMessage = 'Debes seleccionar un grupo de entrenamiento.';
      notifyListeners();
      return false;
    }

    if (_attendance.isEmpty) {
      _errorMessage = 'No hay jugadores para guardar.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    _lastSavedSessionId = null;
    notifyListeners();

    try {
      final DateTime selectedDate = sessionDate ?? _sessionDate;

      final DateTime normalizedDate = _dateOnly(selectedDate);

      _sessionDate = normalizedDate;

      final String sessionId = await _repository.saveTrainingAttendance(
        trainingGroup: group,
        sessionDate: normalizedDate,
        attendance: _attendance,
        sessionNotes: sessionNotes,
      );

      _lastSavedSessionId = sessionId;

      return true;
    } on AuthException catch (error) {
      _errorMessage = _authErrorMessage(error);
      return false;
    } on PostgrestException catch (error) {
      _errorMessage = _databaseErrorMessage(error);
      return false;
    } on FormatException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (error, stackTrace) {
      debugPrint('Error inesperado al guardar asistencia: $error');
      debugPrintStack(stackTrace: stackTrace);

      _errorMessage = 'No fue posible guardar la asistencia.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> selectSessionDate(DateTime value) async {
    final DateTime normalizedDate = _dateOnly(value);

    if (_sessionDate == normalizedDate) {
      return;
    }

    _sessionDate = normalizedDate;
    _lastSavedSessionId = null;

    final AttendanceTrainingGroup? group = _selectedGroup;

    if (group == null) {
      notifyListeners();
      return;
    }

    await selectGroup(group.id);
  }

  void cyclePlayerStatus(String playerId) {
    if (_isSaving) {
      return;
    }

    final int index = _attendance.indexWhere(
      (AttendanceModel item) => item.playerId == playerId,
    );

    if (index == -1) {
      return;
    }

    final AttendanceModel current = _attendance[index];

    _attendance[index] = current.copyWith(status: _nextStatus(current.status));

    _lastSavedSessionId = null;
    notifyListeners();
  }

  void updatePlayerStatus(String playerId, AttendanceStatus status) {
    if (_isSaving) {
      return;
    }

    final int index = _attendance.indexWhere(
      (AttendanceModel item) => item.playerId == playerId,
    );

    if (index == -1) {
      return;
    }

    _attendance[index] = _attendance[index].copyWith(status: status);

    _lastSavedSessionId = null;
    notifyListeners();
  }

  void updateObservation(String playerId, String? observation) {
    if (_isSaving) {
      return;
    }

    final int index = _attendance.indexWhere(
      (AttendanceModel item) => item.playerId == playerId,
    );

    if (index == -1) {
      return;
    }

    final String normalized = observation?.trim() ?? '';

    _attendance[index] = _attendance[index].copyWith(
      observation: normalized.isEmpty ? null : normalized,
    );

    _lastSavedSessionId = null;
    notifyListeners();
  }

  void markAllPresent() {
    if (_isSaving) {
      return;
    }

    for (int index = 0; index < _attendance.length; index++) {
      _attendance[index] = _attendance[index].copyWith(
        status: AttendanceStatus.present,
      );
    }

    _lastSavedSessionId = null;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }

  int _countByStatus(AttendanceStatus status) {
    return _attendance.where((AttendanceModel item) {
      return item.status == status;
    }).length;
  }

  AttendanceStatus _nextStatus(AttendanceStatus current) {
    switch (current) {
      case AttendanceStatus.present:
        return AttendanceStatus.late;

      case AttendanceStatus.late:
        return AttendanceStatus.absent;

      case AttendanceStatus.absent:
        return AttendanceStatus.injured;

      case AttendanceStatus.injured:
        return AttendanceStatus.present;
    }
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String _authErrorMessage(AuthException error) {
    final String message = error.message.toLowerCase();

    if (message.contains('jwt') ||
        message.contains('session') ||
        message.contains('not authenticated')) {
      return 'Tu sesión terminó. '
          'Vuelve a iniciar sesión.';
    }

    return 'No fue posible validar tu sesión.';
  }

  String _databaseErrorMessage(PostgrestException error) {
    final String message = error.message.toLowerCase();

    if (message.contains('permission') ||
        message.contains('policy') ||
        message.contains('row-level security') ||
        error.code == '42501') {
      return 'No tienes permisos para registrar '
          'la asistencia.';
    }

    if (message.contains('grupo seleccionado')) {
      return 'El grupo seleccionado no pertenece '
          'a tu escuela.';
    }

    if (message.contains('jugadores no pertenece') ||
        message.contains('jugador no pertenece')) {
      return 'Uno de los jugadores no pertenece '
          'al grupo seleccionado.';
    }

    if (message.contains('relationship') || message.contains('schema cache')) {
      return 'Supabase no pudo interpretar las '
          'relaciones del módulo de asistencia.';
    }

    return 'Supabase no pudo procesar la asistencia: '
        '${error.message}';
  }
}
