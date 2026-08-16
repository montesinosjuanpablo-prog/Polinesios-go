import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
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

  List<Map<String, dynamic>> _payments = <Map<String, dynamic>>[];

  bool _loading = true;

  String? _error;
  String? _processingPaymentId;

  String _filter = 'pending_verification';

  @override
  void initState() {
    super.initState();

    widget.refreshNotifier?.addListener(_handleExternalRefresh);

    _loadPayments();
  }

  void _handleExternalRefresh() {
    _loadPayments();
  }

  void _openFinancialSummary() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const SchoolFinancialSummaryScreen(),
      ),
    );
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

    super.dispose();
  }

  Future<void> _loadPayments() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final List<Map<String, dynamic>> payments = await _repository
          .getQrPaymentsForAdmin();

      if (!mounted) {
        return;
      }

      setState(() {
        _payments = payments;
      });
    } catch (error) {
      debugPrint('Error al cargar pagos QR: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _error = 'No fue posible cargar los pagos QR.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredPayments {
    if (_filter == 'all') {
      return _payments;
    }

    return _payments.where((Map<String, dynamic> payment) {
      return _paymentStatus(payment) == _filter;
    }).toList();
  }

  int _countByStatus(String status) {
    return _payments.where((Map<String, dynamic> payment) {
      return _paymentStatus(payment) == status;
    }).length;
  }

  Future<void> _approvePayment(Map<String, dynamic> payment) async {
    final String paymentId = _paymentId(payment);

    if (paymentId.isEmpty) {
      _showMessage(
        message: 'El pago no tiene un identificador válido.',
        isError: true,
      );

      return;
    }

    final bool confirmed = await _showConfirmationDialog(
      title: 'Confirmar pago QR',
      message:
          '¿Confirmas que el comprobante de '
          '${_readText(payment, 'player_name')} '
          'es correcto y que el dinero fue recibido?',
      confirmText: 'CONFIRMAR',
      confirmColor: const Color(0xFF168A55),
    );

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _processingPaymentId = paymentId;
    });

    try {
      final Map<String, dynamic> result = await _repository.confirmQrPayment(
        paymentRecordId: paymentId,
        notes: 'Pago QR confirmado por administración.',
      );

      if (!mounted) {
        return;
      }

      final double remainingAmount = _toDouble(result['remaining_amount']);

      final String chargeStatus =
          result['charge_status']?.toString().trim() ?? '';

      if (chargeStatus == 'paid' || remainingAmount <= 0) {
        _showMessage(
          message:
              'Pago confirmado. La mensualidad '
              'quedó completamente pagada.',
        );
      } else {
        _showMessage(
          message:
              'Pago confirmado correctamente. '
              'Saldo pendiente: '
              '${_formatAmount(remainingAmount)}.',
        );
      }

      await _loadPayments();
    } catch (error) {
      debugPrint('Error al confirmar pago QR: $error');

      if (!mounted) {
        return;
      }

      _showMessage(message: _adminPaymentErrorMessage(error), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _processingPaymentId = null;
        });
      }
    }
  }

  Future<void> _rejectPayment(Map<String, dynamic> payment) async {
    final String paymentId = _paymentId(payment);

    if (paymentId.isEmpty) {
      _showMessage(
        message: 'El pago no tiene un identificador válido.',
        isError: true,
      );

      return;
    }

    final String? notes = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _RejectQrPaymentDialog(
          playerName: _readText(payment, 'player_name'),
        );
      },
    );

    if (notes == null || !mounted) {
      return;
    }

    setState(() {
      _processingPaymentId = paymentId;
    });

    try {
      await _repository.rejectQrPayment(
        paymentRecordId: paymentId,
        notes: notes,
      );

      if (!mounted) {
        return;
      }

      _showMessage(message: 'Pago QR rechazado correctamente.');

      await _loadPayments();
    } catch (error) {
      debugPrint('Error al rechazar pago QR: $error');

      if (!mounted) {
        return;
      }

      _showMessage(message: _adminPaymentErrorMessage(error), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _processingPaymentId = null;
        });
      }
    }
  }

  void _showReceipt(Map<String, dynamic> payment) {
    final String receiptUrl = payment['receipt_url']?.toString().trim() ?? '';

    if (receiptUrl.isEmpty) {
      _showMessage(
        message: 'Este pago no tiene comprobante disponible.',
        isError: true,
      );

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
                          _readText(payment, 'player_name'),
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

  Future<bool> _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text(
            message,
            style: const TextStyle(height: 1.4, fontWeight: FontWeight.w600),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(
                'CANCELAR',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: confirmColor,
                foregroundColor: Colors.white,
              ),
              child: Text(
                confirmText,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  String _paymentId(Map<String, dynamic> payment) {
    return payment['payment_record_id']?.toString().trim() ?? '';
  }

  String _paymentStatus(Map<String, dynamic> payment) {
    return payment['payment_status']?.toString().trim().toLowerCase() ?? '';
  }

  String _readText(Map<String, dynamic> payment, String key) {
    final String value = payment[key]?.toString().trim() ?? '';

    return value.isEmpty ? 'No registrado' : value;
  }

  String _paymentPeriod(Map<String, dynamic> payment) {
    final int year = _toInt(payment['charge_year']);

    final int month = _toInt(payment['charge_month']);

    return '${_monthName(month)} $year';
  }

  String _formatDate(dynamic rawDate) {
    final DateTime? date = DateTime.tryParse(rawDate?.toString() ?? '');

    if (date == null) {
      return 'No registrada';
    }

    final String day = date.day.toString().padLeft(2, '0');

    final String month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _formatAmount(dynamic rawAmount) {
    final double amount = _toDouble(rawAmount);

    final bool hasDecimals = amount != amount.roundToDouble();

    return hasDecimals
        ? '${amount.toStringAsFixed(2)} Bs'
        : '${amount.toStringAsFixed(0)} Bs';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'confirmed':
        return 'CONFIRMADO';

      case 'rejected':
        return 'RECHAZADO';

      case 'cancelled':
        return 'CANCELADO';

      case 'pending_verification':
      default:
        return 'PENDIENTE';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return const Color(0xFF168A55);

      case 'rejected':
        return const Color(0xFFC62828);

      case 'cancelled':
        return const Color(0xFF777777);

      case 'pending_verification':
      default:
        return const Color(0xFFE59A00);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'confirmed':
        return Icons.verified_rounded;

      case 'rejected':
        return Icons.cancel_rounded;

      case 'cancelled':
        return Icons.block_rounded;

      case 'pending_verification':
      default:
        return Icons.schedule_rounded;
    }
  }

  void _showMessage({required String message, bool isError = false}) {
    if (!mounted) {
      return;
    }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2F4),
      appBar: AppBar(
        backgroundColor: AppColors.darkFuchsia,
        foregroundColor: Colors.white,
        title: const Text(
          'Pagos QR',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _loading ? null : _loadPayments,
            icon: const Icon(Icons.refresh_rounded),
          ),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.fuchsia,
                size: 52,
              ),
              const SizedBox(height: 14),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _loadPayments,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('REINTENTAR'),
              ),
            ],
          ),
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
                  _buildSummary(),
                  const SizedBox(height: 18),
                  _buildFilters(),
                  const SizedBox(height: 18),
                  if (_filteredPayments.isEmpty)
                    _buildEmptyState()
                  else
                    ..._filteredPayments.map(_buildPaymentCard),
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
        color: Colors.white,
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
                      'Consulta ingresos, saldos pendientes, '
                      'métodos de pago y estado de cobranza.',
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
                foregroundColor: Colors.white,
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

  Widget _buildSummary() {
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
      child: Column(
        children: [
          const Icon(
            Icons.qr_code_2_rounded,
            color: AppColors.yellow,
            size: 42,
          ),
          const SizedBox(height: 10),
          const Text(
            'Revisión de pagos QR',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Confirma o rechaza los comprobantes '
            'reportados.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _SummaryBadge(
                label: 'Pendientes',
                value: _countByStatus('pending_verification'),
                color: const Color(0xFFFFC107),
              ),
              _SummaryBadge(
                label: 'Confirmados',
                value: _countByStatus('confirmed'),
                color: const Color(0xFF6ED5A1),
              ),
              _SummaryBadge(
                label: 'Rechazados',
                value: _countByStatus('rejected'),
                color: const Color(0xFFFF9A9A),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'PENDIENTES',
            selected: _filter == 'pending_verification',
            onTap: () {
              setState(() {
                _filter = 'pending_verification';
              });
            },
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'CONFIRMADOS',
            selected: _filter == 'confirmed',
            onTap: () {
              setState(() {
                _filter = 'confirmed';
              });
            },
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'RECHAZADOS',
            selected: _filter == 'rejected',
            onTap: () {
              setState(() {
                _filter = 'rejected';
              });
            },
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'TODOS',
            selected: _filter == 'all',
            onTap: () {
              setState(() {
                _filter = 'all';
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.mark_email_read_rounded,
            color: AppColors.fuchsia,
            size: 58,
          ),
          SizedBox(height: 14),
          Text(
            'No hay pagos en esta sección',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final String paymentId = _paymentId(payment);

    final String status = _paymentStatus(payment);

    final bool isProcessing = _processingPaymentId == paymentId;

    final bool isPending = status == 'pending_verification';

    final Color statusColor = _statusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: statusColor.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(19),
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
                    color: AppColors.fuchsia.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.fuchsia,
                    size: 29,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _readText(payment, 'player_name'),
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Código: '
                        '${_readText(payment, 'player_code')}',
                        style: const TextStyle(
                          color: Color(0xFF756970),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _readText(payment, 'category_name'),
                        style: const TextStyle(
                          color: Color(0xFF756970),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F3F5),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _PaymentDetail(
                      label: 'Período',
                      value: _paymentPeriod(payment),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 42,
                    color: const Color(0xFFE1D7DC),
                  ),
                  Expanded(
                    child: _PaymentDetail(
                      label: 'Monto',
                      value: _formatAmount(payment['amount']),
                      valueColor: AppColors.fuchsia,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            _InfoRow(
              icon: Icons.event_rounded,
              label: 'Fecha reportada',
              value: _formatDate(payment['created_at']),
            ),

            if (_readText(payment, 'transaction_reference') !=
                'No registrado') ...[
              const SizedBox(height: 7),
              _InfoRow(
                icon: Icons.confirmation_number_outlined,
                label: 'Referencia',
                value: _readText(payment, 'transaction_reference'),
              ),
            ],

            const SizedBox(height: 15),

            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_statusIcon(status), color: statusColor, size: 19),
                    const SizedBox(width: 7),
                    Text(
                      _statusLabel(status),
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

            const SizedBox(height: 17),

            SizedBox(
              height: 49,
              child: OutlinedButton.icon(
                onPressed: isProcessing
                    ? null
                    : () {
                        _showReceipt(payment);
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

            if (isPending) ...[
              const SizedBox(height: 11),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool compact = constraints.maxWidth < 430;

                  final Widget approve = SizedBox(
                    height: 49,
                    child: FilledButton.icon(
                      onPressed: isProcessing
                          ? null
                          : () {
                              _approvePayment(payment);
                            },
                      icon: isProcessing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_rounded),
                      label: const Text(
                        'CONFIRMAR',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF168A55),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  );

                  final Widget reject = SizedBox(
                    height: 49,
                    child: OutlinedButton.icon(
                      onPressed: isProcessing
                          ? null
                          : () {
                              _rejectPayment(payment);
                            },
                      icon: const Icon(Icons.cancel_rounded),
                      label: const Text(
                        'RECHAZAR',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFC62828),
                        side: const BorderSide(color: Color(0xFFC62828)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  );

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [approve, const SizedBox(height: 10), reject],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: approve),
                      const SizedBox(width: 11),
                      Expanded(child: reject),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  const _SummaryBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: selected ? Colors.white : AppColors.fuchsia,
        ),
      ),
      selected: selected,
      selectedColor: AppColors.fuchsia,
      backgroundColor: Colors.white,
      side: const BorderSide(color: AppColors.fuchsia),
      onSelected: (_) {
        onTap();
      },
    );
  }
}

class _PaymentDetail extends StatelessWidget {
  const _PaymentDetail({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF81747A),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: valueColor ?? AppColors.black,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.fuchsia),
        const SizedBox(width: 7),
        Text(
          '$label: ',
          style: const TextStyle(
            color: Color(0xFF81747A),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _RejectQrPaymentDialog extends StatefulWidget {
  const _RejectQrPaymentDialog({required this.playerName});

  final String playerName;

  @override
  State<_RejectQrPaymentDialog> createState() {
    return _RejectQrPaymentDialogState();
  }
}

class _RejectQrPaymentDialogState extends State<_RejectQrPaymentDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  void _reject() {
    final String notes = _controller.text.trim();

    FocusScope.of(context).unfocus();

    Navigator.of(
      context,
    ).pop(notes.isEmpty ? 'Comprobante rechazado por administración.' : notes);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cancel_rounded, color: Color(0xFFC62828)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Rechazar pago QR',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Jugador: ${widget.playerName}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            minLines: 2,
            maxLines: 3,
            maxLength: 150,
            textCapitalization: TextCapitalization.sentences,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              labelText: 'Motivo u observación',
              hintText: 'Ej.: el monto no coincide.',
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            FocusScope.of(context).unfocus();

            Navigator.of(context).pop();
          },
          child: const Text(
            'CANCELAR',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        FilledButton(
          onPressed: _reject,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFC62828),
            foregroundColor: Colors.white,
          ),
          child: const Text(
            'RECHAZAR',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

double _toDouble(dynamic value) {
  if (value == null) {
    return 0;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString()) ?? 0;
}

int _toInt(dynamic value) {
  if (value == null) {
    return 0;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString()) ?? 0;
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

String _adminPaymentErrorMessage(Object error) {
  final String lower = error.toString().toLowerCase();

  if (lower.contains('solo un administrador')) {
    return 'Solo un administrador puede revisar pagos QR.';
  }

  if (lower.contains('ya fue revisado')) {
    return 'Este pago ya fue revisado anteriormente.';
  }

  if (lower.contains('supera el saldo pendiente')) {
    return 'El pago supera el saldo pendiente actual.';
  }

  if (lower.contains('mensualidad ya se encuentra completamente pagada')) {
    return 'La mensualidad ya está completamente pagada.';
  }

  if (lower.contains('no tienes autorización')) {
    return 'No tienes autorización para revisar este pago.';
  }

  return 'No fue posible procesar el pago QR.';
}
