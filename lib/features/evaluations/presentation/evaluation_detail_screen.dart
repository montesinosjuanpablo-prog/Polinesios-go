import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/evaluation_model.dart';
import '../repositories/evaluation_repository.dart';
import 'evaluation_form_screen.dart';

class EvaluationDetailScreen extends StatefulWidget {
  const EvaluationDetailScreen({required this.evaluation, super.key});

  final EvaluationModel evaluation;

  @override
  State<EvaluationDetailScreen> createState() {
    return _EvaluationDetailScreenState();
  }
}

class _EvaluationDetailScreenState extends State<EvaluationDetailScreen> {
  final EvaluationRepository _repository = const EvaluationRepository();

  late EvaluationModel _evaluation;

  bool _isWorking = false;
  bool _wasChanged = false;

  @override
  void initState() {
    super.initState();
    _evaluation = widget.evaluation;
  }

  Future<void> _editEvaluation() async {
    final EvaluationModel? updated = await Navigator.of(context)
        .push<EvaluationModel>(
          MaterialPageRoute<EvaluationModel>(
            builder: (_) => EvaluationFormScreen(evaluation: _evaluation),
          ),
        );

    if (updated == null || !mounted) {
      return;
    }

    setState(() {
      _evaluation = updated;
      _wasChanged = true;
    });

    _showMessage('Evaluación actualizada correctamente.');
  }

  Future<void> _archiveEvaluation() async {
    final bool? confirmed = await _confirmationDialog(
      title: 'Archivar evaluación',
      message:
          'La evaluación quedará archivada, pero seguirá guardada en el historial del jugador.',
      confirmLabel: 'ARCHIVAR',
      confirmColor: const Color(0xFF81747A),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _changeStatus(
      'archived',
      successMessage: 'Evaluación archivada correctamente.',
    );
  }

  Future<void> _restoreEvaluation() async {
    final bool? confirmed = await _confirmationDialog(
      title: 'Reactivar evaluación',
      message: 'La evaluación volverá a quedar como completada.',
      confirmLabel: 'REACTIVAR',
      confirmColor: AppColors.fuchsia,
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _changeStatus(
      'completed',
      successMessage: 'Evaluación reactivada correctamente.',
    );
  }

  Future<void> _completeEvaluation() async {
    final bool? confirmed = await _confirmationDialog(
      title: 'Completar evaluación',
      message: 'El borrador quedará marcado como evaluación completada.',
      confirmLabel: 'COMPLETAR',
      confirmColor: const Color(0xFF168A55),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _changeStatus(
      'completed',
      successMessage: 'Evaluación completada correctamente.',
    );
  }

  Future<void> _changeStatus(
    String status, {
    required String successMessage,
  }) async {
    setState(() {
      _isWorking = true;
    });

    try {
      await _repository.updateStatus(id: _evaluation.id, status: status);

      final EvaluationModel? refreshed = await _repository.getEvaluationById(
        _evaluation.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        if (refreshed != null) {
          _evaluation = refreshed;
        } else {
          _evaluation = _evaluation.copyWith(status: status);
        }

        _wasChanged = true;
      });

      _showMessage(successMessage);
    } catch (error) {
      debugPrint('Error al cambiar estado de evaluación: $error');

      if (!mounted) {
        return;
      }

      _showMessage('No fue posible actualizar la evaluación.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  Future<void> _deleteEvaluation() async {
    final bool? confirmed = await _confirmationDialog(
      title: 'Eliminar evaluación',
      message:
          '¿Quieres eliminar definitivamente la evaluación de ${_evaluation.playerName}?\n\nEsta acción no se puede deshacer.',
      confirmLabel: 'ELIMINAR',
      confirmColor: const Color(0xFFC62828),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isWorking = true;
    });

    try {
      await _repository.deleteEvaluation(_evaluation.id);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop<bool>(true);
    } catch (error) {
      debugPrint('Error al eliminar evaluación: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _isWorking = false;
      });

      _showMessage('No fue posible eliminar la evaluación.', isError: true);
    }
  }

  Future<bool?> _confirmationDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('VOLVER'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: confirmColor,
                foregroundColor: AppColors.white,
              ),
              child: Text(
                confirmLabel,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );
  }

  void _closeScreen() {
    Navigator.of(context).pop<bool>(_wasChanged);
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError
              ? const Color(0xFFC62828)
              : const Color(0xFF168A55),
          content: Text(
            message,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final _EvaluationStatusStyle statusStyle =
        _EvaluationStatusStyle.fromStatus(_evaluation.status);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          return;
        }

        _closeScreen();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F2F4),
        appBar: AppBar(
          backgroundColor: AppColors.darkFuchsia,
          foregroundColor: AppColors.white,
          leading: IconButton(
            tooltip: 'Volver',
            onPressed: _closeScreen,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text(
            'Detalle de evaluación',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          actions: [
            IconButton(
              tooltip: 'Editar',
              onPressed: _isWorking ? null : _editEvaluation,
              icon: const Icon(Icons.edit_rounded),
            ),
          ],
        ),
        body: Stack(
          children: [
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double maxWidth = constraints.maxWidth >= 900
                    ? 780
                    : constraints.maxWidth;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 120),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _HeaderCard(
                              evaluation: _evaluation,
                              statusStyle: statusStyle,
                            ),
                            const SizedBox(height: 16),
                            _ScoresCard(evaluation: _evaluation),
                            const SizedBox(height: 16),
                            _DevelopmentCard(evaluation: _evaluation),
                            const SizedBox(height: 16),
                            _InformationCard(evaluation: _evaluation),
                            const SizedBox(height: 16),
                            _ActionsCard(
                              evaluation: _evaluation,
                              isWorking: _isWorking,
                              onEdit: _editEvaluation,
                              onComplete: _completeEvaluation,
                              onArchive: _archiveEvaluation,
                              onRestore: _restoreEvaluation,
                              onDelete: _deleteEvaluation,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            if (_isWorking)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.16),
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.fuchsia),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.evaluation, required this.statusStyle});

  final EvaluationModel evaluation;
  final _EvaluationStatusStyle statusStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.darkFuchsia, AppColors.fuchsia],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.fuchsia.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusStyle.label.toUpperCase(),
                style: TextStyle(
                  color: statusStyle.color,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            evaluation.playerName.trim().isEmpty
                ? 'Jugador'
                : evaluation.playerName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.yellow,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 3),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  evaluation.averageScore.toStringAsFixed(1),
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  'PROMEDIO',
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _formatDate(evaluation.evaluationDate),
            style: const TextStyle(
              color: Color(0xFFEADDE4),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoresCard extends StatelessWidget {
  const _ScoresCard({required this.evaluation});

  final EvaluationModel evaluation;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Valoración por áreas',
      icon: Icons.insights_rounded,
      child: Column(
        children: [
          _ScoreRow(
            label: 'Técnica',
            icon: Icons.sports_soccer_rounded,
            value: evaluation.technicalScore,
          ),
          const SizedBox(height: 14),
          _ScoreRow(
            label: 'Táctica',
            icon: Icons.schema_rounded,
            value: evaluation.tacticalScore,
          ),
          const SizedBox(height: 14),
          _ScoreRow(
            label: 'Físico',
            icon: Icons.fitness_center_rounded,
            value: evaluation.physicalScore,
          ),
          const SizedBox(height: 14),
          _ScoreRow(
            label: 'Actitud',
            icon: Icons.favorite_rounded,
            value: evaluation.attitudeScore,
          ),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.label,
    required this.icon,
    required this.value,
  });

  final String label;
  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) {
    final double progress = value / 5;

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.fuchsia.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.fuchsia, size: 20),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Container(
              width: 39,
              height: 39,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.yellow.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$value',
                style: const TextStyle(
                  color: AppColors.black,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: const Color(0xFFF0E7EB),
            color: AppColors.fuchsia,
          ),
        ),
      ],
    );
  }
}

class _DevelopmentCard extends StatelessWidget {
  const _DevelopmentCard({required this.evaluation});

  final EvaluationModel evaluation;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Seguimiento formativo',
      icon: Icons.edit_note_rounded,
      child: Column(
        children: [
          _TextInformation(
            title: 'Fortalezas',
            icon: Icons.star_rounded,
            text: evaluation.strengths,
            emptyText: 'Sin fortalezas registradas.',
          ),
          const SizedBox(height: 16),
          _TextInformation(
            title: 'Aspectos a mejorar',
            icon: Icons.trending_up_rounded,
            text: evaluation.areasToImprove,
            emptyText: 'Sin aspectos de mejora registrados.',
          ),
          const SizedBox(height: 16),
          _TextInformation(
            title: 'Observaciones',
            icon: Icons.notes_rounded,
            text: evaluation.observations,
            emptyText: 'Sin observaciones.',
          ),
        ],
      ),
    );
  }
}

class _TextInformation extends StatelessWidget {
  const _TextInformation({
    required this.title,
    required this.icon,
    required this.text,
    required this.emptyText,
  });

  final String title;
  final IconData icon;
  final String text;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.fuchsia, size: 19),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          SelectableText(
            text.trim().isEmpty ? emptyText : text,
            style: const TextStyle(
              color: Color(0xFF675B61),
              fontSize: 12.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({required this.evaluation});

  final EvaluationModel evaluation;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Información',
      icon: Icons.info_outline_rounded,
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.person_rounded,
            label: 'Jugador',
            value: evaluation.playerName,
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.calendar_month_rounded,
            label: 'Fecha',
            value: _formatDate(evaluation.evaluationDate),
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.sports_rounded,
            label: 'Evaluador',
            value: evaluation.evaluatorName.trim().isEmpty
                ? 'Evaluador no registrado'
                : evaluation.evaluatorName,
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.fact_check_rounded,
            label: 'Estado',
            value: evaluation.statusLabel,
          ),
        ],
      ),
    );
  }
}

class _ActionsCard extends StatelessWidget {
  const _ActionsCard({
    required this.evaluation,
    required this.isWorking,
    required this.onEdit,
    required this.onComplete,
    required this.onArchive,
    required this.onRestore,
    required this.onDelete,
  });

  final EvaluationModel evaluation;
  final bool isWorking;

  final VoidCallback onEdit;
  final VoidCallback onComplete;
  final VoidCallback onArchive;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Acciones',
      icon: Icons.settings_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: isWorking ? null : onEdit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.fuchsia,
              foregroundColor: AppColors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            icon: const Icon(Icons.edit_rounded),
            label: const Text(
              'EDITAR EVALUACIÓN',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),

          if (evaluation.isDraft) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: isWorking ? null : onComplete,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF168A55),
                minimumSize: const Size.fromHeight(50),
                side: const BorderSide(color: Color(0xFF168A55)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text(
                'MARCAR COMO COMPLETADA',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],

          if (!evaluation.isArchived) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: isWorking ? null : onArchive,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF81747A),
                minimumSize: const Size.fromHeight(50),
                side: const BorderSide(color: Color(0xFFBBAFB5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: const Icon(Icons.archive_rounded),
              label: const Text(
                'ARCHIVAR EVALUACIÓN',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: isWorking ? null : onRestore,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.fuchsia,
                minimumSize: const Size.fromHeight(50),
                side: const BorderSide(color: AppColors.fuchsia),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: const Icon(Icons.unarchive_rounded),
              label: const Text(
                'REACTIVAR EVALUACIÓN',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],

          const SizedBox(height: 10),

          TextButton.icon(
            onPressed: isWorking ? null : onDelete,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFC62828),
              minimumSize: const Size.fromHeight(48),
            ),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text(
              'ELIMINAR EVALUACIÓN',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.fuchsia.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.fuchsia),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 39,
          height: 39,
          decoration: BoxDecoration(
            color: AppColors.fuchsia.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.fuchsia, size: 20),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF81747A),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value.trim().isEmpty ? 'No registrado' : value,
                style: const TextStyle(
                  color: AppColors.black,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
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
          color: Color(0xFFE4D3DB),
        );

      case 'archived':
        return const _EvaluationStatusStyle(
          label: 'Archivada',
          color: Color(0xFFD0C5CA),
        );

      default:
        return const _EvaluationStatusStyle(
          label: 'Completada',
          color: Color(0xFF8FF0BD),
        );
    }
  }
}

String _formatDate(DateTime date) {
  final String day = date.day.toString().padLeft(2, '0');

  final String month = date.month.toString().padLeft(2, '0');

  return '$day/$month/${date.year}';
}
