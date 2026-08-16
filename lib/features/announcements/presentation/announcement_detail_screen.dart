import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/announcement_model.dart';
import '../repositories/announcement_repository.dart';
import 'announcement_form_screen.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  const AnnouncementDetailScreen({required this.announcement, super.key});

  final AnnouncementModel announcement;

  @override
  State<AnnouncementDetailScreen> createState() {
    return _AnnouncementDetailScreenState();
  }
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  final AnnouncementRepository _repository = const AnnouncementRepository();

  late AnnouncementModel _announcement;

  bool _isWorking = false;
  bool _wasChanged = false;

  @override
  void initState() {
    super.initState();
    _announcement = widget.announcement;
  }

  Future<void> _editAnnouncement() async {
    final AnnouncementModel? updated = await Navigator.of(context)
        .push<AnnouncementModel>(
          MaterialPageRoute<AnnouncementModel>(
            builder: (_) => AnnouncementFormScreen(announcement: _announcement),
          ),
        );

    if (updated == null || !mounted) {
      return;
    }

    Navigator.of(context).pop<bool>(true);
  }

  Future<void> _archiveAnnouncement() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'Archivar comunicado',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: const Text(
            'El comunicado quedará guardado como archivado y dejará de estar activo.',
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
                backgroundColor: AppColors.fuchsia,
                foregroundColor: AppColors.white,
              ),
              child: const Text(
                'ARCHIVAR',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isWorking = true;
    });

    try {
      await _repository.updateStatus(id: _announcement.id, status: 'archived');

      final AnnouncementModel? refreshed = await _repository
          .getAnnouncementById(_announcement.id);

      if (!mounted) {
        return;
      }

      setState(() {
        if (refreshed != null) {
          _announcement = refreshed;
        } else {
          _announcement = _announcement.copyWith(status: 'archived');
        }

        _wasChanged = true;
      });

      _showMessage('Comunicado archivado correctamente.');
    } catch (error) {
      debugPrint('Error al archivar comunicado: $error');

      if (!mounted) {
        return;
      }

      _showMessage('No fue posible archivar el comunicado.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  Future<void> _publishAnnouncement() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'Publicar comunicado',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: const Text('El comunicado quedará marcado como publicado.'),
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
                backgroundColor: AppColors.fuchsia,
                foregroundColor: AppColors.white,
              ),
              child: const Text(
                'PUBLICAR',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isWorking = true;
    });

    try {
      await _repository.updateStatus(id: _announcement.id, status: 'published');

      final AnnouncementModel? refreshed = await _repository
          .getAnnouncementById(_announcement.id);

      if (!mounted) {
        return;
      }

      setState(() {
        if (refreshed != null) {
          _announcement = refreshed;
        } else {
          _announcement = _announcement.copyWith(status: 'published');
        }

        _wasChanged = true;
      });

      _showMessage('Comunicado publicado correctamente.');
    } catch (error) {
      debugPrint('Error al publicar comunicado: $error');

      if (!mounted) {
        return;
      }

      _showMessage('No fue posible publicar el comunicado.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  Future<void> _deleteAnnouncement() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'Eliminar comunicado',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: const Text(
            'Esta acción eliminará definitivamente el comunicado. ¿Deseas continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('NO'),
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

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isWorking = true;
    });

    try {
      await _repository.deleteAnnouncement(_announcement.id);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop<bool>(true);
    } catch (error) {
      debugPrint('Error al eliminar comunicado: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _isWorking = false;
      });

      _showMessage('No fue posible eliminar el comunicado.', isError: true);
    }
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
    final _PriorityStyle priorityStyle = _PriorityStyle.fromPriority(
      _announcement.priority,
    );

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
            'Detalle del comunicado',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          actions: [
            IconButton(
              tooltip: 'Editar',
              onPressed: _isWorking ? null : _editAnnouncement,
              icon: const Icon(Icons.edit_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
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
                            announcement: _announcement,
                            priorityStyle: priorityStyle,
                          ),
                          const SizedBox(height: 16),
                          _MessageCard(message: _announcement.message),
                          const SizedBox(height: 16),
                          _InformationCard(announcement: _announcement),
                          const SizedBox(height: 16),
                          _ActionsCard(
                            announcement: _announcement,
                            isWorking: _isWorking,
                            onEdit: _editAnnouncement,
                            onPublish: _publishAnnouncement,
                            onArchive: _archiveAnnouncement,
                            onDelete: _deleteAnnouncement,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.announcement, required this.priorityStyle});

  final AnnouncementModel announcement;
  final _PriorityStyle priorityStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: priorityStyle.color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: priorityStyle.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(
                  priorityStyle.icon,
                  color: priorityStyle.color,
                  size: 29,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        _Badge(
                          label: announcement.priorityLabel,
                          color: priorityStyle.color,
                        ),
                        _Badge(
                          label: announcement.statusLabel,
                          color: _statusColor(announcement.status),
                        ),
                      ],
                    ),
                    const SizedBox(height: 11),
                    Text(
                      announcement.title,
                      style: const TextStyle(
                        color: AppColors.black,
                        fontSize: 21,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.fuchsia.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notes_rounded, color: AppColors.fuchsia),
              SizedBox(width: 9),
              Text(
                'Mensaje',
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SelectableText(
            message,
            style: const TextStyle(
              color: Color(0xFF554B50),
              fontSize: 14,
              height: 1.55,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({required this.announcement});

  final AnnouncementModel announcement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.fuchsia.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.fuchsia),
              SizedBox(width: 9),
              Text(
                'Información',
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _InfoRow(
            icon: Icons.people_alt_rounded,
            label: 'Destinatarios',
            value: announcement.audienceLabel,
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.calendar_month_rounded,
            label: 'Fecha de publicación',
            value: _formatDate(announcement.publishDate),
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.flag_rounded,
            label: 'Prioridad',
            value: announcement.priorityLabel,
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.visibility_rounded,
            label: 'Estado',
            value: announcement.statusLabel,
          ),
        ],
      ),
    );
  }
}

class _ActionsCard extends StatelessWidget {
  const _ActionsCard({
    required this.announcement,
    required this.isWorking,
    required this.onEdit,
    required this.onPublish,
    required this.onArchive,
    required this.onDelete,
  });

  final AnnouncementModel announcement;
  final bool isWorking;

  final VoidCallback onEdit;
  final VoidCallback onPublish;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

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
          const Text(
            'Acciones',
            style: TextStyle(
              color: AppColors.black,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 15),
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
              'EDITAR COMUNICADO',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),

          if (!announcement.isPublished) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: isWorking ? null : onPublish,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.fuchsia,
                minimumSize: const Size.fromHeight(50),
                side: const BorderSide(color: AppColors.fuchsia),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: const Icon(Icons.visibility_rounded),
              label: const Text(
                'PUBLICAR',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],

          if (!announcement.isArchived) ...[
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
                'ARCHIVAR',
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
              'ELIMINAR COMUNICADO',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),

          if (isWorking) ...[
            const SizedBox(height: 12),
            const Center(
              child: CircularProgressIndicator(color: AppColors.fuchsia),
            ),
          ],
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
                value,
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

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          letterSpacing: 0.4,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PriorityStyle {
  const _PriorityStyle({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  factory _PriorityStyle.fromPriority(String priority) {
    switch (priority) {
      case 'urgent':
        return const _PriorityStyle(
          color: Color(0xFFC62828),
          icon: Icons.warning_amber_rounded,
        );

      case 'important':
        return const _PriorityStyle(
          color: Color(0xFFE19A00),
          icon: Icons.priority_high_rounded,
        );

      default:
        return const _PriorityStyle(
          color: AppColors.fuchsia,
          icon: Icons.campaign_rounded,
        );
    }
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'draft':
      return const Color(0xFF81747A);

    case 'archived':
      return const Color(0xFF6D6D6D);

    default:
      return const Color(0xFF168A55);
  }
}

String _formatDate(DateTime date) {
  final String day = date.day.toString().padLeft(2, '0');

  final String month = date.month.toString().padLeft(2, '0');

  return '$day/$month/${date.year}';
}
