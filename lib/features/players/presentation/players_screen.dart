import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/player_controller.dart';
import '../models/player_model.dart';
import '../widgets/empty_players.dart';
import '../widgets/player_card.dart';
import '../widgets/player_search.dart';
import 'add_player_screen.dart';
import 'player_detail_screen.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  late final PlayerController _controller;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();

    _controller = PlayerController();
    _searchController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadPlayers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _refreshPlayers() async {
    await _controller.refreshPlayers();
  }

  Future<void> _openNewPlayer() async {
    final bool? playerWasCreated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const AddPlayerScreen()),
    );

    if (!mounted || playerWasCreated != true) {
      return;
    }

    await _controller.refreshPlayers();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.fuchsia,
          content: Text(
            'El jugador fue registrado correctamente.',
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
  }

  Future<void> _openPlayerDetails(PlayerModel player) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PlayerDetailScreen(player: player),
      ),
    );
  }

  Future<void> _openPlayerEditor(PlayerModel player) async {
    final bool? playerWasUpdated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddPlayerScreen(playerId: player.id),
      ),
    );

    if (!mounted || playerWasUpdated != true) {
      return;
    }

    await _controller.refreshPlayers();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.fuchsia,
          content: Text(
            'Los datos del jugador fueron actualizados correctamente.',
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
  }

  Future<void> _openFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext modalContext) {
        return _PlayerFiltersSheet(controller: _controller);
      },
    );
  }

  void _clearSearchAndFilters() {
    _searchController.clear();
    _controller.clearAllSearchAndFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2F4),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewPlayer,
        backgroundColor: AppColors.yellow,
        foregroundColor: AppColors.black,
        elevation: 8,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text(
          'Nuevo jugador',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? child) {
            return Column(
              children: [
                const _PlayersHeader(),
                Expanded(child: _buildContent()),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_controller.isLoading && !_controller.hasPlayers) {
      return const _PlayersLoading();
    }

    if (_controller.hasError && !_controller.hasPlayers) {
      return _PlayersError(
        message:
            _controller.errorMessage ?? 'No fue posible cargar los jugadores.',
        onRetry: () {
          _controller.loadPlayers(forceRefresh: true);
        },
      );
    }

    return RefreshIndicator(
      color: AppColors.fuchsia,
      onRefresh: _refreshPlayers,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            sliver: SliverToBoxAdapter(
              child: _PlayersSummary(
                totalPlayers: _controller.totalPlayers,
                activePlayers: _controller.activePlayersCount,
                inactivePlayers: _controller.inactivePlayersCount,
                suspendedPlayers: _controller.suspendedPlayersCount,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
            sliver: SliverToBoxAdapter(
              child: PlayerSearch(
                controller: _searchController,
                onChanged: _controller.updateSearchQuery,
                onFilterPressed: _openFilters,
                hasActiveFilters: _controller.hasActiveFilters,
              ),
            ),
          ),
          if (_controller.isRefreshing)
            const SliverToBoxAdapter(
              child: LinearProgressIndicator(
                minHeight: 3,
                color: AppColors.fuchsia,
                backgroundColor: Color(0xFFEADDE4),
              ),
            ),
          if (_controller.hasError && _controller.hasPlayers)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
              sliver: SliverToBoxAdapter(
                child: _InlineErrorMessage(
                  message:
                      _controller.errorMessage ??
                      'No fue posible actualizar la lista.',
                  onClose: _controller.clearError,
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            sliver: SliverToBoxAdapter(
              child: _ResultsHeader(
                visiblePlayers: _controller.filteredPlayers.length,
                totalPlayers: _controller.totalPlayers,
                searchQuery: _controller.searchQuery,
                hasActiveFilters: _controller.hasActiveFilters,
                onClearPressed: _clearSearchAndFilters,
              ),
            ),
          ),
          ..._buildPlayersSlivers(),
          const SliverToBoxAdapter(child: SizedBox(height: 105)),
        ],
      ),
    );
  }

  List<Widget> _buildPlayersSlivers() {
    final List<PlayerModel> visiblePlayers = _controller.filteredPlayers;

    if (!_controller.hasPlayers) {
      return <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyPlayers(
            title: 'No hay jugadores registrados',
            message:
                'Comienza registrando al primer jugador '
                'de la Escuela Formativa Polinesios.',
            buttonText: 'Nuevo jugador',
            onPressed: _openNewPlayer,
          ),
        ),
      ];
    }

    if (visiblePlayers.isEmpty) {
      return <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyPlayers(
            title: 'No encontramos jugadores',
            message:
                'Prueba con otro nombre, código, categoría '
                'o elimina los filtros seleccionados.',
            buttonText: 'Limpiar búsqueda',
            onPressed: _clearSearchAndFilters,
          ),
        ),
      ];
    }

    return <Widget>[
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        sliver: SliverLayoutBuilder(
          builder: (BuildContext context, SliverConstraints constraints) {
            final double availableWidth = constraints.crossAxisExtent;

            if (availableWidth >= 960) {
              return SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 190,
                ),
                delegate: SliverChildBuilderDelegate((
                  BuildContext context,
                  int index,
                ) {
                  return _buildPlayerCard(visiblePlayers[index]);
                }, childCount: visiblePlayers.length),
              );
            }

            return SliverList.separated(
              itemCount: visiblePlayers.length,
              itemBuilder: (BuildContext context, int index) {
                return _buildPlayerCard(visiblePlayers[index]);
              },
              separatorBuilder: (BuildContext context, int index) {
                return const SizedBox(height: 14);
              },
            );
          },
        ),
      ),
    ];
  }

  Widget _buildPlayerCard(PlayerModel player) {
    return PlayerCard(
      player: player,
      onTap: () {
        _openPlayerDetails(player);
      },
      onEditPressed: () {
        _openPlayerEditor(player);
      },
    );
  }
}

class _PlayersHeader extends StatelessWidget {
  const _PlayersHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.darkFuchsia, AppColors.fuchsia, Color(0xFF8B004D)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: const Row(
        children: [
          _HeaderIcon(),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jugadores',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Gestiona las fichas y el historial '
                  'deportivo de la escuela',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.yellow,
        borderRadius: BorderRadius.circular(19),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: const Icon(Icons.groups_rounded, color: AppColors.black, size: 34),
    );
  }
}

class _PlayersSummary extends StatelessWidget {
  const _PlayersSummary({
    required this.totalPlayers,
    required this.activePlayers,
    required this.inactivePlayers,
    required this.suspendedPlayers,
  });

  final int totalPlayers;
  final int activePlayers;
  final int inactivePlayers;
  final int suspendedPlayers;

  @override
  Widget build(BuildContext context) {
    final List<_SummaryData> data = <_SummaryData>[
      _SummaryData(
        label: 'Total',
        value: totalPlayers,
        icon: Icons.groups_rounded,
        color: AppColors.fuchsia,
      ),
      _SummaryData(
        label: 'Activos',
        value: activePlayers,
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF168A55),
      ),
      _SummaryData(
        label: 'Inactivos',
        value: inactivePlayers,
        icon: Icons.pause_circle_rounded,
        color: const Color(0xFF777777),
      ),
      _SummaryData(
        label: 'Suspendidos',
        value: suspendedPlayers,
        icon: Icons.block_rounded,
        color: const Color(0xFFC62828),
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = constraints.maxWidth >= 760 ? 4 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: data.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: constraints.maxWidth >= 760 ? 1.7 : 1.55,
          ),
          itemBuilder: (BuildContext context, int index) {
            return _SummaryCard(data: data[index]);
          },
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});

  final _SummaryData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: data.color.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.055),
            blurRadius: 13,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: data.color, size: 24),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.value.toString(),
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF756970),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({
    required this.visiblePlayers,
    required this.totalPlayers,
    required this.searchQuery,
    required this.hasActiveFilters,
    required this.onClearPressed,
  });

  final int visiblePlayers;
  final int totalPlayers;
  final String searchQuery;
  final bool hasActiveFilters;
  final VoidCallback onClearPressed;

  @override
  Widget build(BuildContext context) {
    final bool hasSearch = searchQuery.trim().isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: Text(
            hasSearch || hasActiveFilters
                ? '$visiblePlayers de $totalPlayers jugadores'
                : '$totalPlayers jugadores registrados',
            style: const TextStyle(
              color: Color(0xFF665A60),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (hasSearch || hasActiveFilters)
          TextButton.icon(
            onPressed: onClearPressed,
            icon: const Icon(Icons.filter_alt_off_rounded, size: 19),
            label: const Text('Limpiar'),
            style: TextButton.styleFrom(foregroundColor: AppColors.fuchsia),
          ),
      ],
    );
  }
}

class _PlayersLoading extends StatelessWidget {
  const _PlayersLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 54,
              height: 54,
              child: CircularProgressIndicator(
                color: AppColors.fuchsia,
                strokeWidth: 5,
              ),
            ),
            SizedBox(height: 22),
            Text(
              'Cargando jugadores...',
              style: TextStyle(
                color: Color(0xFF665A60),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayersError extends StatelessWidget {
  const _PlayersError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 470),
          child: Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cloud_off_rounded,
                    color: Colors.red,
                    size: 47,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'No pudimos cargar los jugadores',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF73676D),
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 23),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('INTENTAR NUEVAMENTE'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineErrorMessage extends StatelessWidget {
  const _InlineErrorMessage({required this.message, required this.onClose});

  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 11, 7, 11),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF8A2525),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            tooltip: 'Cerrar',
            icon: const Icon(Icons.close_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}

class _PlayerFiltersSheet extends StatefulWidget {
  const _PlayerFiltersSheet({required this.controller});

  final PlayerController controller;

  @override
  State<_PlayerFiltersSheet> createState() => _PlayerFiltersSheetState();
}

class _PlayerFiltersSheetState extends State<_PlayerFiltersSheet> {
  late String _selectedStatus;
  late String? _selectedCategoryId;
  late PlayerSortOption _selectedSortOption;

  @override
  void initState() {
    super.initState();

    _selectedStatus = widget.controller.selectedStatus;

    _selectedCategoryId = widget.controller.selectedCategoryId;

    _selectedSortOption = widget.controller.sortOption;
  }

  void _applyFilters() {
    widget.controller.updateStatusFilter(_selectedStatus);

    widget.controller.updateCategoryFilter(_selectedCategoryId);

    widget.controller.updateSortOption(_selectedSortOption);

    Navigator.of(context).pop();
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = 'all';
      _selectedCategoryId = null;
      _selectedSortOption = PlayerSortOption.nameAscending;
    });

    widget.controller.clearFilters();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final List<PlayerCategoryOption> categories =
        widget.controller.availableCategories;

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.55,
      maxChildSize: 0.94,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8F5F7),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              const _SheetHandle(),
              const Padding(
                padding: EdgeInsets.fromLTRB(22, 6, 22, 18),
                child: Row(
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      color: AppColors.fuchsia,
                      size: 28,
                    ),
                    SizedBox(width: 11),
                    Text(
                      'Filtrar jugadores',
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                  children: [
                    const _FilterTitle(title: 'Estado'),
                    const SizedBox(height: 10),
                    _StatusFilter(
                      selectedStatus: _selectedStatus,
                      onChanged: (String status) {
                        setState(() {
                          _selectedStatus = status;
                        });
                      },
                    ),
                    const SizedBox(height: 25),
                    const _FilterTitle(title: 'Categoría'),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String?>(
                      initialValue: _selectedCategoryId,
                      decoration: _filterInputDecoration(
                        icon: Icons.groups_rounded,
                        label: 'Categoría',
                      ),
                      items: <DropdownMenuItem<String?>>[
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todas las categorías'),
                        ),
                        ...categories.map((PlayerCategoryOption category) {
                          return DropdownMenuItem<String?>(
                            value: category.id,
                            child: Text(category.name),
                          );
                        }),
                      ],
                      onChanged: (String? value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                    ),
                    if (categories.isEmpty) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Las categorías aparecerán cuando '
                        'existan jugadores asignados.',
                        style: TextStyle(
                          color: Color(0xFF81747A),
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 25),
                    const _FilterTitle(title: 'Ordenar'),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<PlayerSortOption>(
                      initialValue: _selectedSortOption,
                      decoration: _filterInputDecoration(
                        icon: Icons.sort_rounded,
                        label: 'Orden',
                      ),
                      items: PlayerSortOption.values.map((
                        PlayerSortOption option,
                      ) {
                        return DropdownMenuItem<PlayerSortOption>(
                          value: option,
                          child: Text(_sortOptionLabel(option)),
                        );
                      }).toList(),
                      onChanged: (PlayerSortOption? value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _selectedSortOption = value;
                        });
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 56,
                      child: FilledButton.icon(
                        onPressed: _applyFilters,
                        icon: const Icon(Icons.check_rounded),
                        label: const Text(
                          'APLICAR FILTROS',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.yellow,
                          foregroundColor: AppColors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.filter_alt_off_rounded),
                        label: const Text(
                          'LIMPIAR FILTROS',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  InputDecoration _filterInputDecoration({
    required IconData icon,
    required String label,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      prefixIconColor: AppColors.fuchsia,
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: Color(0xFFE8DDE3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: AppColors.fuchsia, width: 2),
      ),
    );
  }

  String _sortOptionLabel(PlayerSortOption option) {
    switch (option) {
      case PlayerSortOption.nameAscending:
        return 'Nombre: A – Z';

      case PlayerSortOption.nameDescending:
        return 'Nombre: Z – A';

      case PlayerSortOption.youngestFirst:
        return 'Menores primero';

      case PlayerSortOption.oldestFirst:
        return 'Mayores primero';

      case PlayerSortOption.newestRegistration:
        return 'Inscripciones recientes';
    }
  }
}

class _StatusFilter extends StatelessWidget {
  const _StatusFilter({required this.selectedStatus, required this.onChanged});

  final String selectedStatus;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const List<_StatusOption> options = <_StatusOption>[
      _StatusOption(value: 'all', label: 'Todos', color: AppColors.fuchsia),
      _StatusOption(
        value: 'active',
        label: 'Activos',
        color: Color(0xFF168A55),
      ),
      _StatusOption(
        value: 'inactive',
        label: 'Inactivos',
        color: Color(0xFF777777),
      ),
      _StatusOption(
        value: 'withdrawn',
        label: 'Retirados',
        color: Color(0xFFB65D00),
      ),
      _StatusOption(
        value: 'suspended',
        label: 'Suspendidos',
        color: Color(0xFFC62828),
      ),
    ];

    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: options.map((_StatusOption option) {
        final bool isSelected = selectedStatus == option.value;

        return ChoiceChip(
          selected: isSelected,
          label: Text(option.label),
          onSelected: (_) {
            onChanged(option.value);
          },
          selectedColor: option.color.withValues(alpha: 0.16),
          backgroundColor: AppColors.white,
          side: BorderSide(
            color: isSelected ? option.color : const Color(0xFFE4DADF),
          ),
          labelStyle: TextStyle(
            color: isSelected ? option.color : const Color(0xFF665A60),
            fontWeight: FontWeight.w800,
          ),
          checkmarkColor: option.color,
        );
      }).toList(),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 48,
        height: 5,
        margin: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class _FilterTitle extends StatelessWidget {
  const _FilterTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.black,
        fontSize: 17,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _SummaryData {
  const _SummaryData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
}

class _StatusOption {
  const _StatusOption({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;
}
