import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../models/training_group_model.dart';

class TrainingGroupDropdown extends StatelessWidget {
  const TrainingGroupDropdown({
    required this.groups,
    required this.selectedGroup,
    required this.isLoading,
    required this.errorMessage,
    required this.onChanged,
    required this.onRetry,
    super.key,
  });

  final List<TrainingGroupModel> groups;
  final TrainingGroupModel? selectedGroup;
  final bool isLoading;
  final String? errorMessage;
  final ValueChanged<TrainingGroupModel?> onChanged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.fuchsia),
        ),
      );
    }

    if (errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEEEE),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFC62828)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                errorMessage!,
                style: const TextStyle(
                  color: Color(0xFFC62828),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, color: AppColors.fuchsia),
            ),
          ],
        ),
      );
    }

    if (groups.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8DD),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.yellow),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.fuchsia),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'No existen grupos de entrenamiento activos.',
                style: TextStyle(
                  color: AppColors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<TrainingGroupModel>(
      initialValue: selectedGroup,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Grupo de entrenamiento',
        hintText: 'Selecciona un grupo',
        prefixIcon: const Icon(Icons.groups_rounded, color: AppColors.fuchsia),
        filled: true,
        fillColor: const Color(0xFFF8F3F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.fuchsia.withValues(alpha: 0.10),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.fuchsia, width: 1.5),
        ),
      ),
      items: groups.map((TrainingGroupModel group) {
        return DropdownMenuItem<TrainingGroupModel>(
          value: group,
          child: Text(group.name, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      validator: (TrainingGroupModel? value) {
        if (value == null) {
          return 'Selecciona un grupo de entrenamiento.';
        }

        return null;
      },
      onChanged: onChanged,
    );
  }
}
