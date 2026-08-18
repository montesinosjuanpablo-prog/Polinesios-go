import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../players/models/player_model.dart';
import '../repositories/payment_repository.dart';

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

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime _paymentDate = DateTime.now();

  String _paymentMethod = 'cash';

  List<Map<String, dynamic>> _history = <Map<String, dynamic>>[];

  bool _isLoadingHistory = true;
  bool _isSavingPayment = false;

  String? _historyError;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ============================================================
  // HISTORIAL
  // ============================================================

  Future<void> _loadHistory() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoadingHistory = true;
      _historyError = null;
    });

    try {
      final List<Map<String, dynamic>> result = await _repository
          .getPlayerManualPaymentHistory(widget.player.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _history = result;
        _isLoadingHistory = false;
      });
    } catch (error) {
      debugPrint('Error al cargar historial simple de pagos: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _history = <Map<String, dynamic>>[];
        _isLoadingHistory = false;
        _historyError = 'No fue posible cargar el historial de pagos.';
      });
    }
  }

  // ============================================================
  // FECHA
  // ============================================================

  Future<void> _selectPaymentDate() async {
    if (_isSavingPayment) {
      return;
    }

    final DateTime today = DateTime.now();

    final DateTime normalizedToday = DateTime(
      today.year,
      today.month,
      today.day,
    );

    final DateTime firstAllowedDate = DateTime(today.year, 1, 1);

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: firstAllowedDate,
      lastDate: normalizedToday,
      helpText: 'Fecha del pago',
      cancelText: 'CANCELAR',
      confirmText: 'SELECCIONAR',
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _paymentDate = selectedDate;
    });
  }

  // ============================================================
  // MÉTODO
  // ============================================================

  void _cyclePaymentMethod() {
    if (_isSavingPayment) {
      return;
    }

    setState(() {
      _paymentMethod = _paymentMethod == 'cash' ? 'qr' : 'cash';
    });
  }

  // ============================================================
  // REGISTRAR PAGO
  // ============================================================

  Future<void> _registerPayment() async {
    if (_isSavingPayment) {
      return;
    }

    FocusScope.of(context).unfocus();

    final String amountText = _amountController.text.trim().replaceAll(
      ',',
      '.',
    );

    final double? amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      _showMessage('Ingresa un monto válido mayor a cero.', isError: true);
      return;
    }

    final bool confirmed = await _showRegisterConfirmation(amount: amount);

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _isSavingPayment = true;
    });

    try {
      await _repository.registerManualPayment(
        playerId: widget.player.id,
        amount: amount,
        paymentDate: _paymentDate,
        paymentMethod: _paymentMethod,
        notes: _notesController.text,
      );

      if (!mounted) {
        return;
      }

      _amountController.clear();
      _notesController.clear();

      setState(() {
        _paymentDate = DateTime.now();
        _paymentMethod = 'cash';
      });

      await _loadHistory();

      if (!mounted) {
        return;
      }

      _showMessage('¡Pago registrado correctamente!');
    } catch (error) {
      debugPrint('Error al registrar pago manual: $error');

      if (!mounted) {
        return;
      }

      _showMessage(_friendlyPaymentError(error), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSavingPayment = false;
        });
      }
    }
  }

  Future<bool> _showRegisterConfirmation({required double amount}) async {
    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
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
              _ConfirmationRow(label: 'Jugador', value: widget.player.fullName),
              const SizedBox(height: 10),
              _ConfirmationRow(
                label: 'Fecha',
                value: _formatDate(_paymentDate),
              ),
              const SizedBox(height: 10),
              _ConfirmationRow(label: 'Monto', value: _formatMoney(amount)),
              const SizedBox(height: 10),
              _ConfirmationRow(
                label: 'Método',
                value: _methodLabel(_paymentMethod),
              ),
              if (_notesController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                _ConfirmationRow(
                  label: 'Observación',
                  value: _notesController.text.trim(),
                ),
              ],
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: AppColors.yellow.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'El pago quedará acreditado inmediatamente.',
                  style: TextStyle(
                    color: Color(0xFF6D5600),
                    fontWeight: FontWeight.w700,
                    height: 1.35,
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

    return result ?? false;
  }

  // ============================================================
  // CORREGIR PAGO
  // ============================================================

  Future<void> _openCorrectionDialog(Map<String, dynamic> payment) async {
    final String paymentId =
        payment['payment_record_id']?.toString().trim() ?? '';

    if (paymentId.isEmpty) {
      _showMessage(
        'El pago seleccionado no tiene un identificador válido.',
        isError: true,
      );
      return;
    }

    final double amount = _toDouble(payment['amount']);

    final DateTime paymentDate =
        _parseDate(payment['payment_date']) ?? DateTime.now();

    final String method =
        payment['payment_method']?.toString().trim().toLowerCase() ?? 'cash';

    final String notes = payment['notes']?.toString().trim() ?? '';

    final _PaymentCorrectionRequest? request =
        await showDialog<_PaymentCorrectionRequest>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return _CorrectionDialog(
              initialAmount: amount,
              initialDate: paymentDate,
              initialMethod: method == 'qr' ? 'qr' : 'cash',
              initialNotes: notes,
            );
          },
        );

    if (request == null || !mounted) {
      return;
    }

    final bool confirmed = await _showCorrectionConfirmation(request);

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _isSavingPayment = true;
    });

    try {
      await _repository.updateManualPayment(
        paymentRecordId: paymentId,
        amount: request.amount,
        paymentDate: request.paymentDate,
        paymentMethod: request.paymentMethod,
        notes: request.notes,
      );

      if (!mounted) {
        return;
      }

      await _loadHistory();

      if (!mounted) {
        return;
      }

      _showMessage('Pago corregido correctamente.');
    } catch (error) {
      debugPrint('Error al corregir pago: $error');

      if (!mounted) {
        return;
      }

      _showMessage(_friendlyPaymentError(error), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSavingPayment = false;
        });
      }
    }
  }

  Future<bool> _showCorrectionConfirmation(
    _PaymentCorrectionRequest request,
  ) async {
    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Row(
            children: [
              Icon(Icons.edit_note_rounded, color: AppColors.fuchsia),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Confirmar corrección',
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
                'Se actualizará el mismo registro de pago.',
                style: TextStyle(
                  color: Color(0xFF756970),
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              _ConfirmationRow(
                label: 'Fecha',
                value: _formatDate(request.paymentDate),
              ),
              const SizedBox(height: 9),
              _ConfirmationRow(
                label: 'Monto',
                value: _formatMoney(request.amount),
              ),
              const SizedBox(height: 9),
              _ConfirmationRow(
                label: 'Método',
                value: _methodLabel(request.paymentMethod),
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
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.fuchsia,
                foregroundColor: AppColors.white,
              ),
              child: const Text(
                'GUARDAR CORRECCIÓN',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // ============================================================
  // MENSAJES
  // ============================================================

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError
              ? Colors.red.shade700
              : const Color(0xFF168A55),
          content: Row(
            children: [
              Icon(
                isError ? Icons.error_rounded : Icons.check_circle_rounded,
                color: AppColors.white,
              ),
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

  String _friendlyPaymentError(Object error) {
    final String message = error.toString();

    const List<String> knownMessages = <String>[
      'Debes iniciar sesión',
      'Solo un administrador',
      'El monto del pago',
      'La fecha del pago',
      'El método de pago',
      'El jugador seleccionado no existe',
      'No tienes autorización',
      'No existe el pago confirmado',
      'Tu usuario no está activo',
    ];

    for (final String knownMessage in knownMessages) {
      if (message.contains(knownMessage)) {
        final int start = message.indexOf(knownMessage);
        String clean = message.substring(start);

        final int marker = clean.indexOf(',');

        if (marker > 0) {
          clean = clean.substring(0, marker);
        }

        return clean.trim();
      }
    }

    return 'No fue posible completar la operación.';
  }

  // ============================================================
  // BUILD
  // ============================================================

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
            onPressed: _isLoadingHistory || _isSavingPayment
                ? null
                : _loadHistory,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 4),
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
              _PlayerPaymentHeader(player: widget.player),
              const SizedBox(height: 18),
              _buildPaymentForm(),
              const SizedBox(height: 22),
              _buildHistorySection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.fuchsia.withValues(alpha: 0.14)),
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
          const Row(
            children: [
              Icon(Icons.add_card_rounded, color: AppColors.fuchsia),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Registrar pago',
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Registra únicamente el dinero que ya fue recibido.',
            style: TextStyle(
              color: Color(0xFF81747A),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),

          // FECHA
          InkWell(
            onTap: _selectPaymentDate,
            borderRadius: BorderRadius.circular(16),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Fecha del pago',
                prefixIcon: const Icon(Icons.calendar_month_rounded),
                suffixIcon: const Icon(Icons.expand_more_rounded),
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
              child: Text(
                _formatDateLong(_paymentDate),
                style: const TextStyle(
                  color: AppColors.black,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // MONTO
          TextField(
            controller: _amountController,
            enabled: !_isSavingPayment,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Monto',
              hintText: 'Ej.: 120',
              prefixIcon: const Icon(Icons.payments_outlined),
              suffixText: 'Bs',
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

          const SizedBox(height: 16),

          // MÉTODO
          const Text(
            'Método de pago',
            style: TextStyle(
              color: Color(0xFF756970),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),

          _PaymentMethodButton(
            method: _paymentMethod,
            onTap: _cyclePaymentMethod,
          ),

          const SizedBox(height: 7),

          const Text(
            'Toca el botón para cambiar entre Efectivo y QR.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF91858B),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),

          // OBSERVACIÓN
          TextField(
            controller: _notesController,
            enabled: !_isSavingPayment,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Observación (opcional)',
              hintText: 'Convenio, detalle u otra referencia',
              prefixIcon: const Icon(Icons.notes_rounded),
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

          const SizedBox(height: 20),

          FilledButton.icon(
            onPressed: _isSavingPayment ? null : _registerPayment,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.fuchsia,
              foregroundColor: AppColors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
            icon: _isSavingPayment
                ? const SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_rounded),
            label: Text(
              _isSavingPayment ? 'REGISTRANDO...' : 'CONFIRMAR PAGO',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Historial de pagos',
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (!_isLoadingHistory)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.fuchsia.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_history.length}',
                  style: const TextStyle(
                    color: AppColors.fuchsia,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingHistory)
          const _HistoryLoadingCard()
        else if (_historyError != null)
          _HistoryErrorCard(message: _historyError!, onRetry: _loadHistory)
        else if (_history.isEmpty)
          const _EmptyHistoryCard()
        else
          ..._history.map((Map<String, dynamic> payment) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: _PaymentHistoryCard(
                payment: payment,
                onCorrect: _isSavingPayment
                    ? null
                    : () {
                        _openCorrectionDialog(payment);
                      },
              ),
            );
          }),
      ],
    );
  }
}

// ============================================================
// ENCABEZADO DEL JUGADOR
// ============================================================

class _PlayerPaymentHeader extends StatelessWidget {
  const _PlayerPaymentHeader({required this.player});

  final PlayerModel player;

  @override
  Widget build(BuildContext context) {
    final String photoUrl = player.photoUrl?.trim() ?? '';

    Widget initialsFallback() {
      return Container(
        color: AppColors.yellow,
        alignment: Alignment.center,
        child: Text(
          player.initials,
          style: const TextStyle(
            color: AppColors.black,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.darkFuchsia, AppColors.fuchsia],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppColors.fuchsia.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.yellow,
              borderRadius: BorderRadius.circular(21),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: photoUrl.isNotEmpty
                  ? Image.network(
                      photoUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (
                            BuildContext context,
                            Object error,
                            StackTrace? stackTrace,
                          ) {
                            return initialsFallback();
                          },
                    )
                  : initialsFallback(),
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
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  player.playerCode,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _HeaderChip(
                      icon: Icons.sports_soccer_rounded,
                      label: player.displayCategory,
                    ),
                    _HeaderChip(
                      icon: Icons.groups_rounded,
                      label: player.displayTrainingGroup,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.yellow),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// BOTÓN QR / EFECTIVO
// ============================================================

class _PaymentMethodButton extends StatelessWidget {
  const _PaymentMethodButton({required this.method, required this.onTap});

  final String method;
  final VoidCallback onTap;

  bool get _isCash {
    return method == 'cash';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        height: 58,
        decoration: BoxDecoration(
          color: _isCash
              ? AppColors.yellow.withValues(alpha: 0.35)
              : AppColors.fuchsia.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isCash ? AppColors.yellow : AppColors.fuchsia,
            width: 1.7,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isCash ? Icons.payments_rounded : Icons.qr_code_2_rounded,
              color: _isCash ? AppColors.black : AppColors.fuchsia,
              size: 27,
            ),
            const SizedBox(width: 10),
            Text(
              _isCash ? 'EFECTIVO' : 'QR',
              style: TextStyle(
                color: _isCash ? AppColors.black : AppColors.fuchsia,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.sync_rounded,
              color: _isCash ? AppColors.black : AppColors.fuchsia,
              size: 19,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// HISTORIAL
// ============================================================

class _PaymentHistoryCard extends StatelessWidget {
  const _PaymentHistoryCard({required this.payment, required this.onCorrect});

  final Map<String, dynamic> payment;
  final VoidCallback? onCorrect;

  @override
  Widget build(BuildContext context) {
    final double amount = _toDouble(payment['amount']);

    final DateTime? date = _parseDate(payment['payment_date']);

    final String method =
        payment['payment_method']?.toString().trim().toLowerCase() ?? '';

    final String notes = payment['notes']?.toString().trim() ?? '';

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.fuchsia.withValues(alpha: 0.13)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: method == 'qr'
                      ? AppColors.fuchsia.withValues(alpha: 0.10)
                      : AppColors.yellow.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  method == 'qr'
                      ? Icons.qr_code_2_rounded
                      : Icons.payments_rounded,
                  color: method == 'qr' ? AppColors.fuchsia : AppColors.black,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatMoney(amount),
                      style: const TextStyle(
                        color: AppColors.black,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      date == null ? 'Fecha no registrada' : _formatDate(date),
                      style: const TextStyle(
                        color: Color(0xFF81747A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _methodLabel(method),
                      style: const TextStyle(
                        color: AppColors.fuchsia,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Corregir pago',
                onPressed: onCorrect,
                icon: const Icon(Icons.edit_rounded, color: AppColors.fuchsia),
              ),
            ],
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F3F5),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text(
                notes,
                style: const TextStyle(
                  color: Color(0xFF756970),
                  fontSize: 12.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyHistoryCard extends StatelessWidget {
  const _EmptyHistoryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt_long_rounded, size: 52, color: AppColors.fuchsia),
          SizedBox(height: 12),
          Text(
            'Todavía no hay pagos registrados',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 6),
          Text(
            'Los pagos que acredites aparecerán aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF81747A),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryLoadingCard extends StatelessWidget {
  const _HistoryLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.fuchsia),
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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 45),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('REINTENTAR'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DIÁLOGO DE CORRECCIÓN
// ============================================================

class _CorrectionDialog extends StatefulWidget {
  const _CorrectionDialog({
    required this.initialAmount,
    required this.initialDate,
    required this.initialMethod,
    required this.initialNotes,
  });

  final double initialAmount;
  final DateTime initialDate;
  final String initialMethod;
  final String initialNotes;

  @override
  State<_CorrectionDialog> createState() {
    return _CorrectionDialogState();
  }
}

class _CorrectionDialogState extends State<_CorrectionDialog> {
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;

  late DateTime _paymentDate;
  late String _paymentMethod;

  @override
  void initState() {
    super.initState();

    _amountController = TextEditingController(
      text: _amountForEditing(widget.initialAmount),
    );

    _notesController = TextEditingController(text: widget.initialNotes);

    _paymentDate = widget.initialDate;
    _paymentMethod = widget.initialMethod;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime today = DateTime.now();

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(today.year, 1, 1),
      lastDate: DateTime(today.year, today.month, today.day),
      helpText: 'Corregir fecha del pago',
      cancelText: 'CANCELAR',
      confirmText: 'SELECCIONAR',
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _paymentDate = selectedDate;
    });
  }

  void _cycleMethod() {
    setState(() {
      _paymentMethod = _paymentMethod == 'cash' ? 'qr' : 'cash';
    });
  }

  void _submit() {
    final String amountText = _amountController.text.trim().replaceAll(
      ',',
      '.',
    );

    final double? amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Ingresa un monto válido mayor a cero.'),
          ),
        );

      return;
    }

    Navigator.of(context).pop(
      _PaymentCorrectionRequest(
        amount: amount,
        paymentDate: _paymentDate,
        paymentMethod: _paymentMethod,
        notes: _notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      contentPadding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Text(
        'Corregir pago',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      content: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Monto',
                suffixText: 'Bs',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha',
                  prefixIcon: Icon(Icons.calendar_month_rounded),
                ),
                child: Text(
                  _formatDate(_paymentDate),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Método de pago',
              style: TextStyle(
                color: Color(0xFF756970),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            _CompactPaymentMethodButton(
              method: _paymentMethod,
              onTap: _cycleMethod,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              minLines: 2,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Observación (opcional)',
                hintText: 'Detalle o motivo de la corrección',
                prefixIcon: const Icon(Icons.notes_rounded),
                filled: true,
                fillColor: AppColors.yellow.withValues(alpha: 0.12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: AppColors.yellow.withValues(alpha: 0.85),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.fuchsia,
                    width: 1.6,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.fuchsia,
                        side: const BorderSide(
                          color: AppColors.fuchsia,
                          width: 1.6,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'CANCELAR',
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.fuchsia,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'GUARDAR',
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 11.5,
                                height: 1,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'CAMBIOS',
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 11.5,
                                height: 1,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 17,
                  color: AppColors.fuchsia,
                ),
                SizedBox(width: 7),
                Flexible(
                  child: Text(
                    'Se actualizará el mismo registro de pago.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF756970),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactPaymentMethodButton extends StatelessWidget {
  const _CompactPaymentMethodButton({
    required this.method,
    required this.onTap,
  });

  final String method;
  final VoidCallback onTap;

  bool get _isCash {
    return method == 'cash';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: _isCash
              ? AppColors.yellow.withValues(alpha: 0.18)
              : AppColors.fuchsia.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isCash ? AppColors.yellow : AppColors.fuchsia,
            width: 1.4,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isCash ? Icons.payments_rounded : Icons.qr_code_2_rounded,
              color: _isCash ? AppColors.black : AppColors.fuchsia,
              size: 21,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _isCash ? 'EFECTIVO' : 'QR',
                  maxLines: 1,
                  style: TextStyle(
                    color: _isCash ? AppColors.black : AppColors.fuchsia,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 7),
            Icon(
              Icons.sync_rounded,
              color: _isCash ? AppColors.black : AppColors.fuchsia,
              size: 17,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentCorrectionRequest {
  const _PaymentCorrectionRequest({
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    required this.notes,
  });

  final double amount;
  final DateTime paymentDate;
  final String paymentMethod;
  final String notes;
}

// ============================================================
// CONFIRMACIÓN
// ============================================================

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
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
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

// ============================================================
// HELPERS
// ============================================================

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

String _amountForEditing(double amount) {
  final bool hasDecimals = amount != amount.roundToDouble();

  return hasDecimals ? amount.toStringAsFixed(2) : amount.toStringAsFixed(0);
}

String _methodLabel(String method) {
  return method.toLowerCase() == 'qr' ? 'QR' : 'Efectivo';
}
