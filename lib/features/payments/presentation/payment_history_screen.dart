import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../players/models/player_model.dart';
import '../models/payment_history_item.dart';
import '../repositories/payment_repository.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({required this.player, super.key});

  final PlayerModel player;

  @override
  State<PaymentHistoryScreen> createState() {
    return _PaymentHistoryScreenState();
  }
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final PaymentRepository _repository = const PaymentRepository();

  final TextEditingController _searchController = TextEditingController();

  List<PaymentHistoryItem> _items = <PaymentHistoryItem>[];

  bool _isLoading = true;
  String? _errorMessage;

  String _selectedPeriod = 'all';
  String _selectedStatus = 'all';
  String _selectedMethod = 'all';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<PaymentHistoryItem> result = await _repository
          .getPlayerPaymentHistory(widget.player.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _items = result;
        _isLoading = false;

        if (!_availablePeriods.contains(_selectedPeriod)) {
          _selectedPeriod = 'all';
        }

        if (!_availableMethods.contains(_selectedMethod)) {
          _selectedMethod = 'all';
        }
      });
    } catch (error) {
      debugPrint('Error al cargar historial de pagos: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'No fue posible cargar el historial de pagos.';
      });
    }
  }

  List<String> get _availablePeriods {
    final Map<String, int> periods = <String, int>{};

    for (final PaymentHistoryItem item in _items) {
      final int orderValue = (item.chargeYear * 100) + item.chargeMonth;

      periods[item.periodLabel] = orderValue;
    }

    final List<MapEntry<String, int>> entries = periods.entries.toList()
      ..sort((MapEntry<String, int> a, MapEntry<String, int> b) {
        return b.value.compareTo(a.value);
      });

    return <String>[
      'all',
      ...entries.map((MapEntry<String, int> entry) => entry.key),
    ];
  }

  List<String> get _availableMethods {
    final List<String> methods = _items
        .map((PaymentHistoryItem item) => item.paymentMethod)
        .where((String value) => value.trim().isNotEmpty)
        .toSet()
        .toList();

    methods.sort((String a, String b) {
      return _methodLabelFromCode(a).compareTo(_methodLabelFromCode(b));
    });

    return <String>['all', ...methods];
  }

  List<PaymentHistoryItem> get _filteredItems {
    final String query = _normalizeForSearch(_searchController.text);

    return _items.where((PaymentHistoryItem item) {
      final bool matchesPeriod =
          _selectedPeriod == 'all' || item.periodLabel == _selectedPeriod;

      final bool matchesStatus =
          _selectedStatus == 'all' || item.paymentStatus == _selectedStatus;

      final bool matchesMethod =
          _selectedMethod == 'all' || item.paymentMethod == _selectedMethod;

      if (!matchesPeriod || !matchesStatus || !matchesMethod) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final String searchableText = <String>[
        item.periodLabel,
        item.concept,
        item.amountLabel,
        item.methodLabel,
        item.statusLabel,
        _formatDate(item.paymentDate),
        item.transactionReference ?? '',
        item.notes ?? '',
      ].join(' ');

      return _normalizeForSearch(searchableText).contains(query);
    }).toList();
  }

  Map<String, List<PaymentHistoryItem>> _groupItemsByPeriod(
    List<PaymentHistoryItem> items,
  ) {
    final Map<String, List<PaymentHistoryItem>> grouped =
        <String, List<PaymentHistoryItem>>{};

    for (final PaymentHistoryItem item in items) {
      grouped.putIfAbsent(item.periodLabel, () => <PaymentHistoryItem>[]);

      grouped[item.periodLabel]!.add(item);
    }

    return grouped;
  }

  bool get _hasActiveFilters {
    return _searchController.text.trim().isNotEmpty ||
        _selectedPeriod != 'all' ||
        _selectedStatus != 'all' ||
        _selectedMethod != 'all';
  }

  void _clearFilters() {
    FocusScope.of(context).unfocus();

    _searchController.clear();

    setState(() {
      _selectedPeriod = 'all';
      _selectedStatus = 'all';
      _selectedMethod = 'all';
    });
  }

  String _normalizeForSearch(String value) {
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

  String _methodLabelFromCode(String code) {
    switch (code) {
      case 'qr':
        return 'QR';

      case 'cash':
        return 'Efectivo';

      case 'bank_transfer':
        return 'Transferencia';

      case 'other':
        return 'Otro';

      default:
        return code;
    }
  }

  String _statusFilterLabel(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmados';

      case 'rejected':
        return 'Rechazados';

      case 'pending_verification':
        return 'Pendientes';

      case 'cancelled':
        return 'Cancelados';

      default:
        return status;
    }
  }

  void _showReceipt(PaymentHistoryItem item) {
    final String receiptUrl = item.receiptUrl?.trim() ?? '';

    if (receiptUrl.isEmpty) {
      _showMessage('Este movimiento no tiene comprobante disponible.');
      return;
    }

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(18),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
                  decoration: const BoxDecoration(
                    color: AppColors.darkFuchsia,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(22),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.receipt_long_rounded,
                        color: AppColors.yellow,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${item.periodLabel} · '
                          '${item.amountLabel}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 5,
                    child: Image.network(
                      receiptUrl,
                      fit: BoxFit.contain,
                      loadingBuilder:
                          (
                            BuildContext context,
                            Widget child,
                            ImageChunkEvent? progress,
                          ) {
                            if (progress == null) {
                              return child;
                            }

                            return const SizedBox(
                              height: 420,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.fuchsia,
                                ),
                              ),
                            );
                          },
                      errorBuilder:
                          (
                            BuildContext context,
                            Object error,
                            StackTrace? stackTrace,
                          ) {
                            return const SizedBox(
                              height: 420,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.broken_image_rounded,
                                      size: 50,
                                      color: AppColors.fuchsia,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'No fue posible mostrar '
                                      'el comprobante.',
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.fuchsia,
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
  }

  Color _statusColor(PaymentHistoryItem item) {
    if (item.isConfirmed) {
      return const Color(0xFF168A55);
    }

    if (item.isRejected) {
      return const Color(0xFFC62828);
    }

    if (item.isPending) {
      return const Color(0xFFE59A00);
    }

    return const Color(0xFF777777);
  }

  IconData _statusIcon(PaymentHistoryItem item) {
    if (item.isConfirmed) {
      return Icons.verified_rounded;
    }

    if (item.isRejected) {
      return Icons.cancel_rounded;
    }

    if (item.isPending) {
      return Icons.schedule_rounded;
    }

    return Icons.info_outline_rounded;
  }

  String _formatDate(DateTime date) {
    final DateTime local = date.toLocal();

    final String day = local.day.toString().padLeft(2, '0');

    final String month = local.month.toString().padLeft(2, '0');

    return '$day/$month/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2F4),
      appBar: AppBar(
        backgroundColor: AppColors.darkFuchsia,
        foregroundColor: Colors.white,
        title: const Text(
          'Historial de pagos',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadHistory,
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.fuchsia,
          onRefresh: _loadHistory,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 34),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 850),
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
    if (_isLoading) {
      return const SizedBox(
        height: 420,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.fuchsia),
        ),
      );
    }

    if (_errorMessage != null) {
      return _HistoryErrorCard(message: _errorMessage!, onRetry: _loadHistory);
    }

    final List<PaymentHistoryItem> filteredItems = _filteredItems;

    final Map<String, List<PaymentHistoryItem>> groupedItems =
        _groupItemsByPeriod(filteredItems);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PlayerHistoryHeader(player: widget.player, movements: _items.length),

        const SizedBox(height: 18),

        if (_items.isNotEmpty) ...[
          _HistoryFiltersCard(
            searchController: _searchController,
            selectedPeriod: _selectedPeriod,
            selectedStatus: _selectedStatus,
            selectedMethod: _selectedMethod,
            periods: _availablePeriods,
            methods: _availableMethods,
            hasActiveFilters: _hasActiveFilters,
            resultCount: filteredItems.length,
            onSearchChanged: (String value) {
              setState(() {});
            },
            onPeriodChanged: (String? value) {
              if (value == null) {
                return;
              }

              setState(() {
                _selectedPeriod = value;
              });
            },
            onStatusChanged: (String? value) {
              if (value == null) {
                return;
              }

              setState(() {
                _selectedStatus = value;
              });
            },
            onMethodChanged: (String? value) {
              if (value == null) {
                return;
              }

              setState(() {
                _selectedMethod = value;
              });
            },
            onClearFilters: _clearFilters,
            methodLabel: _methodLabelFromCode,
            statusLabel: _statusFilterLabel,
          ),

          const SizedBox(height: 18),
        ],

        if (_items.isEmpty)
          const _EmptyHistoryCard()
        else if (filteredItems.isEmpty)
          _FilteredEmptyHistoryCard(onClearFilters: _clearFilters)
        else
          ..._buildGroupedHistory(groupedItems),
      ],
    );
  }

  List<Widget> _buildGroupedHistory(
    Map<String, List<PaymentHistoryItem>> groupedItems,
  ) {
    final List<Widget> widgets = <Widget>[];

    for (final MapEntry<String, List<PaymentHistoryItem>> entry
        in groupedItems.entries) {
      widgets.add(
        _MonthGroupHeader(period: entry.key, movements: entry.value.length),
      );

      widgets.add(const SizedBox(height: 12));

      widgets.add(_MonthFinancialSummary(items: entry.value));

      widgets.add(const SizedBox(height: 12));

      for (final PaymentHistoryItem item in entry.value) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildHistoryCard(item),
          ),
        );
      }

      widgets.add(const SizedBox(height: 6));
    }

    return widgets;
  }

  Widget _buildHistoryCard(PaymentHistoryItem item) {
    final Color statusColor = _statusColor(item);

    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: statusColor.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 7),
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
                  color: AppColors.fuchsia.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  item.paymentMethod == 'cash'
                      ? Icons.payments_rounded
                      : Icons.qr_code_2_rounded,
                  color: AppColors.fuchsia,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.concept,
                      style: const TextStyle(
                        color: AppColors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.methodLabel,
                      style: const TextStyle(
                        color: Color(0xFF81747A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item.amountLabel,
                style: const TextStyle(
                  color: AppColors.fuchsia,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
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
                _HistoryInfoRow(label: 'Período', value: item.periodLabel),
                const SizedBox(height: 9),
                _HistoryInfoRow(label: 'Método', value: item.methodLabel),
                const SizedBox(height: 9),
                _HistoryInfoRow(
                  label: 'Fecha',
                  value: _formatDate(item.paymentDate),
                ),
                if (item.transactionReference != null) ...[
                  const SizedBox(height: 9),
                  _HistoryInfoRow(
                    label: 'Referencia',
                    value: item.transactionReference!,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_statusIcon(item), color: statusColor, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    item.statusLabel.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (item.hasNotes) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes_rounded, color: statusColor, size: 19),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      item.notes!,
                      style: const TextStyle(
                        color: Color(0xFF62575C),
                        fontSize: 12.5,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (item.hasReceipt) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  _showReceipt(item);
                },
                icon: const Icon(Icons.visibility_rounded),
                label: const Text(
                  'VER COMPROBANTE',
                  style: TextStyle(fontWeight: FontWeight.w900),
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
        ],
      ),
    );
  }
}

class _MonthGroupHeader extends StatelessWidget {
  const _MonthGroupHeader({required this.period, required this.movements});

  final String period;
  final int movements;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.darkFuchsia, AppColors.fuchsia],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.fuchsia.withValues(alpha: 0.13),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.yellow,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: AppColors.black,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  period.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  movements == 1 ? '1 movimiento' : '$movements movimientos',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 35, minHeight: 35),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$movements',
              style: const TextStyle(
                color: AppColors.yellow,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthFinancialSummary extends StatelessWidget {
  const _MonthFinancialSummary({required this.items});

  final List<PaymentHistoryItem> items;

  double get _confirmedAmount {
    return items
        .where((PaymentHistoryItem item) => item.isConfirmed)
        .fold<double>(
          0,
          (double total, PaymentHistoryItem item) => total + item.paymentAmount,
        );
  }

  double get _pendingAmount {
    return items
        .where((PaymentHistoryItem item) => item.isPending)
        .fold<double>(
          0,
          (double total, PaymentHistoryItem item) => total + item.paymentAmount,
        );
  }

  int get _rejectedCount {
    return items.where((PaymentHistoryItem item) => item.isRejected).length;
  }

  double get _cashConfirmedAmount {
    return items
        .where(
          (PaymentHistoryItem item) =>
              item.isConfirmed && item.paymentMethod == 'cash',
        )
        .fold<double>(
          0,
          (double total, PaymentHistoryItem item) => total + item.paymentAmount,
        );
  }

  double get _qrConfirmedAmount {
    return items
        .where(
          (PaymentHistoryItem item) =>
              item.isConfirmed && item.paymentMethod == 'qr',
        )
        .fold<double>(
          0,
          (double total, PaymentHistoryItem item) => total + item.paymentAmount,
        );
  }

  String _amountLabel(double amount) {
    final bool isWholeNumber = amount == amount.roundToDouble();

    final String value = isWholeNumber
        ? amount.toInt().toString()
        : amount.toStringAsFixed(2);

    return '$value Bs';
  }

  @override
  Widget build(BuildContext context) {
    final double confirmedAmount = _confirmedAmount;
    final double pendingAmount = _pendingAmount;
    final int rejectedCount = _rejectedCount;
    final double cashConfirmedAmount = _cashConfirmedAmount;
    final double qrConfirmedAmount = _qrConfirmedAmount;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.fuchsia.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                color: AppColors.fuchsia,
                size: 22,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Resumen financiero del período',
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _FinancialSummaryRow(
            icon: Icons.verified_rounded,
            label: 'Confirmado',
            value: _amountLabel(confirmedAmount),
            color: const Color(0xFF168A55),
          ),
          if (pendingAmount > 0) ...[
            const SizedBox(height: 10),
            _FinancialSummaryRow(
              icon: Icons.schedule_rounded,
              label: 'Pendiente de revisión',
              value: _amountLabel(pendingAmount),
              color: const Color(0xFFE59A00),
            ),
          ],
          if (rejectedCount > 0) ...[
            const SizedBox(height: 10),
            _FinancialSummaryRow(
              icon: Icons.cancel_rounded,
              label: rejectedCount == 1
                  ? 'Comprobante rechazado'
                  : 'Comprobantes rechazados',
              value: '$rejectedCount',
              color: const Color(0xFFC62828),
            ),
          ],
          if (cashConfirmedAmount > 0 || qrConfirmedAmount > 0) ...[
            const SizedBox(height: 14),
            Divider(
              height: 1,
              color: AppColors.fuchsia.withValues(alpha: 0.12),
            ),
            const SizedBox(height: 13),
            const Text(
              'Ingresos confirmados por método',
              style: TextStyle(
                color: Color(0xFF81747A),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            if (cashConfirmedAmount > 0)
              _FinancialSummaryRow(
                icon: Icons.payments_rounded,
                label: 'Efectivo',
                value: _amountLabel(cashConfirmedAmount),
                color: const Color(0xFF168A55),
                compact: true,
              ),
            if (cashConfirmedAmount > 0 && qrConfirmedAmount > 0)
              const SizedBox(height: 8),
            if (qrConfirmedAmount > 0)
              _FinancialSummaryRow(
                icon: Icons.qr_code_2_rounded,
                label: 'QR',
                value: _amountLabel(qrConfirmedAmount),
                color: AppColors.fuchsia,
                compact: true,
              ),
          ],
        ],
      ),
    );
  }
}

class _FinancialSummaryRow extends StatelessWidget {
  const _FinancialSummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 11 : 12,
        vertical: compact ? 9 : 11,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: compact ? 0.055 : 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 31 : 34,
            height: compact ? 31 : 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: compact ? 17 : 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: compact ? const Color(0xFF62575C) : AppColors.black,
                fontSize: compact ? 12.5 : 13.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: color,
              fontSize: compact ? 13 : 14.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryFiltersCard extends StatelessWidget {
  const _HistoryFiltersCard({
    required this.searchController,
    required this.selectedPeriod,
    required this.selectedStatus,
    required this.selectedMethod,
    required this.periods,
    required this.methods,
    required this.hasActiveFilters,
    required this.resultCount,
    required this.onSearchChanged,
    required this.onPeriodChanged,
    required this.onStatusChanged,
    required this.onMethodChanged,
    required this.onClearFilters,
    required this.methodLabel,
    required this.statusLabel,
  });

  final TextEditingController searchController;

  final String selectedPeriod;
  final String selectedStatus;
  final String selectedMethod;

  final List<String> periods;
  final List<String> methods;

  final bool hasActiveFilters;
  final int resultCount;

  final ValueChanged<String> onSearchChanged;

  final ValueChanged<String?> onPeriodChanged;

  final ValueChanged<String?> onStatusChanged;

  final ValueChanged<String?> onMethodChanged;

  final VoidCallback onClearFilters;

  final String Function(String) methodLabel;

  final String Function(String) statusLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.fuchsia.withValues(alpha: 0.14)),
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
          const Row(
            children: [
              Icon(Icons.filter_alt_rounded, color: AppColors.fuchsia),
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
            controller: searchController,
            onChanged: onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: 'Buscar movimiento',
              hintText: 'Ej.: Agosto, QR, ilegible...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: searchController.text.trim().isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpiar búsqueda',
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.fuchsia.withValues(alpha: 0.25),
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

          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = constraints.maxWidth < 620;

              if (compact) {
                return Column(
                  children: [
                    _HistoryDropdown(
                      label: 'Período',
                      icon: Icons.calendar_month_rounded,
                      value: selectedPeriod,
                      items: periods
                          .map(
                            (String value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value == 'all' ? 'Todos los períodos' : value,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: onPeriodChanged,
                    ),
                    const SizedBox(height: 12),
                    _HistoryDropdown(
                      label: 'Estado',
                      icon: Icons.verified_outlined,
                      value: selectedStatus,
                      items:
                          <String>[
                            'all',
                            'confirmed',
                            'pending_verification',
                            'rejected',
                            'cancelled',
                          ].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value == 'all'
                                    ? 'Todos los estados'
                                    : statusLabel(value),
                              ),
                            );
                          }).toList(),
                      onChanged: onStatusChanged,
                    ),
                    const SizedBox(height: 12),
                    _HistoryDropdown(
                      label: 'Método',
                      icon: Icons.payments_outlined,
                      value: selectedMethod,
                      items: methods.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value == 'all'
                                ? 'Todos los métodos'
                                : methodLabel(value),
                          ),
                        );
                      }).toList(),
                      onChanged: onMethodChanged,
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _HistoryDropdown(
                      label: 'Período',
                      icon: Icons.calendar_month_rounded,
                      value: selectedPeriod,
                      items: periods
                          .map(
                            (String value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(value == 'all' ? 'Todos' : value),
                            ),
                          )
                          .toList(),
                      onChanged: onPeriodChanged,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _HistoryDropdown(
                      label: 'Estado',
                      icon: Icons.verified_outlined,
                      value: selectedStatus,
                      items:
                          <String>[
                            'all',
                            'confirmed',
                            'pending_verification',
                            'rejected',
                            'cancelled',
                          ].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value == 'all' ? 'Todos' : statusLabel(value),
                              ),
                            );
                          }).toList(),
                      onChanged: onStatusChanged,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _HistoryDropdown(
                      label: 'Método',
                      icon: Icons.payments_outlined,
                      value: selectedMethod,
                      items: methods.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value == 'all' ? 'Todos' : methodLabel(value),
                          ),
                        );
                      }).toList(),
                      onChanged: onMethodChanged,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 15),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.fuchsia.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.fuchsia,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    resultCount == 1
                        ? '1 movimiento encontrado'
                        : '$resultCount movimientos encontrados',
                    style: const TextStyle(
                      color: AppColors.fuchsia,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (hasActiveFilters) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onClearFilters,
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
}

class _HistoryDropdown extends StatelessWidget {
  const _HistoryDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final String value;

  final List<DropdownMenuItem<String>> items;

  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey<String>('$label-$value'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: AppColors.fuchsia.withValues(alpha: 0.22),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.fuchsia, width: 1.5),
        ),
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}

class _PlayerHistoryHeader extends StatelessWidget {
  const _PlayerHistoryHeader({required this.player, required this.movements});

  final PlayerModel player;
  final int movements;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.darkFuchsia, AppColors.fuchsia],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: AppColors.yellow,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            alignment: Alignment.center,
            child: Text(
              player.initials.isEmpty ? '?' : player.initials,
              style: const TextStyle(
                color: AppColors.black,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Código: '
                  '${player.playerCode}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  movements == 1
                      ? '1 movimiento registrado'
                      : '$movements movimientos registrados',
                  style: const TextStyle(
                    color: AppColors.yellow,
                    fontWeight: FontWeight.w800,
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

class _HistoryInfoRow extends StatelessWidget {
  const _HistoryInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
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
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyHistoryCard extends StatelessWidget {
  const _EmptyHistoryCard();

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
          Icon(Icons.history_rounded, color: AppColors.fuchsia, size: 58),
          SizedBox(height: 14),
          Text(
            'Todavía no existen movimientos de pago.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _FilteredEmptyHistoryCard extends StatelessWidget {
  const _FilteredEmptyHistoryCard({required this.onClearFilters});

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
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.fuchsia.withValues(alpha: 0.09),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: AppColors.fuchsia,
              size: 37,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No encontramos movimientos',
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
            'o alguno de los filtros.',
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
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.fuchsia,
              side: const BorderSide(color: AppColors.fuchsia),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryErrorCard extends StatelessWidget {
  const _HistoryErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withValues(alpha: 0.20)),
      ),
      child: Column(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 42),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8A2525),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('REINTENTAR'),
          ),
        ],
      ),
    );
  }
}
