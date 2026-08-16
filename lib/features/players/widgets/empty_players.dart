import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class EmptyPlayers extends StatelessWidget {
  const EmptyPlayers({
    required this.title,
    required this.message,
    this.buttonText,
    this.onPressed,
    super.key,
  });

  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.fuchsia.withValues(alpha: 0.08),
              ),
              child: const Icon(
                Icons.sports_soccer_rounded,
                size: 62,
                color: AppColors.fuchsia,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF777777),
                fontSize: 16,
                height: 1.45,
              ),
            ),
            if (buttonText != null && onPressed != null) ...[
              const SizedBox(height: 30),
              SizedBox(
                width: 220,
                height: 54,
                child: FilledButton.icon(
                  onPressed: onPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.yellow,
                    foregroundColor: AppColors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                    buttonText!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
