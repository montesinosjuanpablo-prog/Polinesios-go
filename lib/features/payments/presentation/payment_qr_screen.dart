import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/storage_service.dart';
import '../repositories/payment_repository.dart';
import '../widgets/receipt_preview.dart';

class PaymentQrScreen extends StatefulWidget {
  const PaymentQrScreen({
    required this.playerId,
    required this.playerName,
    required this.categoryName,
    required this.amount,
    super.key,
  });

  final String playerId;
  final String playerName;
  final String categoryName;
  final String amount;

  @override
  State<PaymentQrScreen> createState() => _PaymentQrScreenState();
}

class _PaymentQrScreenState extends State<PaymentQrScreen> {
  static const int _maximumReceiptSize = 8 * 1024 * 1024;

  static const List<String> _months = <String>[
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

  final ImagePicker _imagePicker = ImagePicker();

  final StorageService _storageService = const StorageService();

  final PaymentRepository _paymentRepository = const PaymentRepository();

  Uint8List? _receiptBytes;
  String? _receiptFileName;

  bool _isProcessing = false;
  bool _receiptSubmitted = false;

  String get _currentPeriod {
    final DateTime now = DateTime.now();

    return '${_months[now.month - 1]} '
        '${now.year}';
  }

  double? get _numericAmount {
    String normalizedAmount = widget.amount
        .replaceAll('Bs', '')
        .replaceAll('BOB', '')
        .replaceAll(' ', '')
        .trim();

    if (normalizedAmount.contains(',') && normalizedAmount.contains('.')) {
      normalizedAmount = normalizedAmount
          .replaceAll('.', '')
          .replaceAll(',', '.');
    } else {
      normalizedAmount = normalizedAmount.replaceAll(',', '.');
    }

    return double.tryParse(normalizedAmount);
  }

  Future<void> _selectReceipt() async {
    if (_isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile? selectedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (selectedFile == null) {
        return;
      }

      final Uint8List bytes = await selectedFile.readAsBytes();

      if (bytes.isEmpty) {
        _showMessage(
          message: 'El archivo seleccionado está vacío.',
          isError: true,
        );
        return;
      }

      if (bytes.length > _maximumReceiptSize) {
        _showMessage(
          message:
              'El comprobante supera el límite '
              'permitido de 8 MB.',
          isError: true,
        );
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _receiptBytes = bytes;
        _receiptFileName = selectedFile.name.trim().isEmpty
            ? 'comprobante_pago.jpg'
            : selectedFile.name.trim();

        _receiptSubmitted = false;
      });

      _showMessage(
        message:
            'Comprobante seleccionado '
            'correctamente.',
      );
    } catch (error) {
      debugPrint(
        'Error al seleccionar comprobante: '
        '$error',
      );

      _showMessage(
        message:
            'No fue posible seleccionar '
            'el comprobante.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _uploadReceipt() async {
    if (_isProcessing) {
      return;
    }

    final Uint8List? receiptBytes = _receiptBytes;
    final String? receiptFileName = _receiptFileName;

    if (receiptBytes == null || receiptFileName == null) {
      _showMessage(
        message: 'Seleccione un comprobante primero.',
        isError: true,
      );
      return;
    }

    final String normalizedPlayerId = widget.playerId.trim();

    if (normalizedPlayerId.isEmpty) {
      _showMessage(
        message: 'No se encontró el identificador del jugador.',
        isError: true,
      );
      return;
    }

    final double? amount = _numericAmount;

    if (amount == null || amount <= 0) {
      _showMessage(
        message: 'No fue posible interpretar el monto del pago.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // 1. Subimos el comprobante al Storage.
      final String receiptUrl = await _storageService.uploadPaymentReceipt(
        bytes: receiptBytes,
        fileName: receiptFileName,
      );

      // 2. Registramos financieramente el pago QR.
      // Queda PENDIENTE DE VERIFICACIÓN.
      final Map<String, dynamic> result = await _paymentRepository
          .reportQrPayment(
            playerId: normalizedPlayerId,
            amount: amount,
            receiptUrl: receiptUrl,
            paymentDate: DateTime.now(),
            notes: 'Comprobante QR enviado desde Polinesios GO.',
          );

      if (!mounted) {
        return;
      }

      final String paymentRecordId =
          result['payment_record_id']?.toString().trim() ?? '';

      final String paymentStatus =
          result['payment_status']?.toString().trim() ?? '';

      if (paymentRecordId.isEmpty) {
        throw const FormatException(
          'No se recibió el identificador del pago QR.',
        );
      }

      if (paymentStatus != 'pending_verification') {
        throw FormatException(
          'El pago QR fue registrado con '
          'un estado inesperado: $paymentStatus.',
        );
      }

      setState(() {
        _receiptSubmitted = true;
      });

      _showMessage(
        message:
            'Comprobante enviado correctamente. '
            'El pago quedó pendiente de revisión administrativa.',
      );
    } catch (error) {
      debugPrint('Error al reportar pago QR: $error');

      if (!mounted) {
        return;
      }

      _showMessage(message: _qrPaymentErrorMessage(error), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _removeReceipt() {
    if (_isProcessing) {
      return;
    }

    setState(() {
      _receiptBytes = null;
      _receiptFileName = null;
      _receiptSubmitted = false;
    });

    _showMessage(message: 'Comprobante eliminado.');
  }

  void _showShareComingSoon() {
    _showMessage(
      message:
          'La opción para compartir el QR '
          'será habilitada próximamente.',
    );
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
              : AppColors.fuchsia,
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

  @override
  Widget build(BuildContext context) {
    final bool hasReceipt = _receiptBytes != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F2F4),
      appBar: AppBar(
        backgroundColor: AppColors.darkFuchsia,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Pago mediante QR',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 34),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _InstitutionalHeader(),
                    const SizedBox(height: 18),
                    _PaymentSummaryCard(
                      playerName: widget.playerName,
                      categoryName: widget.categoryName,
                      amount: widget.amount,
                      period: _currentPeriod,
                    ),
                    const SizedBox(height: 18),
                    const _QrImageCard(),
                    const SizedBox(height: 18),
                    const _PaymentInstructionsCard(),
                    const SizedBox(height: 18),
                    ReceiptPreview(
                      imageBytes: _receiptBytes,
                      fileName: _receiptFileName,
                      isProcessing: _isProcessing,
                      onSelectPressed: _selectReceipt,
                      onRemovePressed: _removeReceipt,
                    ),
                    if (_receiptSubmitted) ...[
                      const SizedBox(height: 18),
                      const _SubmittedReceiptCard(),
                    ],
                    const SizedBox(height: 18),
                    _PaymentActions(
                      hasReceipt: hasReceipt,
                      isProcessing: _isProcessing,
                      receiptSubmitted: _receiptSubmitted,
                      onReceiptPressed: hasReceipt
                          ? _uploadReceipt
                          : _selectReceipt,
                      onSharePressed: _showShareComingSoon,
                    ),
                    const SizedBox(height: 22),
                    const _InstitutionalPhrase(),
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: _isProcessing
                            ? null
                            : () {
                                Navigator.of(context).pop();
                              },
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text(
                          'VOLVER AL ESTADO DE CUENTA',
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstitutionalHeader extends StatelessWidget {
  const _InstitutionalHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.darkFuchsia, AppColors.fuchsia, Color(0xFF8B004D)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.fuchsia.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(Icons.sports_soccer_rounded, color: AppColors.yellow, size: 48),
          SizedBox(height: 12),
          Text(
            'Escuela Formativa Polinesios',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.white,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Pago seguro mediante código QR',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentSummaryCard extends StatelessWidget {
  const _PaymentSummaryCard({
    required this.playerName,
    required this.categoryName,
    required this.amount,
    required this.period,
  });

  final String playerName;
  final String categoryName;
  final String amount;
  final String period;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: AppColors.fuchsia.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          const Text(
            'MENSUALIDAD',
            style: TextStyle(
              color: Color(0xFF81747A),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            period,
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            playerName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            categoryName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF756970),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.fuchsia.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text(
                  'Monto a cancelar',
                  style: TextStyle(
                    color: Color(0xFF81747A),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  amount,
                  style: const TextStyle(
                    color: AppColors.fuchsia,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    height: 1,
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

class _QrImageCard extends StatelessWidget {
  const _QrImageCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.fuchsia.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_balance_rounded, color: AppColors.fuchsia),
              SizedBox(width: 8),
              Text(
                'BancoSol',
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/payment_qr.png',
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentInstructionsCard extends StatelessWidget {
  const _PaymentInstructionsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7D6),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xFFFFD54F)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFF8A6500), size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Escanee este código QR desde una '
              'aplicación bancaria compatible. '
              'Verifique el monto antes de confirmar '
              'la operación y conserve el comprobante.',
              style: TextStyle(
                color: Color(0xFF665014),
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmittedReceiptCard extends StatelessWidget {
  const _SubmittedReceiptCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F0),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: const Color(0xFF168A55).withValues(alpha: 0.35),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_done_rounded, color: Color(0xFF168A55), size: 29),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comprobante recibido',
                  style: TextStyle(
                    color: Color(0xFF126B43),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'El comprobante fue enviado '
                  'correctamente y quedó pendiente '
                  'de revisión administrativa.',
                  style: TextStyle(
                    color: Color(0xFF315E4A),
                    fontSize: 12.5,
                    height: 1.4,
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

class _PaymentActions extends StatelessWidget {
  const _PaymentActions({
    required this.hasReceipt,
    required this.isProcessing,
    required this.receiptSubmitted,
    required this.onReceiptPressed,
    required this.onSharePressed,
  });

  final bool hasReceipt;
  final bool isProcessing;
  final bool receiptSubmitted;

  final VoidCallback onReceiptPressed;
  final VoidCallback onSharePressed;

  @override
  Widget build(BuildContext context) {
    String buttonText = 'YA REALICÉ EL PAGO';

    IconData buttonIcon = Icons.check_circle_rounded;

    if (hasReceipt) {
      buttonText = 'SUBIR COMPROBANTE';
      buttonIcon = Icons.cloud_upload_rounded;
    }

    if (receiptSubmitted) {
      buttonText = 'COMPROBANTE ENVIADO';
      buttonIcon = Icons.cloud_done_rounded;
    }

    if (isProcessing) {
      buttonText = 'PROCESANDO...';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 55,
          child: FilledButton.icon(
            onPressed: isProcessing || receiptSubmitted
                ? null
                : onReceiptPressed,
            icon: isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: AppColors.black,
                    ),
                  )
                : Icon(buttonIcon),
            label: Text(
              buttonText,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            style: FilledButton.styleFrom(
              disabledBackgroundColor: receiptSubmitted
                  ? const Color(0xFFBDE7CD)
                  : AppColors.yellow.withValues(alpha: 0.55),
              disabledForegroundColor: receiptSubmitted
                  ? const Color(0xFF126B43)
                  : AppColors.black,
              backgroundColor: AppColors.yellow,
              foregroundColor: AppColors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 55,
          child: OutlinedButton.icon(
            onPressed: isProcessing ? null : onSharePressed,
            icon: const Icon(Icons.share_rounded),
            label: const Text(
              'COMPARTIR QR',
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

class _InstitutionalPhrase extends StatelessWidget {
  const _InstitutionalPhrase();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '“Nunca dejes de Soñar, '
      'Nunca dejes de Intentar, '
      'Nunca te Rindas.”',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: AppColors.darkFuchsia,
        fontSize: 14,
        height: 1.5,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

String _qrPaymentErrorMessage(Object error) {
  final String message = error.toString();
  final String lower = message.toLowerCase();

  if (lower.contains('ya se encuentra pagada')) {
    return 'Esta mensualidad ya se encuentra pagada.';
  }

  if (lower.contains('supera el saldo pendiente')) {
    return 'El monto reportado supera el saldo '
        'pendiente de la mensualidad.';
  }

  if (lower.contains('ya existe un pago qr pendiente')) {
    return 'Ya existe un pago QR con este monto '
        'pendiente de revisión.';
  }

  if (lower.contains('debes adjuntar un comprobante')) {
    return 'Debes adjuntar un comprobante de pago.';
  }

  if (lower.contains('no existe una tarifa vigente')) {
    return 'No existe una tarifa vigente para '
        'este jugador.';
  }

  if (lower.contains('no tienes autorización')) {
    return 'No tienes autorización para reportar '
        'este pago.';
  }

  if (lower.contains('no está activo')) {
    return 'Tu usuario no está activo para '
        'reportar pagos.';
  }

  return 'No fue posible registrar el pago QR.';
}
