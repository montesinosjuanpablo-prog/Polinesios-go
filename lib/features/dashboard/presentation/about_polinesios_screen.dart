import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';

class AboutPolinesiosScreen extends StatelessWidget {
  const AboutPolinesiosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2F4),
      appBar: AppBar(
        backgroundColor: AppColors.darkFuchsia,
        foregroundColor: AppColors.white,
        title: const Text(
          'Acerca de',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
          child: Column(
            children: [
              SizedBox(
                width: 124,
                height: 124,
                child: Image.asset(
                  AppAssets.logo,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.shield_rounded,
                      color: AppColors.fuchsia,
                      size: 76,
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'POLINESIOS GO',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.darkFuchsia,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'Versión 1.0',
                style: TextStyle(
                  color: Color(0xFF7B6F75),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.darkFuchsia, AppColors.fuchsia],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.format_quote_rounded,
                      color: AppColors.yellow,
                      size: 34,
                    ),
                    SizedBox(height: 8),
                    Text(
                      '“Respeto, Disciplina y Pasión, '
                      'esa es nuestra Formación”',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 17,
                        height: 1.5,
                        fontWeight: FontWeight.w800,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              const _AboutCard(
                icon: Icons.sports_soccer_rounded,
                title: 'Nuestra aplicación',
                child: Text(
                  'Polinesios GO fue creada para apoyar '
                  'la gestión de la Escuela Formativa '
                  'Polinesios y acompañar la formación '
                  'deportiva y humana de nuestros niños, '
                  'niñas y jóvenes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF675B61),
                    fontSize: 14,
                    height: 1.55,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              const _AboutCard(
                icon: Icons.code_rounded,
                title: 'Creación y desarrollo',
                child: Column(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Proyecto y dirección',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF81747A),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Juan Pablo Montesinos Nasz Eddine',
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.darkFuchsia,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Coach Titulado N° 11527',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Real Federación Española de Fútbol',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF675B61),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 18),

                    _CreditItem(
                      label: 'Asistencia en desarrollo e IA',
                      value: 'Cami · ChatGPT · OpenAI',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              const _AboutCard(
                icon: Icons.favorite_rounded,
                title: 'Gracias',
                child: Text(
                  'A nuestras familias, entrenadores, '
                  'colaboradores y, especialmente, a '
                  'nuestros futbolistas, quienes dan '
                  'sentido a cada paso de este proyecto.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF675B61),
                    fontSize: 14,
                    height: 1.55,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Escuela Formativa Polinesios',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.darkFuchsia,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'La Paz · Bolivia 🇧🇴',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF81747A),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Polinesios GO · v1.0',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF9A8D93),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.fuchsia.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.yellow.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: AppColors.darkFuchsia, size: 26),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _CreditItem extends StatelessWidget {
  const _CreditItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF81747A),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.darkFuchsia,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
