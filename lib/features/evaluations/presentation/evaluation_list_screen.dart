import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/evaluation_model.dart';
import '../repositories/evaluation_repository.dart';
import 'evaluation_detail_screen.dart';
import 'evaluation_form_screen.dart';

class EvaluationListScreen extends StatefulWidget {
  const EvaluationListScreen({super.key});

  @override
  State<EvaluationListScreen> createState() {
    return _EvaluationListScreenState();
  }
}

class _EvaluationListScreenState extends State<EvaluationListScreen> {
  final EvaluationRepository _repository = const EvaluationRepository();

  List<EvaluationModel> _evaluations = <EvaluationModel>[];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEvaluations();
  }

  Future<void> _loadEvaluations() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final List<EvaluationModel> evaluations = await _repository
          .getEvaluations();

      if (!mounted) {
        return;
      }

      setState(() {
        _evaluations = evaluations;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Error al cargar evaluaciones: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'No fue posible cargar las evaluaciones.';
      });
    }
  }

  Future<void> _createEvaluation() async {
    final EvaluationModel? created = await Navigator.of(context)
        .push<EvaluationModel>(
          MaterialPageRoute<EvaluationModel>(
            builder: (_) => const EvaluationFormScreen(),
          ),
        );

    if (created == null || !mounted) {
      return;
    }

    await _loadEvaluations();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF168A55),
          content: Text(
            'Evaluación registrada correctamente.',
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
  }

  Future<void> _openEvaluation(EvaluationModel evaluation) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => EvaluationDetailScreen(evaluation: evaluation),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadEvaluations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2F4),
      appBar: AppBar(
        backgroundColor: AppColors.darkFuchsia,
        foregroundColor: AppColors.white,
        title: const Text(
          'Evaluaciones',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _isLoading ? null : _loadEvaluations,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.fuchsia,
        onRefresh: _loadEvaluations,
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createEvaluation,
        backgroundColor: AppColors.fuchsia,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add_chart_rounded),
        label: const Text(
          'NUEVA',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 190),
          Center(child: CircularProgressIndicator(color: AppColors.fuchsia)),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          _ErrorState(message: _errorMessage!, onRetry: _loadEvaluations),
        ],
      );
    }

    if (_evaluations.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 80, 24, 120),
        children: [_EmptyState(onCreate: _createEvaluation)],
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool wide = constraints.maxWidth >= 760;

        if (wide) {
          return GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
            itemCount: _evaluations.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 2.05,
            ),
            itemBuilder: (BuildContext context, int index) {
              final EvaluationModel evaluation = _evaluations[index];

              return _EvaluationCard(
                evaluation: evaluation,
                onPressed: () {
                  _openEvaluation(evaluation);
                },
              );
            },
          );
        }

        return ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
          itemCount: _evaluations.length,
          separatorBuilder: (BuildContext context, int index) {
            return const SizedBox(height: 12);
          },
          itemBuilder: (BuildContext context, int index) {
            final EvaluationModel evaluation = _evaluations[index];

            return _EvaluationCard(
              evaluation: evaluation,
              onPressed: () {
                _openEvaluation(evaluation);
              },
            );
          },
        );
      },
    );
  }
}

class _EvaluationCard extends StatelessWidget {
  const _EvaluationCard({required this.evaluation, required this.onPressed});

  final EvaluationModel evaluation;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final _EvaluationStatusStyle statusStyle =
        _EvaluationStatusStyle.fromStatus(evaluation.status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.fuchsia.withValues(alpha: 0.14),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AverageCircle(value: evaluation.averageScore),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 7,
                      runSpacing: 6,
                      children: [
                        _Badge(
                          label: statusStyle.label,
                          color: statusStyle.color,
                        ),
                        _Badge(
                          label: _formatDate(evaluation.evaluationDate),
                          color: AppColors.fuchsia,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      evaluation.playerName.trim().isEmpty
                          ? 'Jugador sin nombre'
                          : evaluation.playerName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _ScoresSummary(evaluation: evaluation),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.sports_rounded,
                          size: 15,
                          color: AppColors.fuchsia,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            evaluation.evaluatorName.trim().isEmpty
                                ? 'Evaluador no registrado'
                                : evaluation.evaluatorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF81747A),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: AppColors.fuchsia),
            ],
          ),
        ),
      ),
    );
  }
}

class _AverageCircle extends StatelessWidget {
  const _AverageCircle({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.darkFuchsia, AppColors.fuchsia],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.yellow, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.fuchsia.withValues(alpha: 0.20),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Text(
          value.toStringAsFixed(1),
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ScoresSummary extends StatelessWidget {
  const _ScoresSummary({required this.evaluation});

  final EvaluationModel evaluation;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        _ScoreMiniBadge(label: 'Téc.', value: evaluation.technicalScore),
        _ScoreMiniBadge(label: 'Tác.', value: evaluation.tacticalScore),
        _ScoreMiniBadge(label: 'Fís.', value: evaluation.physicalScore),
        _ScoreMiniBadge(label: 'Act.', value: evaluation.attitudeScore),
      ],
    );
  }
}

class _ScoreMiniBadge extends StatelessWidget {
  const _ScoreMiniBadge({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.fuchsia.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(
          color: AppColors.fuchsia,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          letterSpacing: 0.3,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 470),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: AppColors.fuchsia.withValues(alpha: 0.11),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.yellow.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: AppColors.fuchsia,
                  size: 41,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Aún no hay evaluaciones',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Registra el progreso técnico, táctico, físico y formativo de cada jugador.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF81747A),
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: onCreate,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.fuchsia,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.add_chart_rounded),
                  label: const Text(
                    'CREAR PRIMERA EVALUACIÓN',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 58,
              color: AppColors.fuchsia,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('REINTENTAR'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EvaluationStatusStyle {
  const _EvaluationStatusStyle({required this.label, required this.color});

  final String label;
  final Color color;

  factory _EvaluationStatusStyle.fromStatus(String status) {
    switch (status) {
      case 'draft':
        return const _EvaluationStatusStyle(
          label: 'Borrador',
          color: Color(0xFF81747A),
        );

      case 'archived':
        return const _EvaluationStatusStyle(
          label: 'Archivada',
          color: Color(0xFF6D6D6D),
        );

      default:
        return const _EvaluationStatusStyle(
          label: 'Completada',
          color: Color(0xFF168A55),
        );
    }
  }
}

String _formatDate(DateTime date) {
  final String day = date.day.toString().padLeft(2, '0');

  final String month = date.month.toString().padLeft(2, '0');

  return '$day/$month/${date.year}';
}
