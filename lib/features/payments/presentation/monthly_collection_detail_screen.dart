import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../players/models/player_model.dart';
import '../../players/repositories/player_repository.dart';
import '../models/monthly_collection_player.dart';
import '../repositories/payment_repository.dart';
import 'payment_account_screen.dart';

class MonthlyCollectionDetailScreen extends StatefulWidget {
  const MonthlyCollectionDetailScreen({
    this.initialYear,
    this.initialMonth,
    this.initialFilter = 'all',
    super.key,
  });

  final int? initialYear;
  final int? initialMonth;

  /// Valores admitidos:
  /// - all
  /// - paid
  /// - pending
  final String initialFilter;

  @override
  State<MonthlyCollectionDetailScreen> createState() {
    return _MonthlyCollectionDetailScreenState();
  }
}

class _MonthlyCollectionDetailScreenState
    extends State<MonthlyCollectionDetailScreen> {
  final PaymentRepository _paymentRepository = const PaymentRepository();

  final PlayerRepository _playerRepository = const PlayerRepository();

  final TextEditingController _searchController = TextEditingController();

  List<MonthlyCollectionPlayer> _players = <MonthlyCollectionPlayer>[];

  late int _selectedYear;
  late int _selectedMonth;
  late String _statusFilter;

  bool _isLoading = true;
  String? _errorMessage;

  String? _openingPlayerId;

  @override
  void initState() {
    super.initState();

    final DateTime now = DateTime.now();

    _selectedYear = widget.initialYear ?? now.year;

    _selectedMonth = widget.initialMonth ?? now.month;

    _statusFilter = _normalizeInitialFilter(widget.initialFilter);

    _loadCollectionDetail();
  }

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  String _normalizeInitialFilter(String value) {
    switch (value) {
      case 'paid':
      case 'pending':
        return value;

      case 'all':
      default:
        return 'all';
    }
  }

  Future<void> _loadCollectionDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<MonthlyCollectionPlayer> players = await _paymentRepository
          .getSchoolMonthlyCollectionDetail(
            year: _selectedYear,
            month: _selectedMonth,
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _players = players;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint(
        'Error al cargar detalle de cobranza: '
        '$error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _players = <MonthlyCollectionPlayer>[];

        _isLoading = false;

        _errorMessage =
            'No fue posible cargar el detalle '
            'de cobranza del período.';
      });
    }
  }

  Future<void> _selectPeriod() async {
    final _CollectionPeriodSelection? result =
        await showModalBottomSheet<_CollectionPeriodSelection>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (BuildContext context) {
            return _CollectionPeriodSelectorSheet(
              selectedYear: _selectedYear,
              selectedMonth: _selectedMonth,
            );
          },
        );

    if (result == null || !mounted) {
      return;
    }

    final bool changed =
        result.year != _selectedYear || result.month != _selectedMonth;

    if (!changed) {
      return;
    }

    setState(() {
      _selectedYear = result.year;
      _selectedMonth = result.month;
    });

    await _loadCollectionDetail();
  }

  List<MonthlyCollectionPlayer> get _filteredPlayers {
    final String query = _normalizeSearchText(_searchController.text);

    return _players.where((MonthlyCollectionPlayer player) {
      final bool matchesStatus;

      switch (_statusFilter) {
        case 'paid':
          matchesStatus = player.isPaid;

        case 'pending':
          matchesStatus = player.isPending;

        case 'all':
        default:
          matchesStatus = true;
      }

      if (!matchesStatus) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final String searchable = <String>[
        player.fullName,
        player.playerCode,
        player.displayCategory,
        player.paymentMethodLabel,
        player.statusLabel,
        _formatAmount(player.amountDue),
        _formatAmount(player.amountPaid),
        _formatAmount(player.pendingAmount),
      ].join(' ');

      return _normalizeSearchText(searchable).contains(query);
    }).toList();
  }

  int get _paidCount {
    return _players
        .where((MonthlyCollectionPlayer player) => player.isPaid)
        .length;
  }

  int get _pendingCount {
    return _players
        .where((MonthlyCollectionPlayer player) => player.isPending)
        .length;
  }

  double get _totalDue {
    return _players.fold<double>(
      0,
      (double total, MonthlyCollectionPlayer player) =>
          total + player.amountDue,
    );
  }

  double get _totalPaid {
    return _players.fold<double>(
      0,
      (double total, MonthlyCollectionPlayer player) =>
          total + player.amountPaid,
    );
  }

  double get _totalPending {
    return _players.fold<double>(
      0,
      (double total, MonthlyCollectionPlayer player) =>
          total + player.pendingAmount,
    );
  }

  bool get _hasActiveFilters {
    return _statusFilter != 'all' || _searchController.text.trim().isNotEmpty;
  }

  void _clearFilters() {
    FocusScope.of(context).unfocus();

    _searchController.clear();

    setState(() {
      _statusFilter = 'all';
    });
  }

  Future<void> _openPlayerAccount(MonthlyCollectionPlayer item) async {
    if (_openingPlayerId != null) {
      return;
    }

    setState(() {
      _openingPlayerId = item.playerId;
    });

    try {
      final PlayerModel player = await _playerRepository.getPlayerById(
        item.playerId,
      );

      if (!mounted) {
        return;
      }

      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => PaymentAccountScreen(player: player),
        ),
      );

      if (!mounted) {
        return;
      }

      await _loadCollectionDetail();
    } catch (error) {
      debugPrint(
        'Error al abrir estado de cuenta: '
        '$error',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'No fue posible abrir el estado '
        'de cuenta del jugador.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _openingPlayerId = null;
        });
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError
              ? const Color(0xFFC62828)
              : const Color(0xFF168A55),
          content: Row(
            children: [
              Icon(
                isError ? Icons.error_rounded : Icons.check_circle_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  String _normalizeSearchText(String value) {
    String text = value.toLowerCase().trim();

    const Map<String, String> replacements = <String, String>{
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'ñ': 'n',
    };

    replacements.forEach((String from, String to) {
      text = text.replaceAll(from, to);
    });

    return text;
  }

  String _monthName(int month) {
    const List<String> months = <String>[
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];

    if (month < 1 || month > months.length) {
      return 'Mes';
    }

    return months[month - 1];
  }

  String _formatAmount(double amount) {
    final bool whole = amount == amount.roundToDouble();

    final String value = whole
        ? amount.toInt().toString()
        : amount.toStringAsFixed(2);

    return '$value Bs';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2F4),
      appBar: AppBar(
        backgroundColor: AppColors.darkFuchsia,
        foregroundColor: Colors.white,
        title: const Text(
          'Detalle de cobranza',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _isLoading ? null : _loadCollectionDetail,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.fuchsia,
          onRefresh: _loadCollectionDetail,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 34),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPeriodSelector(),

        const SizedBox(height: 18),

        if (_isLoading)
          const _CollectionLoadingCard()
        else if (_errorMessage != null)
          _CollectionErrorCard(
            message: _errorMessage!,
            onRetry: _loadCollectionDetail,
          )
        else ...[
          _buildOverview(),

          const SizedBox(height: 18),

          _buildFilters(),

          const SizedBox(height: 18),

          _buildResults(),
        ],
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return InkWell(
      onTap: _isLoading ? null : _selectPeriod,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.fuchsia.withValues(alpha: 0.16)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.fuchsia.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: AppColors.fuchsia,
                size: 28,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Período de cobranza',
                    style: TextStyle(
                      color: Color(0xFF81747A),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_monthName(_selectedMonth)} '
                    '$_selectedYear',
                    style: const TextStyle(
                      color: AppColors.black,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.expand_more_rounded, color: AppColors.fuchsia),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.darkFuchsia, AppColors.fuchsia],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.fuchsia.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                color: AppColors.yellow,
                size: 30,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Cobranza del período',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _CollectionOverviewMetric(
                  label: 'Esperado',
                  value: _formatAmount(_totalDue),
                ),
              ),
              Container(width: 1, height: 52, color: Colors.white24),
              Expanded(
                child: _CollectionOverviewMetric(
                  label: 'Pagado',
                  value: _formatAmount(_totalPaid),
                ),
              ),
              Container(width: 1, height: 52, color: Colors.white24),
              Expanded(
                child: _CollectionOverviewMetric(
                  label: 'Pendiente',
                  value: _formatAmount(_totalPending),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_players.length} '
                    '${_players.length == 1 ? 'jugador' : 'jugadores'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '$_paidCount al día',
                  style: const TextStyle(
                    color: AppColors.yellow,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$_pendingCount pendientes',
                  style: const TextStyle(
                    color: Colors.white70,
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

  Widget _buildFilters() {
    final int resultCount = _filteredPlayers.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.fuchsia.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.search_rounded, color: AppColors.fuchsia),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Buscar y filtrar',
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          TextField(
            controller: _searchController,
            onChanged: (String value) {
              setState(() {});
            },
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: 'Buscar jugador',
              hintText: 'Nombre, código, categoría...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.trim().isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpiar búsqueda',
                      onPressed: () {
                        _searchController.clear();

                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.fuchsia,
                  width: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = constraints.maxWidth < 520;

              final List<Widget> buttons = <Widget>[
                _CollectionFilterButton(
                  label: 'TODOS',
                  count: _players.length,
                  selected: _statusFilter == 'all',
                  onPressed: () {
                    setState(() {
                      _statusFilter = 'all';
                    });
                  },
                ),
                _CollectionFilterButton(
                  label: 'AL DÍA',
                  count: _paidCount,
                  selected: _statusFilter == 'paid',
                  onPressed: () {
                    setState(() {
                      _statusFilter = 'paid';
                    });
                  },
                ),
                _CollectionFilterButton(
                  label: 'PENDIENTES',
                  count: _pendingCount,
                  selected: _statusFilter == 'pending',
                  onPressed: () {
                    setState(() {
                      _statusFilter = 'pending';
                    });
                  },
                ),
              ];

              if (compact) {
                return Column(
                  children: [
                    for (int index = 0; index < buttons.length; index++) ...[
                      SizedBox(width: double.infinity, child: buttons[index]),
                      if (index != buttons.length - 1)
                        const SizedBox(height: 9),
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  for (int index = 0; index < buttons.length; index++) ...[
                    Expanded(child: buttons[index]),
                    if (index != buttons.length - 1) const SizedBox(width: 9),
                  ],
                ],
              );
            },
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.fuchsia.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.groups_rounded,
                  color: AppColors.fuchsia,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    resultCount == 1
                        ? '1 jugador encontrado'
                        : '$resultCount jugadores encontrados',
                    style: const TextStyle(
                      color: AppColors.fuchsia,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_hasActiveFilters) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.filter_alt_off_rounded),
                label: const Text(
                  'LIMPIAR FILTROS',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                style: TextButton.styleFrom(foregroundColor: AppColors.fuchsia),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResults() {
    final List<MonthlyCollectionPlayer> players = _filteredPlayers;

    if (_players.isEmpty) {
      return const _NoCollectionPlayersCard();
    }

    if (players.isEmpty) {
      return _FilteredCollectionEmptyCard(onClearFilters: _clearFilters);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...players.map((MonthlyCollectionPlayer player) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildPlayerCard(player),
          );
        }),
      ],
    );
  }

  Widget _buildPlayerCard(MonthlyCollectionPlayer player) {
    final bool paid = player.isPaid;

    final Color statusColor = paid
        ? const Color(0xFF168A55)
        : const Color(0xFFE59A00);

    final double progress = (player.collectionPercentage / 100).clamp(0.0, 1.0);

    final bool opening = _openingPlayerId == player.playerId;

    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: statusColor.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  paid ? Icons.verified_rounded : Icons.schedule_rounded,
                  color: statusColor,
                  size: 28,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.fullName,
                      style: const TextStyle(
                        color: AppColors.black,
                        fontSize: 17.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${player.playerCode} · '
                      '${player.displayCategory}',
                      style: const TextStyle(
                        color: Color(0xFF81747A),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  player.statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F3F5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _CollectionMoneyRow(
                  label: 'Esperado',
                  value: _formatAmount(player.amountDue),
                ),
                const SizedBox(height: 9),
                _CollectionMoneyRow(
                  label: 'Pagado',
                  value: _formatAmount(player.amountPaid),
                  valueColor: const Color(0xFF168A55),
                ),
                const SizedBox(height: 9),
                _CollectionMoneyRow(
                  label: 'Pendiente',
                  value: _formatAmount(player.pendingAmount),
                  valueColor: player.pendingAmount > 0
                      ? const Color(0xFFE59A00)
                      : const Color(0xFF168A55),
                ),
                const SizedBox(height: 9),
                _CollectionMoneyRow(
                  label: 'Método confirmado',
                  value: player.paymentMethodLabel,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: const Color(0xFFEFE6EA),
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${player.collectionPercentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: opening
                  ? null
                  : () {
                      _openPlayerAccount(player);
                    },
              icon: opening
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : const Icon(Icons.account_balance_wallet_outlined),
              label: Text(
                opening ? 'ABRIENDO...' : 'VER ESTADO DE CUENTA',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.fuchsia,
                side: const BorderSide(color: AppColors.fuchsia),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionOverviewMetric extends StatelessWidget {
  const _CollectionOverviewMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.yellow,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _CollectionFilterButton extends StatelessWidget {
  const _CollectionFilterButton({
    required this.label,
    required this.count,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? AppColors.fuchsia : Colors.white,
        foregroundColor: selected ? Colors.white : AppColors.fuchsia,
        side: const BorderSide(color: AppColors.fuchsia),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: selected
                  ? Colors.white.withValues(alpha: 0.18)
                  : AppColors.fuchsia.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionMoneyRow extends StatelessWidget {
  const _CollectionMoneyRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF81747A),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: valueColor ?? AppColors.black,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _CollectionLoadingCard extends StatelessWidget {
  const _CollectionLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 420,
      child: Center(child: CircularProgressIndicator(color: AppColors.fuchsia)),
    );
  }
}

class _NoCollectionPlayersCard extends StatelessWidget {
  const _NoCollectionPlayersCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            color: AppColors.fuchsia,
            size: 56,
          ),
          SizedBox(height: 14),
          Text(
            'No existen cargos registrados '
            'para este período.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.black,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilteredCollectionEmptyCard extends StatelessWidget {
  const _FilteredCollectionEmptyCard({required this.onClearFilters});

  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.fuchsia.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            color: AppColors.fuchsia,
            size: 54,
          ),
          const SizedBox(height: 14),
          const Text(
            'No encontramos jugadores',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.black,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Prueba cambiando la búsqueda '
            'o el filtro seleccionado.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF81747A),
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onClearFilters,
            icon: const Icon(Icons.filter_alt_off_rounded),
            label: const Text(
              'LIMPIAR FILTROS',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionErrorCard extends StatelessWidget {
  const _CollectionErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8A2525),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 15),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('REINTENTAR'),
          ),
        ],
      ),
    );
  }
}

class _CollectionPeriodSelection {
  const _CollectionPeriodSelection({required this.year, required this.month});

  final int year;
  final int month;
}

class _CollectionPeriodSelectorSheet extends StatefulWidget {
  const _CollectionPeriodSelectorSheet({
    required this.selectedYear,
    required this.selectedMonth,
  });

  final int selectedYear;
  final int selectedMonth;

  @override
  State<_CollectionPeriodSelectorSheet> createState() {
    return _CollectionPeriodSelectorSheetState();
  }
}

class _CollectionPeriodSelectorSheetState
    extends State<_CollectionPeriodSelectorSheet> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();

    _year = widget.selectedYear;
    _month = widget.selectedMonth;
  }

  List<int> get _years {
    final int currentYear = DateTime.now().year;

    return List<int>.generate(7, (int index) => currentYear - 5 + index);
  }

  String _monthName(int month) {
    const List<String> months = <String>[
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];

    return months[month - 1];
  }

  void _apply() {
    Navigator.of(
      context,
    ).pop(_CollectionPeriodSelection(year: _year, month: _month));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.fuchsia,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Seleccionar período',
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),

            const SizedBox(height: 18),

            DropdownButtonFormField<int>(
              initialValue: _month,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Mes',
                prefixIcon: const Icon(Icons.calendar_today_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              items: List<int>.generate(12, (int index) => index + 1).map((
                int month,
              ) {
                return DropdownMenuItem<int>(
                  value: month,
                  child: Text(_monthName(month)),
                );
              }).toList(),
              onChanged: (int? value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _month = value;
                });
              },
            ),

            const SizedBox(height: 14),

            DropdownButtonFormField<int>(
              initialValue: _year,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Año',
                prefixIcon: const Icon(Icons.event_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              items: _years.map((int year) {
                return DropdownMenuItem<int>(value: year, child: Text('$year'));
              }).toList(),
              onChanged: (int? value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _year = value;
                });
              },
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: _apply,
                icon: const Icon(Icons.check_rounded),
                label: const Text(
                  'APLICAR PERÍODO',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.fuchsia,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
