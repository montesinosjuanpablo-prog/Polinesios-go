import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../repositories/payment_repository.dart';

class SchoolFinancialSummaryScreen extends StatefulWidget {
  const SchoolFinancialSummaryScreen({super.key});

  @override
  State<SchoolFinancialSummaryScreen> createState() {
    return _SchoolFinancialSummaryScreenState();
  }
}

class _SchoolFinancialSummaryScreenState
    extends State<SchoolFinancialSummaryScreen> {
  final PaymentRepository _repository = const PaymentRepository();

  late int _selectedYear;
  late int _selectedMonth;

  Map<String, dynamic>? _summary;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    final DateTime now = DateTime.now();

    _selectedYear = now.year;
    _selectedMonth = now.month;

    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final Map<String, dynamic> summary = await _repository
          .getSchoolManualFinancialSummary(
            year: _selectedYear,
            month: _selectedMonth,
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Error al cargar resumen financiero manual: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _summary = null;
        _isLoading = false;
        _errorMessage = 'No fue posible cargar el resumen financiero.';
      });
    }
  }

  Future<void> _selectPeriod() async {
    final _FinancialPeriodSelection? result =
        await showModalBottomSheet<_FinancialPeriodSelection>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (BuildContext context) {
            return _PeriodSelectorSheet(
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

    await _loadSummary();
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

    if (month < 1 || month > 12) {
      return 'Mes';
    }

    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2F4),
      appBar: AppBar(
        backgroundColor: AppColors.darkFuchsia,
        foregroundColor: Colors.white,
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Resumen financiero',
            maxLines: 1,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _isLoading ? null : _loadSummary,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.fuchsia,
        onRefresh: _loadSummary,
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
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPeriodSelector(),
        const SizedBox(height: 18),
        if (_isLoading)
          const _FinancialLoadingCard()
        else if (_errorMessage != null)
          _FinancialErrorCard(message: _errorMessage!, onRetry: _loadSummary)
        else if (_summary != null)
          _buildSummaryContent(_summary!),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: _isLoading ? null : _selectPeriod,
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
                    'Período financiero',
                    style: TextStyle(
                      color: Color(0xFF81747A),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_monthName(_selectedMonth)} $_selectedYear',
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

  Widget _buildSummaryContent(Map<String, dynamic> summary) {
    final double totalCollected = _toDouble(summary['total_collected']);

    final double qrCollected = _toDouble(summary['qr_collected']);

    final double cashCollected = _toDouble(summary['cash_collected']);

    final int paymentCount = _toInt(summary['payment_count']);

    final int playersWithPayments = _toInt(summary['players_with_payments']);

    final double qrPercentage = totalCollected <= 0
        ? 0
        : (qrCollected / totalCollected) * 100;

    final double cashPercentage = totalCollected <= 0
        ? 0
        : (cashCollected / totalCollected) * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MainFinancialCard(
          totalCollected: totalCollected,
          paymentCount: paymentCount,
          playersWithPayments: playersWithPayments,
        ),
        const SizedBox(height: 18),
        _PaymentMethodsCard(
          qrCollected: qrCollected,
          cashCollected: cashCollected,
          qrPercentage: qrPercentage,
          cashPercentage: cashPercentage,
        ),
        const SizedBox(height: 18),
        _PeriodActivityCard(
          paymentCount: paymentCount,
          playersWithPayments: playersWithPayments,
          hasMovement: paymentCount > 0,
        ),
      ],
    );
  }
}

class _MainFinancialCard extends StatelessWidget {
  const _MainFinancialCard({
    required this.totalCollected,
    required this.paymentCount,
    required this.playersWithPayments,
  });

  final double totalCollected;
  final int paymentCount;
  final int playersWithPayments;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.darkFuchsia, AppColors.fuchsia],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.fuchsia.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.account_balance_wallet_rounded,
            color: AppColors.yellow,
            size: 42,
          ),
          const SizedBox(height: 10),
          const Text(
            'Ingresos confirmados',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _formatMoney(totalCollected),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _MainFinancialMetric(
                  label: 'Pagos registrados',
                  value: '$paymentCount',
                ),
              ),
              Container(width: 1, height: 50, color: Colors.white24),
              Expanded(
                child: _MainFinancialMetric(
                  label: 'Jugadores',
                  value: '$playersWithPayments',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MainFinancialMetric extends StatelessWidget {
  const _MainFinancialMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.yellow,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodsCard extends StatelessWidget {
  const _PaymentMethodsCard({
    required this.qrCollected,
    required this.cashCollected,
    required this.qrPercentage,
    required this.cashPercentage,
  });

  final double qrCollected;
  final double cashCollected;
  final double qrPercentage;
  final double cashPercentage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              Icon(Icons.payments_rounded, color: AppColors.fuchsia),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Ingresos por método',
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = constraints.maxWidth < 520;

              final Widget qr = _PaymentMethodMetric(
                icon: Icons.qr_code_2_rounded,
                label: 'QR',
                amount: _formatMoney(qrCollected),
                percentage: qrPercentage,
              );

              final Widget cash = _PaymentMethodMetric(
                icon: Icons.payments_rounded,
                label: 'Efectivo',
                amount: _formatMoney(cashCollected),
                percentage: cashPercentage,
              );

              if (compact) {
                return Column(children: [qr, const SizedBox(height: 12), cash]);
              }

              return Row(
                children: [
                  Expanded(child: qr),
                  const SizedBox(width: 12),
                  Expanded(child: cash),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodMetric extends StatelessWidget {
  const _PaymentMethodMetric({
    required this.icon,
    required this.label,
    required this.amount,
    required this.percentage,
  });

  final IconData icon;
  final String label;
  final String amount;
  final double percentage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F3F5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.fuchsia.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.fuchsia),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF81747A),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  amount,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${percentage.toStringAsFixed(0)}% de lo recaudado',
                  style: const TextStyle(
                    color: AppColors.fuchsia,
                    fontSize: 11,
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

class _PeriodActivityCard extends StatelessWidget {
  const _PeriodActivityCard({
    required this.paymentCount,
    required this.playersWithPayments,
    required this.hasMovement,
  });

  final int paymentCount;
  final int playersWithPayments;
  final bool hasMovement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              Icon(Icons.receipt_long_rounded, color: AppColors.fuchsia),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Actividad del período',
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ActivityMetric(
            icon: Icons.payments_outlined,
            label: 'Pagos registrados',
            value: '$paymentCount',
          ),
          const SizedBox(height: 12),
          _ActivityMetric(
            icon: Icons.groups_rounded,
            label: 'Jugadores con pagos',
            value: '$playersWithPayments',
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: hasMovement
                  ? const Color(0xFF168A55).withValues(alpha: 0.08)
                  : AppColors.fuchsia.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              hasMovement
                  ? 'Este período tiene movimientos confirmados.'
                  : 'Todavía no existen pagos confirmados en este período.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: hasMovement
                    ? const Color(0xFF168A55)
                    : const Color(0xFF756970),
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityMetric extends StatelessWidget {
  const _ActivityMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F3F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.fuchsia),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.fuchsia,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancialLoadingCard extends StatelessWidget {
  const _FinancialLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 420,
      child: Center(child: CircularProgressIndicator(color: AppColors.fuchsia)),
    );
  }
}

class _FinancialErrorCard extends StatelessWidget {
  const _FinancialErrorCard({required this.message, required this.onRetry});

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

class _FinancialPeriodSelection {
  const _FinancialPeriodSelection({required this.year, required this.month});

  final int year;
  final int month;
}

class _PeriodSelectorSheet extends StatefulWidget {
  const _PeriodSelectorSheet({
    required this.selectedYear,
    required this.selectedMonth,
  });

  final int selectedYear;
  final int selectedMonth;

  @override
  State<_PeriodSelectorSheet> createState() {
    return _PeriodSelectorSheetState();
  }
}

class _PeriodSelectorSheetState extends State<_PeriodSelectorSheet> {
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
    ).pop(_FinancialPeriodSelection(year: _year, month: _month));
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

double _toDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _formatMoney(double amount) {
  final bool hasDecimals = amount != amount.roundToDouble();

  return hasDecimals
      ? '${amount.toStringAsFixed(2)} Bs'
      : '${amount.toStringAsFixed(0)} Bs';
}
