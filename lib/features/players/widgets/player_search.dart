import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class PlayerSearch extends StatelessWidget {
  const PlayerSearch({
    required this.controller,
    required this.onChanged,
    this.hintText = 'Buscar por nombre o código...',
    this.onFilterPressed,
    this.hasActiveFilters = false,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;
  final VoidCallback? onFilterPressed;
  final bool hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder:
                (BuildContext context, TextEditingValue value, Widget? child) {
                  final bool hasText = value.text.trim().isNotEmpty;

                  return TextField(
                    controller: controller,
                    onChanged: onChanged,
                    textInputAction: TextInputAction.search,
                    autocorrect: false,
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: const TextStyle(
                        color: Color(0xFF8A7D83),
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.fuchsia,
                      ),
                      suffixIcon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: hasText
                            ? IconButton(
                                key: const ValueKey<String>('clear-search'),
                                onPressed: () {
                                  controller.clear();
                                  onChanged('');
                                },
                                tooltip: 'Limpiar búsqueda',
                                icon: const Icon(Icons.close_rounded),
                              )
                            : const SizedBox.shrink(
                                key: ValueKey<String>('empty-search'),
                              ),
                      ),
                      filled: true,
                      fillColor: AppColors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 17,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(
                          color: AppColors.fuchsia.withValues(alpha: 0.14),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: AppColors.fuchsia,
                          width: 2,
                        ),
                      ),
                    ),
                  );
                },
          ),
        ),
        if (onFilterPressed != null) ...[
          const SizedBox(width: 12),
          _FilterButton(
            onPressed: onFilterPressed!,
            hasActiveFilters: hasActiveFilters,
          ),
        ],
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.onPressed,
    required this.hasActiveFilters,
  });

  final VoidCallback onPressed;
  final bool hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: hasActiveFilters,
      backgroundColor: AppColors.yellow,
      smallSize: 11,
      child: IconButton(
        onPressed: onPressed,
        tooltip: 'Filtrar jugadores',
        style: IconButton.styleFrom(
          fixedSize: const Size(58, 58),
          foregroundColor: hasActiveFilters
              ? AppColors.white
              : AppColors.fuchsia,
          backgroundColor: hasActiveFilters
              ? AppColors.fuchsia
              : AppColors.white,
          side: BorderSide(color: AppColors.fuchsia.withValues(alpha: 0.18)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        icon: const Icon(Icons.tune_rounded, size: 26),
      ),
    );
  }
}
