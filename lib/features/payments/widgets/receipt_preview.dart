import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class ReceiptPreview extends StatelessWidget {
  const ReceiptPreview({
    required this.onSelectPressed,
    required this.onRemovePressed,
    this.imageBytes,
    this.fileName,
    this.isProcessing = false,
    super.key,
  });

  final Uint8List? imageBytes;
  final String? fileName;

  final VoidCallback onSelectPressed;
  final VoidCallback onRemovePressed;

  final bool isProcessing;

  bool get hasReceipt {
    return imageBytes != null && imageBytes!.isNotEmpty;
  }

  String get displayFileName {
    final String value = fileName?.trim() ?? '';

    return value.isEmpty ? 'Comprobante seleccionado' : value;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: hasReceipt
          ? _SelectedReceiptCard(
              key: const ValueKey<String>('selected-receipt'),
              imageBytes: imageBytes!,
              fileName: displayFileName,
              isProcessing: isProcessing,
              onChangePressed: onSelectPressed,
              onRemovePressed: onRemovePressed,
            )
          : _EmptyReceiptCard(
              key: const ValueKey<String>('empty-receipt'),
              isProcessing: isProcessing,
              onSelectPressed: onSelectPressed,
            ),
    );
  }
}

class _EmptyReceiptCard extends StatelessWidget {
  const _EmptyReceiptCard({
    required this.isProcessing,
    required this.onSelectPressed,
    super.key,
  });

  final bool isProcessing;
  final VoidCallback onSelectPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.fuchsia.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: AppColors.fuchsia.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppColors.fuchsia,
              size: 35,
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'Comprobante de pago',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.black,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Todavía no se seleccionó ningún '
            'comprobante. Puedes cargar una '
            'captura o fotografía del pago.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF81747A),
              fontSize: 12.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 51,
            child: FilledButton.icon(
              onPressed: isProcessing ? null : onSelectPressed,
              icon: isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppColors.white,
                      ),
                    )
                  : const Icon(Icons.add_photo_alternate_rounded),
              label: Text(
                isProcessing ? 'PROCESANDO...' : 'SELECCIONAR COMPROBANTE',
                style: const TextStyle(fontWeight: FontWeight.w900),
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
}

class _SelectedReceiptCard extends StatelessWidget {
  const _SelectedReceiptCard({
    required this.imageBytes,
    required this.fileName,
    required this.isProcessing,
    required this.onChangePressed,
    required this.onRemovePressed,
    super.key,
  });

  final Uint8List imageBytes;
  final String fileName;

  final bool isProcessing;

  final VoidCallback onChangePressed;
  final VoidCallback onRemovePressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF168A55).withValues(alpha: 0.30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF168A55)),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Comprobante seleccionado',
                  style: TextStyle(
                    color: Color(0xFF168A55),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              constraints: const BoxConstraints(minHeight: 220, maxHeight: 440),
              color: const Color(0xFFF1ECEF),
              child: Image.memory(
                imageBytes,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder:
                    (
                      BuildContext context,
                      Object error,
                      StackTrace? stackTrace,
                    ) {
                      return const SizedBox(
                        height: 220,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.broken_image_rounded,
                                color: AppColors.fuchsia,
                                size: 42,
                              ),
                              SizedBox(height: 9),
                              Text(
                                'No fue posible mostrar '
                                'la imagen.',
                                style: TextStyle(
                                  color: Color(0xFF81747A),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
              ),
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              const Icon(
                Icons.image_rounded,
                color: AppColors.fuchsia,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isProcessing ? null : onChangePressed,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text(
                    'CAMBIAR',
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
              const SizedBox(width: 11),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isProcessing ? null : onRemovePressed,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text(
                    'ELIMINAR',
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}
