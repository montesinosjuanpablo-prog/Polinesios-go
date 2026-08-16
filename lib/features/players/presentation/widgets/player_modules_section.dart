import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class PlayerModulesSection extends StatelessWidget {
  const PlayerModulesSection({required this.onModulePressed, super.key});

  final ValueChanged<String> onModulePressed;

  @override
  Widget build(BuildContext context) {
    const List<_ModuleData> modules = <_ModuleData>[
      _ModuleData(
        title: 'Tutor y familia',
        subtitle: 'Contactos y responsables',
        icon: Icons.family_restroom_rounded,
      ),
      _ModuleData(
        title: 'Información médica',
        subtitle: 'Salud, alergias y antecedentes',
        icon: Icons.medical_information_rounded,
      ),
      _ModuleData(
        title: 'Asistencia',
        subtitle: 'Historial de entrenamientos',
        icon: Icons.fact_check_rounded,
      ),
      _ModuleData(
        title: 'Pagos',
        subtitle: 'Estado de cuenta y comprobantes',
        icon: Icons.payments_rounded,
      ),
      _ModuleData(
        title: 'Rendimiento',
        subtitle: 'Estadísticas y evaluaciones · V2',
        icon: Icons.insights_rounded,
        isVersionTwo: true,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.fuchsia.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Expediente del jugador',
            style: TextStyle(
              color: AppColors.black,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Accede a la información complementaria.',
            style: TextStyle(
              color: Color(0xFF81747A),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final int columns = constraints.maxWidth >= 760
                  ? 3
                  : constraints.maxWidth >= 500
                  ? 2
                  : 1;

              final double aspectRatio;

              if (columns == 1) {
                aspectRatio = 3.0;
              } else if (columns == 2) {
                aspectRatio = 1.55;
              } else {
                aspectRatio = 1.65;
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: modules.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: aspectRatio,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final _ModuleData module = modules[index];

                  return _ModuleCard(
                    data: module,
                    onPressed: () {
                      onModulePressed(module.title);
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.data, required this.onPressed});

  final _ModuleData data;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: data.isVersionTwo
              ? const Color(0xFFFFF8DD)
              : const Color(0xFFF8F3F5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: data.isVersionTwo
                ? AppColors.yellow
                : AppColors.fuchsia.withValues(alpha: 0.10),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: data.isVersionTwo
                    ? AppColors.yellow.withValues(alpha: 0.45)
                    : AppColors.fuchsia.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                data.icon,
                color: data.isVersionTwo ? AppColors.black : AppColors.fuchsia,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    data.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF81747A),
                      fontSize: 11.5,
                      height: 1.15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: AppColors.fuchsia),
          ],
        ),
      ),
    );
  }
}

class _ModuleData {
  const _ModuleData({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isVersionTwo = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isVersionTwo;
}
