import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/match_model.dart';
import '../repositories/match_repository.dart';
import 'match_form_screen.dart';

class MatchDetailScreen extends StatefulWidget {
  const MatchDetailScreen({required this.match, super.key});

  final MatchModel match;

  @override
  State<MatchDetailScreen> createState() {
    return _MatchDetailScreenState();
  }
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  final MatchRepository _repository = const MatchRepository();

  late MatchModel _match;

  bool _isWorking = false;

  @override
  void initState() {
    super.initState();
    _match = widget.match;
  }

  Future<void> _editMatch() async {
    final MatchModel? updated = await Navigator.of(context).push<MatchModel>(
      MaterialPageRoute<MatchModel>(
        builder: (_) => MatchFormScreen(match: _match),
      ),
    );

    if (updated == null || !mounted) {
      return;
    }

    setState(() {
      _match = updated;
    });
  }

  Future<void> _reprogramMatch() async {
    final MatchModel? updated = await Navigator.of(context).push<MatchModel>(
      MaterialPageRoute<MatchModel>(
        builder: (_) => MatchFormScreen(match: _match, isRescheduling: true),
      ),
    );

    if (updated == null || !mounted) {
      return;
    }

    setState(() {
      _match = updated;
    });

    _showMessage('Partido reprogramado correctamente.');
  }

  Future<void> _showCancelOrReprogramOptions() async {
    final String? action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Cancelar o reprogramar',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                const Text(
                  '¿Qué deseas hacer con este partido?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF786C72),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop('reprogram');
                    },
                    icon: const Icon(Icons.event_repeat_rounded),
                    label: const Text(
                      'REPROGRAMAR PARTIDO',
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
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop('cancel');
                    },
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text(
                      'CANCELAR PARTIDO',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFC62828),
                      side: const BorderSide(color: Color(0xFFC62828)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                  },
                  child: const Text('VOLVER'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) {
      return;
    }

    if (action == 'reprogram') {
      await _reprogramMatch();
      return;
    }

    if (action == 'cancel') {
      await _cancelMatch();
    }
  }

  Future<void> _registerResult() async {
    final _MatchResult? result = await showDialog<_MatchResult>(
      context: context,
      builder: (BuildContext dialogContext) {
        return _ResultDialog(match: _match);
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _isWorking = true;
    });

    try {
      await _repository.updateResult(
        id: _match.id,
        goalsFor: result.goalsFor,
        goalsAgainst: result.goalsAgainst,
      );

      final MatchModel? refreshed = await _repository.getMatchById(_match.id);

      if (!mounted) {
        return;
      }

      if (refreshed != null) {
        setState(() {
          _match = refreshed;
        });
      }

      _showMessage('Resultado guardado correctamente.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'No fue posible guardar el resultado.\n$error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  Future<void> _cancelMatch() async {
    final bool? confirmed = await _confirmationDialog(
      title: 'Cancelar partido',
      message: '¿Quieres marcar este partido como cancelado?',
      confirmLabel: 'CANCELAR PARTIDO',
      confirmColor: const Color(0xFFC62828),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _changeStatus('cancelled');
  }

  Future<void> _changeStatus(String status) async {
    setState(() {
      _isWorking = true;
    });

    try {
      await _repository.updateStatus(id: _match.id, status: status);

      final MatchModel? refreshed = await _repository.getMatchById(_match.id);

      if (!mounted) {
        return;
      }

      if (refreshed != null) {
        setState(() {
          _match = refreshed;
        });
      }

      if (status == 'cancelled') {
        _showMessage('Partido cancelado correctamente.');
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'No fue posible actualizar el partido.\n$error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  Future<void> _deleteMatch() async {
    final bool? confirmed = await _confirmationDialog(
      title: 'Eliminar partido',
      message:
          '¿Quieres eliminar definitivamente '
          '${_matchTitle(_match)}?\n\n'
          'Esta acción no se puede deshacer.',
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
      await _repository.deleteMatch(_match.id);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop<bool>(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'No fue posible eliminar el partido.\n$error',
        isError: true,
      );

      setState(() {
        _isWorking = false;
      });
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
    final _DetailStatusStyle statusStyle = _DetailStatusStyle.fromStatus(
      _match.status,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF6F2F4),
      appBar: AppBar(
        backgroundColor: AppColors.darkFuchsia,
        foregroundColor: AppColors.white,
        title: const Text(
          'Detalle del partido',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 34),
            children: [
              _ScoreHeader(match: _match, statusStyle: statusStyle),
              const SizedBox(height: 16),
              _InformationCard(match: _match),
              const SizedBox(height: 16),
              _NotesCard(notes: _match.notes),
              const SizedBox(height: 20),
              _buildActions(),
            ],
          ),
          if (_isWorking)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.18),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.fuchsia),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: _isWorking ? null : _editMatch,
            icon: const Icon(Icons.edit_rounded),
            label: const Text(
              'EDITAR PARTIDO',
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
        ),
        const SizedBox(height: 10),

        if (!_match.isCancelled)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _isWorking ? null : _registerResult,
              icon: const Icon(Icons.scoreboard_rounded),
              label: Text(
                _match.hasResult ? 'EDITAR RESULTADO' : 'REGISTRAR RESULTADO',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF168A55),
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

        if (!_match.isCancelled) const SizedBox(height: 10),

        if (_match.isCancelled)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _isWorking ? null : _reprogramMatch,
              icon: const Icon(Icons.event_repeat_rounded),
              label: const Text(
                'REPROGRAMAR PARTIDO',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.fuchsia,
                side: const BorderSide(color: AppColors.fuchsia),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _isWorking ? null : _showCancelOrReprogramOptions,
              icon: const Icon(Icons.event_repeat_rounded),
              label: const Text(
                'CANCELAR / REPROGRAMAR',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.fuchsia,
                side: const BorderSide(color: AppColors.fuchsia),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: _isWorking ? null : _deleteMatch,
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text(
              'ELIMINAR PARTIDO',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFC62828),
              side: const BorderSide(color: Color(0xFFC62828)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultDialog extends StatefulWidget {
  const _ResultDialog({required this.match});

  final MatchModel match;

  @override
  State<_ResultDialog> createState() {
    return _ResultDialogState();
  }
}

class _ResultDialogState extends State<_ResultDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _goalsForController;

  late final TextEditingController _goalsAgainstController;

  @override
  void initState() {
    super.initState();

    _goalsForController = TextEditingController(
      text: widget.match.goalsFor?.toString() ?? '',
    );

    _goalsAgainstController = TextEditingController(
      text: widget.match.goalsAgainst?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _goalsForController.dispose();
    _goalsAgainstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.match.hasResult ? 'Editar resultado' : 'Registrar resultado',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _matchTitle(widget.match),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _goalsForController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      labelText: 'Polinesios',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateGoals,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    '-',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: _goalsAgainstController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      labelText: widget.match.opponentName,
                      border: const OutlineInputBorder(),
                    ),
                    validator: _validateGoals,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('CANCELAR'),
        ),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF168A55),
            foregroundColor: AppColors.white,
          ),
          child: const Text(
            'GUARDAR RESULTADO',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final int goalsFor = int.parse(_goalsForController.text.trim());

    final int goalsAgainst = int.parse(_goalsAgainstController.text.trim());

    Navigator.of(
      context,
    ).pop(_MatchResult(goalsFor: goalsFor, goalsAgainst: goalsAgainst));
  }

  static String? _validateGoals(String? value) {
    final String text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Requerido';
    }

    final int? goals = int.tryParse(text);

    if (goals == null || goals < 0) {
      return 'Inválido';
    }

    return null;
  }
}

class _MatchResult {
  const _MatchResult({required this.goalsFor, required this.goalsAgainst});

  final int goalsFor;
  final int goalsAgainst;
}

class _ScoreHeader extends StatelessWidget {
  const _ScoreHeader({required this.match, required this.statusStyle});

  final MatchModel match;
  final _DetailStatusStyle statusStyle;

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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusStyle.icon, color: statusStyle.color, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    statusStyle.label,
                    style: TextStyle(
                      color: statusStyle.color,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _matchTitle(match),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          if (match.hasResult)
            Text(
              '${match.goalsFor}  -  ${match.goalsAgainst}',
              style: const TextStyle(
                color: AppColors.yellow,
                fontSize: 40,
                fontWeight: FontWeight.w900,
              ),
            )
          else
            const Text(
              'VS',
              style: TextStyle(
                color: AppColors.yellow,
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      ),
    );
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({required this.match});

  final MatchModel match;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.fuchsia.withValues(alpha: 0.11)),
      ),
      child: Column(
        children: [
          _InformationRow(
            icon: Icons.calendar_month_rounded,
            label: 'Fecha',
            value: _formatDate(match.matchDate),
          ),
          _InformationRow(
            icon: Icons.schedule_rounded,
            label: 'Hora',
            value: _formatTime(match.startTime),
          ),
          _InformationRow(
            icon: Icons.groups_rounded,
            label: 'Grupo / categoría',
            value: match.trainingGroupName.trim().isEmpty
                ? 'No registrado'
                : match.trainingGroupName,
          ),
          _InformationRow(
            icon: Icons.location_on_rounded,
            label: 'Lugar',
            value: match.locationName.trim().isEmpty
                ? 'No registrado'
                : match.locationName,
          ),
          _InformationRow(
            icon: Icons.swap_horiz_rounded,
            label: 'Condición',
            value: match.homeAwayLabel,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 17),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.fuchsia.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.fuchsia, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF81747A),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.fuchsia.withValues(alpha: 0.11)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notes_rounded, color: AppColors.fuchsia),
              SizedBox(width: 8),
              Text(
                'Observaciones',
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            notes.trim().isEmpty ? 'Sin observaciones.' : notes,
            style: const TextStyle(
              color: Color(0xFF675B61),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailStatusStyle {
  const _DetailStatusStyle({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  factory _DetailStatusStyle.fromStatus(String status) {
    switch (status) {
      case 'in_progress':
        return const _DetailStatusStyle(
          label: 'EN JUEGO',
          color: AppColors.yellow,
          icon: Icons.play_circle_rounded,
        );

      case 'completed':
        return const _DetailStatusStyle(
          label: 'FINALIZADO',
          color: Color(0xFF8FF0BD),
          icon: Icons.check_circle_rounded,
        );

      case 'cancelled':
        return const _DetailStatusStyle(
          label: 'CANCELADO',
          color: Color(0xFFFFA5A5),
          icon: Icons.cancel_rounded,
        );

      default:
        return const _DetailStatusStyle(
          label: 'PROGRAMADO',
          color: AppColors.yellow,
          icon: Icons.schedule_rounded,
        );
    }
  }
}

String _matchTitle(MatchModel match) {
  if (match.homeAway == 'away') {
    return '${match.opponentName} vs Polinesios';
  }

  return 'Polinesios vs ${match.opponentName}';
}

String _formatDate(DateTime date) {
  final String day = date.day.toString().padLeft(2, '0');

  final String month = date.month.toString().padLeft(2, '0');

  return '$day/$month/${date.year}';
}

String _formatTime(String value) {
  if (value.trim().isEmpty) {
    return 'Sin hora';
  }

  return value.length >= 5 ? value.substring(0, 5) : value;
}
