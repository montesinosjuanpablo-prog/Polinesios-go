import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/match_model.dart';
import '../repositories/match_repository.dart';
import 'match_detail_screen.dart';
import 'match_form_screen.dart';

class MatchListScreen extends StatefulWidget {
  const MatchListScreen({super.key});

  @override
  State<MatchListScreen> createState() {
    return _MatchListScreenState();
  }
}

class _MatchListScreenState extends State<MatchListScreen> {
  final MatchRepository _repository = const MatchRepository();

  bool _isLoading = true;
  String? _errorMessage;

  List<MatchModel> _matches = <MatchModel>[];

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<MatchModel> matches = await _repository.getMatches();

      if (!mounted) {
        return;
      }

      setState(() {
        _matches = matches;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Error al cargar partidos: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'No fue posible cargar los partidos.\n\n$error';
      });
    }
  }

  Future<void> _createMatch() async {
    final MatchModel? created = await Navigator.of(context).push<MatchModel>(
      MaterialPageRoute<MatchModel>(builder: (_) => const MatchFormScreen()),
    );

    if (created == null || !mounted) {
      return;
    }

    await _loadMatches();

    if (!mounted) {
      return;
    }

    _showSuccess('Partido creado correctamente.');
  }

  Future<void> _openMatch(
  MatchModel match,
) async {
  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) =>
          MatchDetailScreen(match: match),
    ),
  );

  if (!mounted) {
    return;
  }

  await _loadMatches();
}

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF168A55),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2F4),
      appBar: AppBar(
        backgroundColor: AppColors.darkFuchsia,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Partidos',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadMatches,
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createMatch,
        backgroundColor: AppColors.fuchsia,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'NUEVO',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.fuchsia,
        onRefresh: _loadMatches,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        physics: AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 180),
          Center(child: CircularProgressIndicator(color: AppColors.fuchsia)),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 90),
          Icon(
            Icons.cloud_off_rounded,
            size: 62,
            color: AppColors.fuchsia.withValues(alpha: 0.65),
          ),
          const SizedBox(height: 18),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton.icon(
              onPressed: _loadMatches,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('REINTENTAR'),
            ),
          ),
        ],
      );
    }

    if (_matches.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 90),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.fuchsia.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: AppColors.fuchsia,
              size: 50,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Todavía no existen partidos registrados.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.black,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pulsa NUEVO para registrar el primer '
            'partido de Polinesios.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF786C72),
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
      itemCount: _matches.length,
      separatorBuilder: (BuildContext context, int index) {
        return const SizedBox(height: 12);
      },
      itemBuilder: (BuildContext context, int index) {
        final MatchModel match = _matches[index];

        return _MatchCard(
          match: match,
          onPressed: () {
            _openMatch(match);
          },
        );
      },
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match, required this.onPressed});

  final MatchModel match;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final _MatchStatusStyle statusStyle = _MatchStatusStyle.fromStatus(
      match.status,
    );

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.fuchsia.withValues(alpha: 0.12),
            ),
          ),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = constraints.maxWidth < 360;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: compact ? 54 : 62,
                    height: compact ? 54 : 62,
                    decoration: BoxDecoration(
                      color: AppColors.yellow.withValues(alpha: 0.30),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: const Icon(
                      Icons.sports_soccer_rounded,
                      color: AppColors.black,
                      size: 30,
                    ),
                  ),
                  SizedBox(width: compact ? 11 : 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _matchTitle(match),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _matchInformation(match),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF786C72),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 7,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _StatusBadge(style: statusStyle),
                            _SimpleBadge(
                              icon: Icons.swap_horiz_rounded,
                              label: match.homeAwayLabel,
                            ),
                            if (match.hasResult)
                              _ResultBadge(
                                goalsFor: match.goalsFor!,
                                goalsAgainst: match.goalsAgainst!,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.fuchsia,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  static String _matchTitle(MatchModel match) {
    switch (match.homeAway) {
      case 'away':
        return '${match.opponentName} vs Polinesios';

      default:
        return 'Polinesios vs ${match.opponentName}';
    }
  }

  static String _matchInformation(MatchModel match) {
    final String date = _formatDate(match.matchDate);

    final String time = _formatTime(match.startTime);

    final String group = match.trainingGroupName.trim().isEmpty
        ? 'Sin grupo'
        : match.trainingGroupName;

    final String location = match.locationName.trim().isEmpty
        ? 'Sin lugar'
        : match.locationName;

    return '$date · $time\n$group · $location';
  }

  static String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');

    final String month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  static String _formatTime(String value) {
    if (value.trim().isEmpty) {
      return 'Sin hora';
    }

    return value.length >= 5 ? value.substring(0, 5) : value;
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.style});

  final _MatchStatusStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: style.color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, color: style.color, size: 14),
          const SizedBox(width: 5),
          Text(
            style.label,
            style: TextStyle(
              color: style.color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleBadge extends StatelessWidget {
  const _SimpleBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F2F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECE2E7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.fuchsia, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF5F5359),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.goalsFor, required this.goalsAgainst});

  final int goalsFor;
  final int goalsAgainst;

  @override
  Widget build(BuildContext context) {
    final bool victory = goalsFor > goalsAgainst;

    final bool draw = goalsFor == goalsAgainst;

    final Color color = victory
        ? const Color(0xFF168A55)
        : draw
        ? const Color(0xFFE08200)
        : const Color(0xFFC62828);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        '$goalsFor - $goalsAgainst',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MatchStatusStyle {
  const _MatchStatusStyle({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  factory _MatchStatusStyle.fromStatus(String status) {
    switch (status) {
      case 'in_progress':
        return const _MatchStatusStyle(
          label: 'En juego',
          color: Color(0xFFE08200),
          icon: Icons.play_circle_rounded,
        );

      case 'completed':
        return const _MatchStatusStyle(
          label: 'Finalizado',
          color: Color(0xFF168A55),
          icon: Icons.check_circle_rounded,
        );

      case 'cancelled':
        return const _MatchStatusStyle(
          label: 'Cancelado',
          color: Color(0xFFC62828),
          icon: Icons.cancel_rounded,
        );

      default:
        return const _MatchStatusStyle(
          label: 'Programado',
          color: AppColors.fuchsia,
          icon: Icons.schedule_rounded,
        );
    }
  }
}
