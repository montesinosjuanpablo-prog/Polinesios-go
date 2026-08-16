import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/player_repository.dart';
import '../models/player_model.dart';

enum PlayerSortOption {
  nameAscending,
  nameDescending,
  youngestFirst,
  oldestFirst,
  newestRegistration,
}

class PlayerController extends ChangeNotifier {
  PlayerController();

  final PlayerRepository _repository = const PlayerRepository();

  final List<PlayerModel> _players = <PlayerModel>[];

  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _errorMessage;

  String _searchQuery = '';
  String _selectedStatus = 'all';
  String? _selectedCategoryId;
  PlayerSortOption _sortOption = PlayerSortOption.nameAscending;

  List<PlayerModel> get players => List<PlayerModel>.unmodifiable(_players);

  bool get isLoading => _isLoading;

  bool get isRefreshing => _isRefreshing;

  String? get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;

  String get selectedStatus => _selectedStatus;

  String? get selectedCategoryId => _selectedCategoryId;

  PlayerSortOption get sortOption => _sortOption;

  bool get hasError => _errorMessage != null;

  bool get hasPlayers => _players.isNotEmpty;

  bool get hasActiveFilters {
    return _selectedStatus != 'all' ||
        _selectedCategoryId != null ||
        _sortOption != PlayerSortOption.nameAscending;
  }

  int get totalPlayers => _players.length;

  int get activePlayersCount {
    return _players.where((PlayerModel player) {
      return player.status.toLowerCase() == 'active';
    }).length;
  }

  int get inactivePlayersCount {
    return _players.where((PlayerModel player) {
      return player.status.toLowerCase() == 'inactive';
    }).length;
  }

  int get suspendedPlayersCount {
    return _players.where((PlayerModel player) {
      return player.status.toLowerCase() == 'suspended';
    }).length;
  }

  List<PlayerModel> get filteredPlayers {
    final String normalizedQuery = _normalizeText(_searchQuery);

    final List<PlayerModel> result = _players.where((PlayerModel player) {
      final bool matchesSearch =
          normalizedQuery.isEmpty || _matchesSearch(player, normalizedQuery);

      final bool matchesStatus =
          _selectedStatus == 'all' ||
          player.status.toLowerCase() == _selectedStatus.toLowerCase();

      final bool matchesCategory =
          _selectedCategoryId == null ||
          player.categoryId == _selectedCategoryId;

      return matchesSearch && matchesStatus && matchesCategory;
    }).toList();

    _sortPlayers(result);

    return result;
  }

  List<String> get availableStatuses {
    final Set<String> statuses = _players
        .map((PlayerModel player) => player.status.toLowerCase())
        .where((String status) => status.isNotEmpty)
        .toSet();

    final List<String> result = statuses.toList()..sort();

    return result;
  }

  List<PlayerCategoryOption> get availableCategories {
    final Map<String, PlayerCategoryOption> categoryMap =
        <String, PlayerCategoryOption>{};

    for (final PlayerModel player in _players) {
      final String? categoryId = player.categoryId;
      final String? categoryName = player.categoryName;

      if (categoryId == null ||
          categoryId.trim().isEmpty ||
          categoryName == null ||
          categoryName.trim().isEmpty) {
        continue;
      }

      categoryMap[categoryId] = PlayerCategoryOption(
        id: categoryId,
        name: categoryName,
      );
    }

    final List<PlayerCategoryOption> result = categoryMap.values.toList();

    result.sort((PlayerCategoryOption first, PlayerCategoryOption second) {
      return first.name.toLowerCase().compareTo(second.name.toLowerCase());
    });

    return result;
  }

  Future<void> loadPlayers({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final List<PlayerModel> loadedPlayers = await _repository.getPlayers();

      _players
        ..clear()
        ..addAll(loadedPlayers);

      _players
        ..clear()
        ..addAll(loadedPlayers);
    } on AuthException catch (error) {
      _errorMessage = _authErrorMessage(error);
    } on PostgrestException catch (error) {
      _errorMessage = _databaseErrorMessage(error);
    } on FormatException catch (error) {
      _errorMessage =
          'Se encontró información de un jugador '
          'con formato incorrecto: ${error.message}';
    } catch (error, stackTrace) {
      debugPrint('Error inesperado al cargar jugadores: $error');
      debugPrintStack(stackTrace: stackTrace);

      _errorMessage =
          'No fue posible cargar los jugadores. '
          'Inténtalo nuevamente.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshPlayers() async {
    if (_isRefreshing) {
      return;
    }

    _isRefreshing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final List<PlayerModel> refreshedPlayers = await _repository.getPlayers();

      _players
        ..clear()
        ..addAll(refreshedPlayers);
    } on AuthException catch (error) {
      _errorMessage = _authErrorMessage(error);
    } on PostgrestException catch (error) {
      _errorMessage = _databaseErrorMessage(error);
    } on FormatException catch (error) {
      _errorMessage =
          'Se encontró información de un jugador '
          'con formato incorrecto: ${error.message}';
    } catch (error, stackTrace) {
      debugPrint('Error inesperado al actualizar jugadores: $error');
      debugPrintStack(stackTrace: stackTrace);

      _errorMessage = 'No fue posible actualizar la lista.';
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  void updateSearchQuery(String value) {
    final String normalizedValue = value.trimLeft();

    if (_searchQuery == normalizedValue) {
      return;
    }

    _searchQuery = normalizedValue;
    notifyListeners();
  }

  void clearSearch() {
    if (_searchQuery.isEmpty) {
      return;
    }

    _searchQuery = '';
    notifyListeners();
  }

  void updateStatusFilter(String status) {
    final String normalizedStatus = status.trim().toLowerCase();

    final String newStatus = normalizedStatus.isEmpty
        ? 'all'
        : normalizedStatus;

    if (_selectedStatus == newStatus) {
      return;
    }

    _selectedStatus = newStatus;
    notifyListeners();
  }

  void updateCategoryFilter(String? categoryId) {
    final String? normalizedCategoryId = categoryId?.trim();

    final String? newCategoryId =
        normalizedCategoryId == null || normalizedCategoryId.isEmpty
        ? null
        : normalizedCategoryId;

    if (_selectedCategoryId == newCategoryId) {
      return;
    }

    _selectedCategoryId = newCategoryId;
    notifyListeners();
  }

  void updateSortOption(PlayerSortOption option) {
    if (_sortOption == option) {
      return;
    }

    _sortOption = option;
    notifyListeners();
  }

  void clearFilters() {
    final bool nothingToClear =
        _selectedStatus == 'all' &&
        _selectedCategoryId == null &&
        _sortOption == PlayerSortOption.nameAscending;

    if (nothingToClear) {
      return;
    }

    _selectedStatus = 'all';
    _selectedCategoryId = null;
    _sortOption = PlayerSortOption.nameAscending;

    notifyListeners();
  }

  void clearAllSearchAndFilters() {
    final bool nothingToClear =
        _searchQuery.isEmpty &&
        _selectedStatus == 'all' &&
        _selectedCategoryId == null &&
        _sortOption == PlayerSortOption.nameAscending;

    if (nothingToClear) {
      return;
    }

    _searchQuery = '';
    _selectedStatus = 'all';
    _selectedCategoryId = null;
    _sortOption = PlayerSortOption.nameAscending;

    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }

  void addOrReplacePlayer(PlayerModel player) {
    final int existingIndex = _players.indexWhere((PlayerModel currentPlayer) {
      return currentPlayer.id == player.id;
    });

    if (existingIndex == -1) {
      _players.add(player);
    } else {
      _players[existingIndex] = player;
    }

    notifyListeners();
  }

  void removePlayerLocally(String playerId) {
    final int previousLength = _players.length;

    _players.removeWhere((PlayerModel player) => player.id == playerId);

    if (_players.length != previousLength) {
      notifyListeners();
    }
  }

  PlayerModel? findPlayerById(String playerId) {
    for (final PlayerModel player in _players) {
      if (player.id == playerId) {
        return player;
      }
    }

    return null;
  }

  bool _matchesSearch(PlayerModel player, String normalizedQuery) {
    final String fullName = _normalizeText(player.fullName);

    final String firstName = _normalizeText(player.firstName);

    final String lastName = _normalizeText(player.lastName);

    final String playerCode = _normalizeText(player.playerCode);

    final String category = _normalizeText(player.categoryName ?? '');

    final String trainingGroup = _normalizeText(player.trainingGroupName ?? '');

    final String position = _normalizeText(player.primaryPosition ?? '');

    return fullName.contains(normalizedQuery) ||
        firstName.contains(normalizedQuery) ||
        lastName.contains(normalizedQuery) ||
        playerCode.contains(normalizedQuery) ||
        category.contains(normalizedQuery) ||
        trainingGroup.contains(normalizedQuery) ||
        position.contains(normalizedQuery);
  }

  void _sortPlayers(List<PlayerModel> players) {
    switch (_sortOption) {
      case PlayerSortOption.nameAscending:
        players.sort((PlayerModel first, PlayerModel second) {
          return _compareNames(first, second);
        });
        break;

      case PlayerSortOption.nameDescending:
        players.sort((PlayerModel first, PlayerModel second) {
          return _compareNames(second, first);
        });
        break;

      case PlayerSortOption.youngestFirst:
        players.sort((PlayerModel first, PlayerModel second) {
          return second.birthDate.compareTo(first.birthDate);
        });
        break;

      case PlayerSortOption.oldestFirst:
        players.sort((PlayerModel first, PlayerModel second) {
          return first.birthDate.compareTo(second.birthDate);
        });
        break;

      case PlayerSortOption.newestRegistration:
        players.sort((PlayerModel first, PlayerModel second) {
          return second.registrationDate.compareTo(first.registrationDate);
        });
        break;
    }
  }

  int _compareNames(PlayerModel first, PlayerModel second) {
    final int lastNameComparison = _normalizeText(
      first.lastName,
    ).compareTo(_normalizeText(second.lastName));

    if (lastNameComparison != 0) {
      return lastNameComparison;
    }

    return _normalizeText(
      first.firstName,
    ).compareTo(_normalizeText(second.firstName));
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
        message.contains('row-level security')) {
      return 'No tienes permisos para consultar '
          'los jugadores.';
    }

    if (message.contains('relationship') || message.contains('schema cache')) {
      return 'No fue posible interpretar las relaciones '
          'de la base de datos.';
    }

    return 'Supabase no pudo cargar los jugadores: '
        '${error.message}';
  }

  String _normalizeText(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll('ñ', 'n');
  }
}

class PlayerCategoryOption {
  const PlayerCategoryOption({required this.id, required this.name});

  final String id;
  final String name;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PlayerCategoryOption &&
            runtimeType == other.runtimeType &&
            id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}
