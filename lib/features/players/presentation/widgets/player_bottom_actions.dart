import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class PlayerBottomActions extends StatelessWidget {
  const PlayerBottomActions({
    required this.onEditPressed,
    required this.onBackPressed,
    super.key,
  });

  final VoidCallback onEditPressed;
  final VoidCallback onBackPressed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 560;

        final Widget editButton = SizedBox(
          height: 54,
          child: FilledButton.icon(
            onPressed: onEditPressed,
            icon: const Icon(Icons.edit_rounded),
            label: const Text(
              'EDITAR JUGADOR',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.fuchsia,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
          ),
        );

        final Widget backButton = SizedBox(
          height: 54,
          child: OutlinedButton.icon(
            onPressed: onBackPressed,
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text(
              'VOLVER',
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
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [editButton, const SizedBox(height: 11), backButton],
          );
        }

        return Row(
          children: [
            Expanded(child: editButton),
            const SizedBox(width: 11),
            Expanded(child: backButton),
          ],
        );
      },
    );
  }
}
