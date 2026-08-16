import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/training_session_model.dart';
import '../repositories/training_repository.dart';
import 'training_form_screen.dart';

class TrainingDetailScreen extends StatelessWidget {
  const TrainingDetailScreen({super.key, required this.session});

  final TrainingSessionModel session;

  TrainingRepository get _repository => const TrainingRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FA),
      appBar: AppBar(
        backgroundColor: AppColors.darkFuchsia,
        foregroundColor: AppColors.white,
        title: const Text(
          'Detalle del entrenamiento',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.categoryName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 24),

                _item(
                  Icons.calendar_month_rounded,
                  'Fecha',
                  _formatDate(session.date),
                ),

                _item(
                  Icons.schedule_rounded,
                  'Horario',
                  '${_formatTime(session.startTime)} - '
                      '${_formatTime(session.endTime)}',
                ),

                _item(
                  Icons.location_on_rounded,
                  'Lugar',
                  session.location.isEmpty ? 'No registrado' : session.location,
                ),

                _item(
                  Icons.person_rounded,
                  'Entrenador',
                  session.coachName.isEmpty
                      ? 'No registrado'
                      : session.coachName,
                ),

                const Divider(height: 40),

                const Text(
                  'Objetivo',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                Text(session.objective.isEmpty ? '-' : session.objective),

                const SizedBox(height: 24),

                const Text(
                  'Materiales',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                Text(session.materials.isEmpty ? '-' : session.materials),

                const SizedBox(height: 24),

                const Text(
                  'Observaciones',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                Text(session.notes.isEmpty ? '-' : session.notes),

                const SizedBox(height: 30),

                _buildEditButton(context),

                const SizedBox(height: 12),

                if (session.status == 'completed')
                  _buildCompletedMessage()
                else
                  _buildCompleteButton(context),

                const SizedBox(height: 12),

                _buildDeleteButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        onPressed: () async {
          final TrainingSessionModel? updated = await Navigator.of(context)
              .push(
                MaterialPageRoute<TrainingSessionModel>(
                  builder: (_) => TrainingFormScreen(session: session),
                ),
              );

          if (updated == null || !context.mounted) {
            return;
          }

          Navigator.of(context).pop();
        },
        icon: const Icon(Icons.edit_rounded),
        label: const Text(
          'EDITAR ENTRENAMIENTO',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.fuchsia,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildCompleteButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        onPressed: () async {
          final bool? confirmed = await showDialog<bool>(
            context: context,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: const Text(
                  'Completar entrenamiento',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                content: Text(
                  '¿Quieres marcar '
                  '${session.categoryName} '
                  'como completado?',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(false);
                    },
                    child: const Text('CANCELAR'),
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(true);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF168A55),
                      foregroundColor: AppColors.white,
                    ),
                    child: const Text(
                      'COMPLETAR',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              );
            },
          );

          if (confirmed != true || !context.mounted) {
            return;
          }

          try {
            await _repository.updateStatus(id: session.id, status: 'completed');

            if (!context.mounted) {
              return;
            }

            Navigator.of(context).pop();
          } catch (error) {
            if (!context.mounted) {
              return;
            }

            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: const Color(0xFFC62828),
                  content: Text(
                    'No fue posible completar '
                    'el entrenamiento.\n$error',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
          }
        },
        icon: const Icon(Icons.check_circle_rounded),
        label: const Text(
          'MARCAR COMO COMPLETADO',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF168A55),
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE4F7ED),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_rounded, color: Color(0xFF168A55)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'ENTRENAMIENTO COMPLETADO',
              style: TextStyle(
                color: Color(0xFF168A55),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: () async {
          final bool? confirmed = await showDialog<bool>(
            context: context,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: const Text(
                  'Eliminar entrenamiento',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                content: Text(
                  '¿Quieres eliminar '
                  '${session.categoryName}?\n\n'
                  'Esta acción no se puede deshacer.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(false);
                    },
                    child: const Text('CANCELAR'),
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(true);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFC62828),
                      foregroundColor: AppColors.white,
                    ),
                    child: const Text(
                      'ELIMINAR',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              );
            },
          );

          if (confirmed != true || !context.mounted) {
            return;
          }

          try {
            await _repository.deleteTrainingSession(session.id);

            if (!context.mounted) {
              return;
            }

            Navigator.of(context).pop();
          } catch (error) {
            if (!context.mounted) {
              return;
            }

            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: const Color(0xFFC62828),
                  content: Text(
                    'No fue posible eliminar '
                    'el entrenamiento.\n$error',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
          }
        },
        icon: const Icon(Icons.delete_outline_rounded),
        label: const Text(
          'ELIMINAR ENTRENAMIENTO',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFC62828),
          side: const BorderSide(color: Color(0xFFC62828), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _item(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          Icon(icon, color: AppColors.fuchsia),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static String _formatTime(String value) {
    if (value.length >= 5) {
      return value.substring(0, 5);
    }

    return value;
  }
}
