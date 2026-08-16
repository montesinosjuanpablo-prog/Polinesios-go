import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/announcement_model.dart';
import '../repositories/announcement_repository.dart';
import 'announcement_detail_screen.dart';
import 'announcement_form_screen.dart';

class AnnouncementListScreen extends StatefulWidget {
  const AnnouncementListScreen({super.key});

  @override
  State<AnnouncementListScreen> createState() {
    return _AnnouncementListScreenState();
  }
}

class _AnnouncementListScreenState extends State<AnnouncementListScreen> {
  final AnnouncementRepository _repository = const AnnouncementRepository();

  List<AnnouncementModel> _announcements = <AnnouncementModel>[];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final List<AnnouncementModel> announcements = await _repository
          .getAnnouncements();

      if (!mounted) {
        return;
      }

      setState(() {
        _announcements = announcements;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Error al cargar comunicados: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'No fue posible cargar los comunicados.';
      });
    }
  }

  Future<void> _createAnnouncement() async {
    final AnnouncementModel? created = await Navigator.of(context)
        .push<AnnouncementModel>(
          MaterialPageRoute<AnnouncementModel>(
            builder: (_) => const AnnouncementFormScreen(),
          ),
        );

    if (created == null || !mounted) {
      return;
    }

    await _loadAnnouncements();

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
            'Comunicado creado correctamente.',
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
  }

  Future<void> _openAnnouncement(AnnouncementModel announcement) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AnnouncementDetailScreen(announcement: announcement),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadAnnouncements();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2F4),
      appBar: AppBar(
        backgroundColor: AppColors.darkFuchsia,
        foregroundColor: AppColors.white,
        title: const Text(
          'Comunicados',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _isLoading ? null : _loadAnnouncements,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.fuchsia,
        onRefresh: _loadAnnouncements,
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createAnnouncement,
        backgroundColor: AppColors.fuchsia,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'NUEVO',
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
          _ErrorState(message: _errorMessage!, onRetry: _loadAnnouncements),
        ],
      );
    }

    if (_announcements.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 80, 24, 120),
        children: [_EmptyState(onCreate: _createAnnouncement)],
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool wide = constraints.maxWidth >= 760;

        if (wide) {
          return GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
            itemCount: _announcements.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 2.05,
            ),
            itemBuilder: (BuildContext context, int index) {
              final AnnouncementModel announcement = _announcements[index];

              return _AnnouncementCard(
                announcement: announcement,
                onPressed: () {
                  _openAnnouncement(announcement);
                },
              );
            },
          );
        }

        return ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
          itemCount: _announcements.length,
          separatorBuilder: (BuildContext context, int index) {
            return const SizedBox(height: 12);
          },
          itemBuilder: (BuildContext context, int index) {
            final AnnouncementModel announcement = _announcements[index];

            return _AnnouncementCard(
              announcement: announcement,
              onPressed: () {
                _openAnnouncement(announcement);
              },
            );
          },
        );
      },
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.announcement,
    required this.onPressed,
  });

  final AnnouncementModel announcement;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final _PriorityStyle priorityStyle = _PriorityStyle.fromPriority(
      announcement.priority,
    );

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
              color: priorityStyle.color.withValues(alpha: 0.28),
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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: priorityStyle.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(priorityStyle.icon, color: priorityStyle.color),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 7,
                      runSpacing: 6,
                      children: [
                        _SmallBadge(
                          label: announcement.priorityLabel,
                          color: priorityStyle.color,
                        ),
                        if (!announcement.isPublished)
                          _SmallBadge(
                            label: announcement.statusLabel,
                            color: const Color(0xFF81747A),
                          ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Text(
                      announcement.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      announcement.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF71656B),
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.people_alt_rounded,
                          size: 15,
                          color: AppColors.fuchsia,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            announcement.audienceLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF81747A),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(announcement.publishDate),
                          style: const TextStyle(
                            color: Color(0xFF81747A),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
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

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({required this.label, required this.color});

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
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
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
        constraints: const BoxConstraints(maxWidth: 460),
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
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: AppColors.fuchsia.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.campaign_rounded,
                  color: AppColors.fuchsia,
                  size: 39,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Aún no hay comunicados',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Mantén informada a toda la Familia Polinesios desde un solo lugar.',
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
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'CREAR PRIMER COMUNICADO',
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

String _formatDate(DateTime date) {
  final String day = date.day.toString().padLeft(2, '0');

  final String month = date.month.toString().padLeft(2, '0');

  return '$day/$month/${date.year}';
}
