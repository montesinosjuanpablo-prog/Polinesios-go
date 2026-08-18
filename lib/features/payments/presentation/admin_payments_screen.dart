import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../players/data/player_service.dart';
import '../repositories/payment_repository.dart';
import 'school_financial_summary_screen.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key, this.refreshNotifier});

  final ValueNotifier<int>? refreshNotifier;

  @override
  State<AdminPaymentsScreen> createState() {
    return _AdminPaymentsScreenState();
  }
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  final PaymentRepository _repository = const PaymentRepository();

  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _payments = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _categories = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _trainingGroups = <Map<String, dynamic>>[];

  bool _loading = true;
  String? _error;

  String? _selectedCategoryId;
  String? _selectedTrainingGroupId;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();

    widget.refreshNotifier?.addListener(_handleExternalRefresh);
    _searchController.addListener(_handleSearchChanged);

    _loadPayments();
  }

  @override
  void didUpdateWidget(covariant AdminPaymentsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.refreshNotifier != widget.refreshNotifier) {
      oldWidget.refreshNotifier?.removeListener(_handleExternalRefresh);
      widget.refreshNotifier?.addListener(_handleExternalRefresh);
    }
  }

  @override
  void dispose() {
    widget.refreshNotifier?.removeListener(_handleExternalRefresh);
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();

    super.dispose();
  }

  void _handleExternalRefresh() {
    _loadPayments();
  }

  void _handleSearchChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> _loadPayments() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final List<dynamic> results =
          await Future.wait<dynamic>(<Future<dynamic>>[
            _repository.getSchoolManualPayments(),
            PlayerService.getCategories(),
            PlayerService.getTrainingGroups(),
          ]);

      final List<Map<String, dynamic>> payments =
          results[0] as List<Map<String, dynamic>>;

      final List<Map<String, dynamic>> categories =
          results[1] as List<Map<String, dynamic>>;

      final List<Map<String, dynamic>> trainingGroups =
          results[2] as List<Map<String, dynamic>>;

      if (!mounted) {
        return;
      }

      setState(() {
        _payments = payments;
        _categories = categories;
        _trainingGroups = trainingGroups;
        _normalizeSelectedFilters();
        _loading = false;
      });
    } catch (error) {
      debugPrint('Error al cargar pagos manuales: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _payments = <Map<String, dynamic>>[];
        _loading = false;
        _error = 'No fue posible cargar el registro de pagos.';
      });
    }
  }

  void _normalizeSelectedFilters() {
    if (_selectedCategoryId != null &&
        !_categoryOptions.any(
          (_FilterOption option) => option.id == _selectedCategoryId,
        )) {
      _selectedCategoryId = null;
    }

    if (_selectedTrainingGroupId != null &&
        !_trainingGroupOptions.any(
          (_FilterOption option) => option.id == _selectedTrainingGroupId,
        )) {
      _selectedTrainingGroupId = null;
    }
  }

  void _openFinancialSummary() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const SchoolFinancialSummaryScreen(),
      ),
    );
  }

  List<_FilterOption> get _categoryOptions {
    final List<_FilterOption> result = <_FilterOption>[];

    for (final Map<String, dynamic> category in _categories) {
      final String id = _readNullableText(category, 'id');
      final String name = _readNullableText(category, 'name');

      if (id.isEmpty || name.isEmpty) {
        continue;
      }

      result.add(_FilterOption(id: id, label: name));
    }

    result.sort(
      (_FilterOption a, _FilterOption b) =>
          a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    );

    return result;
  }

  List<_FilterOption> get _trainingGroupOptions {
    final List<_FilterOption> result = <_FilterOption>[];

    for (final Map<String, dynamic> group in _trainingGroups) {
      final String id = _readNullableText(group, 'id');
      final String name = _readNullableText(group, 'name');
      final String categoryId = _readNullableText(group, 'category_id');

      if (id.isEmpty || name.isEmpty) {
        continue;
      }

      if (_selectedCategoryId != null && categoryId != _selectedCategoryId) {
        continue;
      }

      result.add(_FilterOption(id: id, label: _displayTrainingGroup(name)));
    }

    result.sort(
      (_FilterOption a, _FilterOption b) =>
          a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    );

    return result;
  }

  List<Map<String, dynamic>> get _filteredPayments {
    final String search = _normalizeSearch(_searchController.text);

    final List<Map<String, dynamic>> result = _payments.where((
      Map<String, dynamic> payment,
    ) {
      if (search.isNotEmpty) {
        final String playerName = _normalizeSearch(
          _readNullableText(payment, 'player_name'),
        );

        final String playerCode = _normalizeSearch(
          _readNullableText(payment, 'player_code'),
        );

        if (!playerName.contains(search) && !playerCode.contains(search)) {
          return false;
        }
      }

      if (_selectedCategoryId != null &&
          _readNullableText(payment, 'category_id') != _selectedCategoryId) {
        return false;
      }

      if (_selectedTrainingGroupId != null &&
          _readNullableText(payment, 'training_group_id') !=
              _selectedTrainingGroupId) {
        return false;
      }

      if (_selectedDate != null) {
        final DateTime? paymentDate = _parseDate(payment['payment_date']);

        if (paymentDate == null || !_isSameDate(paymentDate, _selectedDate!)) {
          return false;
        }
      }

      return true;
    }).toList();

    result.sort((Map<String, dynamic> first, Map<String, dynamic> second) {
      final DateTime firstDate =
          _parseDate(first['payment_date']) ?? DateTime(1900);
      final DateTime secondDate =
          _parseDate(second['payment_date']) ?? DateTime(1900);

      final int byDate = secondDate.compareTo(firstDate);

      if (byDate != 0) {
        return byDate;
      }

      final DateTime firstCreated =
          _parseDate(first['created_at']) ?? DateTime(1900);
      final DateTime secondCreated =
          _parseDate(second['created_at']) ?? DateTime(1900);

      return secondCreated.compareTo(firstCreated);
    });

    return result;
  }

  double get _filteredTotal {
    return _filteredPayments.fold<double>(0, (
      double total,
      Map<String, dynamic> payment,
    ) {
      return total + _toDouble(payment['amount']);
    });
  }

  int get _filteredPlayerCount {
    final Set<String> playerIds = <String>{};

    for (final Map<String, dynamic> payment in _filteredPayments) {
      final String playerId = _readNullableText(payment, 'player_id');

      if (playerId.isNotEmpty) {
        playerIds.add(playerId);
      }
    }

    return playerIds.length;
  }

  bool get _hasActiveFilters {
    return _searchController.text.trim().isNotEmpty ||
        _selectedCategoryId != null ||
        _selectedTrainingGroupId != null ||
        _selectedDate != null;
  }

  void _clearFilters() {
    FocusScope.of(context).unfocus();

    _searchController.clear();

    setState(() {
      _selectedCategoryId = null;
      _selectedTrainingGroupId = null;
      _selectedDate = null;
    });
  }

  Future<void> _selectDate() async {
    final DateTime today = DateTime.now();

    final DateTime? result = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? today,
      firstDate: DateTime(today.year, 1, 1),
      lastDate: DateTime(today.year, today.month, today.day),
      helpText: 'Buscar pago por fecha',
      cancelText: 'CANCELAR',
      confirmText: 'SELECCIONAR',
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDate = result;
    });
  }

  void _clearSelectedDate() {
    setState(() {
      _selectedDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2F4),
      appBar: AppBar(
        backgroundColor: AppColors.darkFuchsia,
        foregroundColor: AppColors.white,
        title: const Text(
          'Pagos',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _loading ? null : _loadPayments,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.fuchsia),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _ErrorState(message: _error!, onRetry: _loadPayments),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.fuchsia,
      onRefresh: _loadPayments,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 34),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFinancialSummaryAccess(),
                  const SizedBox(height: 18),
                  _buildGeneralSummary(),
                  const SizedBox(height: 18),
                  _buildSearchAndFilters(),
                  const SizedBox(height: 18),
                  _buildResultsHeader(),
                  const SizedBox(height: 11),
                  if (_filteredPayments.isEmpty)
                    _buildEmptyState()
                  else
                    ..._filteredPayments.map((Map<String, dynamic> payment) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PaymentCard(payment: payment),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummaryAccess() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.fuchsia.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.fuchsia.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: AppColors.fuchsia,
                  size: 30,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumen financiero',
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Consulta los ingresos y el movimiento financiero de la escuela.',
                      style: TextStyle(
                        color: Color(0xFF81747A),
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: _openFinancialSummary,
              icon: const Icon(Icons.insights_rounded),
              label: const Text(
                'VER RESUMEN FINANCIERO',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.fuchsia,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralSummary() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.darkFuchsia, AppColors.fuchsia],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppColors.fuchsia.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_rounded,
            color: AppColors.yellow,
            size: 42,
          ),
          const SizedBox(height: 9),
          const Text(
            'Registro general de pagos',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Todos los pagos acreditados por administración.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 19),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: 'Pagos',
                  value: '${_payments.length}',
                ),
              ),
              Container(width: 1, height: 52, color: Colors.white24),
              Expanded(
                child: _SummaryMetric(
                  label: 'Jugadores',
                  value: '${_allPlayerCount()}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _allPlayerCount() {
    final Set<String> playerIds = <String>{};

    for (final Map<String, dynamic> payment in _payments) {
      final String playerId = _readNullableText(payment, 'player_id');

      if (playerId.isNotEmpty) {
        playerIds.add(playerId);
      }
    }

    return playerIds.length;
  }

  Widget _buildSearchAndFilters() {
    final List<_FilterOption> categories = _categoryOptions;
    final List<_FilterOption> groups = _trainingGroupOptions;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.fuchsia.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.search_rounded, color: AppColors.fuchsia),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Buscar pagos',
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (_hasActiveFilters)
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.filter_alt_off_rounded, size: 19),
                  label: const Text(
                    'LIMPIAR',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // BUSCADOR POR NOMBRE / CÓDIGO
          TextField(
            controller: _searchController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Jugador',
              hintText: 'Buscar por nombre o código',
              prefixIcon: const Icon(Icons.person_search_rounded),
              suffixIcon: _searchController.text.trim().isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Borrar búsqueda',
                      onPressed: _searchController.clear,
                      icon: const Icon(Icons.close_rounded),
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.fuchsia.withValues(alpha: 0.22),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.fuchsia,
                  width: 1.6,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // CATEGORÍA
          DropdownButtonFormField<String?>(
            initialValue: _selectedCategoryId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Categoría',
              prefixIcon: const Icon(Icons.sports_soccer_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            items: <DropdownMenuItem<String?>>[
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Todas las categorías'),
              ),
              ...categories.map((_FilterOption option) {
                return DropdownMenuItem<String?>(
                  value: option.id,
                  child: Text(option.label, overflow: TextOverflow.ellipsis),
                );
              }),
            ],
            onChanged: (String? value) {
              setState(() {
                _selectedCategoryId = value;

                if (_selectedTrainingGroupId != null &&
                    !_trainingGroupOptions.any(
                      (_FilterOption option) =>
                          option.id == _selectedTrainingGroupId,
                    )) {
                  _selectedTrainingGroupId = null;
                }
              });
            },
          ),

          const SizedBox(height: 14),

          // GRUPO
          DropdownButtonFormField<String?>(
            key: ValueKey<String>(
              'group-${_selectedCategoryId ?? 'all'}-'
              '${_selectedTrainingGroupId ?? 'all'}',
            ),
            initialValue: _selectedTrainingGroupId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Grupo',
              prefixIcon: const Icon(Icons.groups_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            items: <DropdownMenuItem<String?>>[
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Todos los grupos'),
              ),
              ...groups.map((_FilterOption option) {
                return DropdownMenuItem<String?>(
                  value: option.id,
                  child: Text(option.label, overflow: TextOverflow.ellipsis),
                );
              }),
            ],
            onChanged: (String? value) {
              setState(() {
                _selectedTrainingGroupId = value;
              });
            },
          ),

          const SizedBox(height: 14),

          // FECHA
          InkWell(
            onTap: _selectDate,
            borderRadius: BorderRadius.circular(16),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Fecha del pago',
                prefixIcon: const Icon(Icons.calendar_month_rounded),
                suffixIcon: _selectedDate == null
                    ? const Icon(Icons.expand_more_rounded)
                    : IconButton(
                        tooltip: 'Quitar fecha',
                        onPressed: _clearSelectedDate,
                        icon: const Icon(Icons.close_rounded),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _selectedDate == null
                    ? 'Todas las fechas'
                    : _formatDateLong(_selectedDate!),
                style: TextStyle(
                  color: _selectedDate == null
                      ? const Color(0xFF81747A)
                      : AppColors.black,
                  fontWeight: _selectedDate == null
                      ? FontWeight.w600
                      : FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pagos encontrados',
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${_filteredPayments.length} '
                '${_filteredPayments.length == 1 ? 'pago' : 'pagos'} · '
                '$_filteredPlayerCount '
                '${_filteredPlayerCount == 1 ? 'jugador' : 'jugadores'}',
                style: const TextStyle(
                  color: Color(0xFF81747A),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.yellow.withValues(alpha: 0.32),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _formatMoney(_filteredTotal),
            style: const TextStyle(
              color: AppColors.black,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.manage_search_rounded,
            color: AppColors.fuchsia,
            size: 58,
          ),
          const SizedBox(height: 13),
          Text(
            _payments.isEmpty
                ? 'Todavía no hay pagos registrados'
                : 'No encontramos pagos con estos filtros',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _payments.isEmpty
                ? 'Los pagos que acredites desde la ficha de cada jugador aparecerán aquí.'
                : 'Prueba cambiando el nombre, grupo, categoría o fecha seleccionada.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF81747A),
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_payments.isNotEmpty && _hasActiveFilters) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.filter_alt_off_rounded),
              label: const Text(
                'LIMPIAR FILTROS',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment});

  final Map<String, dynamic> payment;

  @override
  Widget build(BuildContext context) {
    final String playerName = _readNullableText(payment, 'player_name');

    final String playerCode = _readNullableText(payment, 'player_code');

    final String categoryName = _readNullableText(payment, 'category_name');

    final String groupName = _displayTrainingGroup(
      _readNullableText(payment, 'training_group_name'),
    );

    final String method = _readNullableText(
      payment,
      'payment_method',
    ).toLowerCase();

    final String notes = _readNullableText(payment, 'notes');

    final DateTime? paymentDate = _parseDate(payment['payment_date']);

    final double amount = _toDouble(payment['amount']);

    final bool isQr = method == 'qr';

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: AppColors.fuchsia.withValues(alpha: 0.13)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isQr
                      ? AppColors.fuchsia.withValues(alpha: 0.10)
                      : AppColors.yellow.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isQr ? Icons.qr_code_2_rounded : Icons.payments_rounded,
                  color: isQr ? AppColors.fuchsia : AppColors.black,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playerName.isEmpty ? 'Jugador' : playerName,
                      style: const TextStyle(
                        color: AppColors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (playerCode.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        playerCode,
                        style: const TextStyle(
                          color: Color(0xFF81747A),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _formatMoney(amount),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: AppColors.fuchsia,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              if (categoryName.isNotEmpty)
                _InfoChip(
                  icon: Icons.sports_soccer_rounded,
                  label: categoryName,
                ),
              if (groupName.isNotEmpty)
                _InfoChip(icon: Icons.groups_rounded, label: groupName),
              _InfoChip(
                icon: isQr ? Icons.qr_code_2_rounded : Icons.payments_rounded,
                label: isQr ? 'QR' : 'Efectivo',
                highlighted: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F3F5),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.fuchsia,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Fecha',
                  style: TextStyle(
                    color: Color(0xFF81747A),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  paymentDate == null
                      ? 'No registrada'
                      : _formatDate(paymentDate),
                  style: const TextStyle(
                    color: AppColors.black,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.notes_rounded,
                  color: Color(0xFF81747A),
                  size: 19,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    notes,
                    style: const TextStyle(
                      color: Color(0xFF756970),
                      fontSize: 12.5,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.yellow,
            fontSize: 23,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.fuchsia.withValues(alpha: 0.09)
            : const Color(0xFFF8F3F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: highlighted ? AppColors.fuchsia : const Color(0xFF756970),
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: highlighted ? AppColors.fuchsia : const Color(0xFF756970),
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_off_rounded, color: AppColors.fuchsia, size: 52),
        const SizedBox(height: 14),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.black,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('REINTENTAR'),
        ),
      ],
    );
  }
}

class _FilterOption {
  const _FilterOption({required this.id, required this.label});

  final String id;
  final String label;
}

String _readNullableText(Map<String, dynamic> map, String key) {
  return map[key]?.toString().trim() ?? '';
}

DateTime? _parseDate(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is DateTime) {
    return value;
  }

  return DateTime.tryParse(value.toString());
}

double _toDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0;
}

bool _isSameDate(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

String _formatDate(DateTime date) {
  final String day = date.day.toString().padLeft(2, '0');

  final String month = date.month.toString().padLeft(2, '0');

  return '$day/$month/${date.year}';
}

String _formatDateLong(DateTime date) {
  const List<String> months = <String>[
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  return '${date.day} de ${months[date.month - 1]} de ${date.year}';
}

String _formatMoney(double amount) {
  final bool hasDecimals = amount != amount.roundToDouble();

  return hasDecimals
      ? '${amount.toStringAsFixed(2)} Bs'
      : '${amount.toStringAsFixed(0)} Bs';
}

String _displayTrainingGroup(String value) {
  String result = value.trim();

  if (result.startsWith('Polinesios ')) {
    result = result.substring('Polinesios '.length);
  }

  return result;
}

String _normalizeSearch(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ñ', 'n');
}
