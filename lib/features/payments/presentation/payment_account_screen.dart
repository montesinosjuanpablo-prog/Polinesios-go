import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../players/models/player_model.dart';
import '../models/payment_account_status.dart';
import '../repositories/payment_repository.dart';
import 'payment_qr_screen.dart';
import 'payment_history_screen.dart';

class PaymentAccountScreen extends StatefulWidget {
  const PaymentAccountScreen({required this.player, super.key});

  final PlayerModel player;

  @override
  State<PaymentAccountScreen> createState() {
    return _PaymentAccountScreenState();
  }
}

class _PaymentAccountScreenState extends State<PaymentAccountScreen> {
  final PaymentRepository _repository = const PaymentRepository();

  PaymentAccountStatus? _status;

  bool _isLoading = true;
  bool _isRegisteringCash = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAccountStatus();
  }

  void _openPaymentHistory() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PaymentHistoryScreen(player: widget.player),
      ),
    );
  }

  Future<void> _loadAccountStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final PaymentAccountStatus result = await _repository.getCurrentFee(
        widget.player.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _status = result;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage =
            'No fue posible obtener el estado de cuenta del jugador.';
      });
    }
  }

  void _openPaymentQr() {
    final PaymentAccountStatus? status = _status;

    if (status == null) {
      _showMessage('Todavía estamos cargando los datos del pago.');
      return;
    }

    if (status.isPaid) {
      _showMessage(
        'La mensualidad de ${status.displayPeriod} ya se encuentra pagada.',
      );
      return;
    }

    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PaymentQrScreen(
          playerId: status.playerId,
          playerName: status.playerName,
          categoryName: status.categoryName,
          amount: status.displayRemainingAmount,
        ),
      ),
    );
  }

  Future<void> _openCashPaymentDialog() async {
    final PaymentAccountStatus? status = _status;

    if (status == null || _isRegisteringCash) {
      return;
    }

    if (status.isPaid) {
      _showMessage(
        'La mensualidad de ${status.displayPeriod} ya se encuentra pagada.',
      );
      return;
    }

    final _CashPaymentRequest? request = await showDialog<_CashPaymentRequest>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _CashPaymentDialog(status: status);
      },
    );

    if (request == null || !mounted) {
      return;
    }

    await _confirmAndRegisterCashPayment(status: status, request: request);
  }

  Future<void> _confirmAndRegisterCashPayment({
    required PaymentAccountStatus status,
    required _CashPaymentRequest request,
  }) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Row(
            children: [
              Icon(Icons.payments_rounded, color: AppColors.fuchsia),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Confirmar pago',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Estás por registrar un pago en efectivo.',
                style: TextStyle(
                  color: Color(0xFF756970),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              _ConfirmationRow(label: 'Jugador', value: status.playerName),
              const SizedBox(height: 9),
              _ConfirmationRow(label: 'Período', value: status.displayPeriod),
              const SizedBox(height: 9),
              _ConfirmationRow(
                label: 'Monto',
                value: _formatMoney(request.amount),
              ),
              const SizedBox(height: 9),
              const _ConfirmationRow(label: 'Método', value: 'Efectivo'),
              if (request.notes != null) ...[
                const SizedBox(height: 9),
                _ConfirmationRow(label: 'Observación', value: request.notes!),
              ],
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.yellow.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'El pago quedará confirmado inmediatamente '
                  'por el administrador.',
                  style: TextStyle(
                    color: Color(0xFF6D5600),
                    fontSize: 12.5,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
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
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text(
                'CONFIRMAR',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.fuchsia,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _registerCashPayment(request);
  }

  Future<void> _registerCashPayment(_CashPaymentRequest request) async {
    if (_isRegisteringCash) {
      return;
    }

    setState(() {
      _isRegisteringCash = true;
    });

    try {
      final Map<String, dynamic> result = await _repository.registerCashPayment(
        playerId: widget.player.id,
        amount: request.amount,
        paymentDate: DateTime.now(),
        notes: request.notes,
      );

      if (!mounted) {
        return;
      }

      final double remainingAmount = _toDouble(result['remaining_amount']);

      final String chargeStatus =
          result['charge_status']?.toString().trim() ?? '';

      await _loadAccountStatus();

      if (!mounted) {
        return;
      }

      if (chargeStatus == 'paid' || remainingAmount <= 0) {
        _showSuccessMessage(
          '¡Pago registrado! '
          'La mensualidad quedó completamente pagada.',
        );
      } else {
        _showSuccessMessage(
          'Pago registrado correctamente. '
          'Saldo pendiente: ${_formatMoney(remainingAmount)}.',
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showErrorMessage(_cashPaymentErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() {
          _isRegisteringCash = false;
        });
      }
    }
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
              color: AppColors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF168A55),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFC62828),
          content: Row(
            children: [
              const Icon(Icons.error_rounded, color: AppColors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.white,
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
        foregroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Estado de cuenta',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading || _isRegisteringCash
                ? null
                : _loadAccountStatus,
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.fuchsia,
          onRefresh: _loadAccountStatus,
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
      return _PaymentErrorCard(
        message: _errorMessage!,
        onRetry: _loadAccountStatus,
      );
    }

    final PaymentAccountStatus status = _status!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PlayerHeaderCard(player: widget.player, status: status),
        const SizedBox(height: 18),

        _CurrentPaymentCard(status: status),
        const SizedBox(height: 18),

        _FinancialSummaryCard(status: status),
        const SizedBox(height: 18),

        _PaymentDetailsCard(status: status),
        const SizedBox(height: 18),

        _QrActionCard(
          isEnabled: !status.isPaid && !_isRegisteringCash,
          onPressed: _openPaymentQr,
        ),
        const SizedBox(height: 18),

        _CashActionCard(
          status: status,
          isLoading: _isRegisteringCash,
          onPressed: _openCashPaymentDialog,
        ),
        const SizedBox(height: 18),

        _HistoryActionCard(onPressed: _openPaymentHistory),
        const SizedBox(height: 22),

        SizedBox(
          height: 54,
          child: OutlinedButton.icon(
            onPressed: _isRegisteringCash
                ? null
                : () {
                    Navigator.of(context).pop();
                  },
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text(
              'VOLVER A LA FICHA',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.fuchsia,
              side: const BorderSide(color: AppColors.fuchsia),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlayerHeaderCard extends StatelessWidget {
  const _PlayerHeaderCard({required this.player, required this.status});

  final PlayerModel player;
  final PaymentAccountStatus status;

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
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.yellow,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 3),
            ),
            alignment: Alignment.center,
            child: Text(
              player.initials.isEmpty ? '?' : player.initials,
              style: const TextStyle(
                color: AppColors.black,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.playerName,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Código: ${player.playerCode}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  status.categoryName,
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

class _CurrentPaymentCard extends StatelessWidget {
  const _CurrentPaymentCard({required this.status});

  final PaymentAccountStatus status;

  @override
  Widget build(BuildContext context) {
    final bool paid = status.isPaid;

    final Color principalColor = paid
        ? const Color(0xFF168A55)
        : AppColors.fuchsia;

    return Container(
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: principalColor.withValues(alpha: 0.20)),
      ),
      child: Column(
        children: [
          Icon(
            paid
                ? Icons.verified_rounded
                : Icons.account_balance_wallet_rounded,
            color: principalColor,
            size: 42,
          ),
          const SizedBox(height: 12),

          Text(
            paid ? 'Mensualidad pagada' : 'Saldo pendiente',
            style: const TextStyle(
              color: Color(0xFF756970),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),

          Text(
            status.displayRemainingAmount,
            style: TextStyle(
              color: principalColor,
              fontSize: 39,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            status.displayPeriod,
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 13),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: paid
                  ? const Color(0xFF168A55).withValues(alpha: 0.12)
                  : AppColors.yellow.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  paid ? Icons.check_circle_rounded : Icons.schedule_rounded,
                  color: paid
                      ? const Color(0xFF168A55)
                      : const Color(0xFF745700),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  paid ? 'PAGADO' : status.chargeStatusLabel.toUpperCase(),
                  style: TextStyle(
                    color: paid
                        ? const Color(0xFF168A55)
                        : const Color(0xFF745700),
                    fontWeight: FontWeight.w900,
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

class _FinancialSummaryCard extends StatelessWidget {
  const _FinancialSummaryCard({required this.status});

  final PaymentAccountStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                color: AppColors.fuchsia,
                size: 28,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Resumen de la mensualidad',
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          _FinancialRow(label: 'Monto total', value: status.displayAmountDue),
          const Divider(height: 24),

          _FinancialRow(
            label: 'Monto pagado',
            value: status.displayAmountPaid,
            valueColor: const Color(0xFF168A55),
          ),
          const Divider(height: 24),

          _FinancialRow(
            label: 'Saldo pendiente',
            value: status.displayRemainingAmount,
            valueColor: status.isPaid
                ? const Color(0xFF168A55)
                : AppColors.fuchsia,
            emphasize: true,
          ),
        ],
      ),
    );
  }
}

class _FinancialRow extends StatelessWidget {
  const _FinancialRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: const Color(0xFF756970),
              fontSize: emphasize ? 14 : 13,
              fontWeight: emphasize ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.black,
            fontSize: emphasize ? 18 : 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _PaymentDetailsCard extends StatelessWidget {
  const _PaymentDetailsCard({required this.status});

  final PaymentAccountStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.calendar_month_rounded,
            label: 'Período',
            value: status.displayPeriod,
          ),
          const Divider(height: 28),

          _DetailRow(
            icon: Icons.date_range_rounded,
            label: 'Ventana de pago',
            value: 'Del día ${status.dayFrom} al ${status.dayTo}',
          ),
          const Divider(height: 28),

          _DetailRow(
            icon: Icons.event_rounded,
            label: 'Fecha límite',
            value: status.displayDueDate,
          ),
          const Divider(height: 28),

          _DetailRow(
            icon: Icons.groups_rounded,
            label: 'Categoría',
            value: status.categoryName,
          ),
          const Divider(height: 28),

          _DetailRow(
            icon: status.isPaid
                ? Icons.verified_rounded
                : Icons.pending_actions_rounded,
            label: 'Estado',
            value: status.chargeStatusLabel,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
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
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.fuchsia.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.fuchsia),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF81747A),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QrActionCard extends StatelessWidget {
  const _QrActionCard({required this.isEnabled, required this.onPressed});

  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.qr_code_2_rounded, color: AppColors.fuchsia, size: 35),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pago mediante QR',
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Consulta el QR institucional '
                      'para realizar el pago.',
                      style: TextStyle(
                        color: Color(0xFF81747A),
                        fontWeight: FontWeight.w600,
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
              onPressed: isEnabled ? onPressed : null,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: Text(
                isEnabled ? 'VER QR' : 'MENSUALIDAD PAGADA',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.yellow,
                foregroundColor: AppColors.black,
                disabledBackgroundColor: const Color(0xFFE4E4E4),
                disabledForegroundColor: const Color(0xFF777777),
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
}

class _CashActionCard extends StatelessWidget {
  const _CashActionCard({
    required this.status,
    required this.isLoading,
    required this.onPressed,
  });

  final PaymentAccountStatus status;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final bool enabled = !status.isPaid && !isLoading;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF168A55).withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF168A55).withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.payments_rounded,
                  color: Color(0xFF168A55),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pago en efectivo',
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      status.isPaid
                          ? 'La mensualidad ya fue cubierta.'
                          : 'Registro y aprobación manual '
                                'por administración.',
                      style: const TextStyle(
                        color: Color(0xFF81747A),
                        fontWeight: FontWeight.w600,
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
              onPressed: enabled ? onPressed : null,
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : const Icon(Icons.add_card_rounded),
              label: Text(
                isLoading
                    ? 'REGISTRANDO...'
                    : status.isPaid
                    ? 'PAGO COMPLETADO'
                    : 'REGISTRAR PAGO EN EFECTIVO',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF168A55),
                foregroundColor: AppColors.white,
                disabledBackgroundColor: const Color(0xFFE4E4E4),
                disabledForegroundColor: const Color(0xFF777777),
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
}

class _HistoryActionCard extends StatelessWidget {
  const _HistoryActionCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.fuchsia.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.fuchsia.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: AppColors.fuchsia,
                  size: 29,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Historial de pagos',
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Consulta todos los movimientos '
                      'registrados del jugador.',
                      style: TextStyle(
                        color: Color(0xFF81747A),
                        fontWeight: FontWeight.w600,
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
            child: OutlinedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.receipt_long_rounded),
              label: const Text(
                'VER HISTORIAL DE PAGOS',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.fuchsia,
                side: const BorderSide(color: AppColors.fuchsia),
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
}

class _CashPaymentDialog extends StatefulWidget {
  const _CashPaymentDialog({required this.status});

  final PaymentAccountStatus status;

  @override
  State<_CashPaymentDialog> createState() {
    return _CashPaymentDialogState();
  }
}

class _CashPaymentDialogState extends State<_CashPaymentDialog> {
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;

  String? _validationMessage;

  @override
  void initState() {
    super.initState();

    _amountController = TextEditingController(
      text: _editableAmount(widget.status.remainingAmount),
    );

    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  void _submit() {
    final String normalizedAmount = _amountController.text.trim().replaceAll(
      ',',
      '.',
    );

    final double? amount = double.tryParse(normalizedAmount);

    if (amount == null || amount <= 0) {
      setState(() {
        _validationMessage = 'Ingresa un monto válido mayor a cero.';
      });
      return;
    }

    if (amount > widget.status.remainingAmount) {
      setState(() {
        _validationMessage =
            'El monto no puede superar el saldo '
            'pendiente de '
            '${widget.status.displayRemainingAmount}.';
      });
      return;
    }

    final String notes = _notesController.text.trim();

    Navigator.of(context).pop(
      _CashPaymentRequest(amount: amount, notes: notes.isEmpty ? null : notes),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Row(
        children: [
          Icon(Icons.payments_rounded, color: Color(0xFF168A55)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pago en efectivo',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.status.playerName,
              style: const TextStyle(
                color: AppColors.black,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.status.displayPeriod} · '
              'Saldo '
              '${widget.status.displayRemainingAmount}',
              style: const TextStyle(
                color: Color(0xFF81747A),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Monto recibido',
                suffixText: 'Bs',
                prefixIcon: const Icon(Icons.payments_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: _notesController,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Observación opcional',
                hintText: 'Ej.: Pago recibido en secretaría',
                prefixIcon: const Icon(Icons.notes_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            if (_validationMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _validationMessage!,
                style: const TextStyle(
                  color: Color(0xFFC62828),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],

            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF168A55).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Puedes registrar el monto completo '
                'o un pago parcial. El saldo restante '
                'se actualizará automáticamente.',
                style: TextStyle(
                  color: Color(0xFF37634F),
                  fontSize: 12.5,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text(
            'CANCELAR',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.arrow_forward_rounded),
          label: const Text(
            'CONTINUAR',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF168A55),
            foregroundColor: AppColors.white,
          ),
        ),
      ],
    );
  }
}

class _ConfirmationRow extends StatelessWidget {
  const _ConfirmationRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF81747A),
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
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _PaymentErrorCard extends StatelessWidget {
  const _PaymentErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 34),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8A2525),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('REINTENTAR')),
        ],
      ),
    );
  }
}

class _CashPaymentRequest {
  const _CashPaymentRequest({required this.amount, this.notes});

  final double amount;
  final String? notes;
}

String _editableAmount(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value.toStringAsFixed(2);
}

String _formatMoney(double value) {
  if (value == value.roundToDouble()) {
    return '${value.toInt()} Bs';
  }

  return '${value.toStringAsFixed(2)} Bs';
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

String _cashPaymentErrorMessage(Object error) {
  final String message = error.toString();

  final String lower = message.toLowerCase();

  if (lower.contains('solo un administrador')) {
    return 'Solo un administrador puede '
        'registrar pagos en efectivo.';
  }

  if (lower.contains('no está activo')) {
    return 'Tu usuario no está activo para '
        'registrar pagos.';
  }

  if (lower.contains('ya se encuentra pagada')) {
    return 'Esta mensualidad ya se encuentra pagada.';
  }

  if (lower.contains('supera el saldo pendiente')) {
    return 'El monto ingresado supera el saldo pendiente.';
  }

  if (lower.contains('no existe una tarifa vigente')) {
    return 'No existe una tarifa vigente para '
        'este jugador.';
  }

  if (lower.contains('no tienes autorización')) {
    return 'No tienes autorización para registrar '
        'este pago.';
  }

  return 'No fue posible registrar el pago en efectivo.';
}
