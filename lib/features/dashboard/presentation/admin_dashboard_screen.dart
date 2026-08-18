import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../attendance/presentation/attendance_screen.dart';
import '../../payments/presentation/admin_payments_screen.dart';
import '../../payments/presentation/school_financial_summary_screen.dart';
import '../../payments/repositories/payment_repository.dart';
import '../../players/presentation/players_screen.dart';
import '../../training/presentation/training_list_screen.dart';
import '../data/dashboard_service.dart';
import '../../matches/presentation/match_list_screen.dart';
import '../../announcements/presentation/announcement_list_screen.dart';
import '../../evaluations/presentation/evaluation_list_screen.dart';
import '../../documents/presentation/document_list_screen.dart';
import 'about_polinesios_screen.dart';
import 'identity_polinesios_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() {
    return _AdminDashboardScreenState();
  }
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  int _dashboardRefreshVersion = 0;

  final List<_NavigationItemData> _navigationItems =
      const <_NavigationItemData>[
        _NavigationItemData(
          label: 'Inicio',
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
        ),
        _NavigationItemData(
          label: 'Jugadores',
          icon: Icons.groups_outlined,
          selectedIcon: Icons.groups_rounded,
        ),
        _NavigationItemData(
          label: 'Asistencia',
          icon: Icons.fact_check_outlined,
          selectedIcon: Icons.fact_check_rounded,
        ),
        _NavigationItemData(
          label: 'Pagos',
          icon: Icons.payments_outlined,
          selectedIcon: Icons.payments_rounded,
        ),
        _NavigationItemData(
          label: 'Más',
          icon: Icons.grid_view_outlined,
          selectedIcon: Icons.grid_view_rounded,
        ),
      ];

  void _selectSection(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _refreshDashboard() {
    if (!mounted) {
      return;
    }

    setState(() {
      _dashboardRefreshVersion++;
    });
  }

  Future<void> _openModule(String moduleName) async {
    final String normalizedModuleName = moduleName.trim();

    debugPrint('MÓDULO PULSADO: "$normalizedModuleName"');

    switch (normalizedModuleName) {
      case 'Jugadores':
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const PlayersScreen()),
        );
        return;

      case 'Asistencia':
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const AttendanceScreen()),
        );
        return;

      case 'Pagos':
        _selectSection(3);
        return;

      case 'Entrenamientos':
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const TrainingListScreen()),
        );
        return;

      case 'Partidos':
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const MatchListScreen()),
        );

        if (!mounted) {
          return;
        }

        _refreshDashboard();
        return;

      case 'Comunicados':
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const AnnouncementListScreen(),
          ),
        );

        if (!mounted) {
          return;
        }

        _refreshDashboard();
        return;

      case 'Evaluaciones':
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const EvaluationListScreen()),
        );
        return;

      case 'Documentos':
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const DocumentListScreen()),
        );
        return;

      case 'Acerca de':
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const AboutPolinesiosScreen(),
          ),
        );
        return;

      case 'Identidad Polinesios':
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const IdentityPolinesiosScreen(),
          ),
        );
        return;

      default:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.darkFuchsia,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
              content: Row(
                children: [
                  const Icon(
                    Icons.construction_rounded,
                    color: AppColors.yellow,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$normalizedModuleName estará disponible muy pronto.',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
    }
  }

  Future<void> _confirmLogout() async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: const Icon(
            Icons.logout_rounded,
            color: AppColors.fuchsia,
            size: 48,
          ),
          title: const Text(
            'Cerrar sesión',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: const Text(
            '¿Deseas salir de Polinesios GO?',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
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
              child: const Text('SALIR'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !mounted) {
      return;
    }

    Navigator.of(context).pop();
  }

  Future<bool> _confirmExitApp() async {
    final bool? shouldExit = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: const Icon(
            Icons.exit_to_app_rounded,
            color: AppColors.fuchsia,
            size: 48,
          ),
          title: const Text(
            'Salir de Polinesios GO',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: const Text(
            '¿Está seguro de que desea salir de la aplicación?',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
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
              child: const Text('SALIR'),
            ),
          ],
        );
      },
    );

    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final Widget selectedPage;

    switch (_selectedIndex) {
      case 1:
        selectedPage = const PlayersScreen();
        break;
      case 2:
        selectedPage = const AttendanceScreen();
        break;
      case 3:
        selectedPage = const AdminPaymentsScreen();
        break;
      case 4:
        selectedPage = _MoreModules(
          onModulePressed: _openModule,
          onLogoutPressed: _confirmLogout,
        );
        break;
      case 0:
      default:
        selectedPage = _DashboardHome(
          key: ValueKey<int>(_dashboardRefreshVersion),
          onModulePressed: _openModule,
        );
        break;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }

        if (_selectedIndex != 0) {
          _selectSection(0);
          return;
        }

        final bool shouldExit = await _confirmExitApp();

        if (shouldExit) {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F2F4),
        body: selectedPage,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _selectSection,
          backgroundColor: AppColors.white,
          indicatorColor: AppColors.fuchsia.withValues(alpha: 0.16),
          surfaceTintColor: AppColors.white,
          destinations: _navigationItems.map((_NavigationItemData item) {
            return NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon, color: AppColors.fuchsia),
              label: item.label,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _DashboardHome extends StatefulWidget {
  const _DashboardHome({super.key, required this.onModulePressed});

  final ValueChanged<String> onModulePressed;

  @override
  State<_DashboardHome> createState() {
    return _DashboardHomeState();
  }
}

class _DashboardHomeState extends State<_DashboardHome> {
  final DashboardService _dashboardService = const DashboardService();
  final PaymentRepository _paymentRepository = const PaymentRepository();

  bool _loading = true;

  DashboardPlayerSummary _playerSummary = const DashboardPlayerSummary(
    totalPlayers: 0,
    groupCounts: <String, int>{},
    withoutGroup: 0,
  );

  List<DashboardActivity> _upcomingActivities = <DashboardActivity>[];
  List<DashboardBirthday> _upcomingBirthdays = <DashboardBirthday>[];
  List<DashboardAnnouncement> _expiringAnnouncements =
      <DashboardAnnouncement>[];
  Map<String, dynamic>? _financialSummary;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<Map<String, dynamic>?> _loadFinancialSummary() async {
    final DateTime now = DateTime.now();

    try {
      return await _paymentRepository.getSchoolManualFinancialSummary(
        year: now.year,
        month: now.month,
      );
    } catch (error) {
      debugPrint('Error al cargar finanzas del dashboard: $error');
      return null;
    }
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
    });

    try {
      final Future<DashboardPlayerSummary> summaryFuture = _dashboardService
          .playerSummary();

      final Future<List<DashboardActivity>> activitiesFuture = _dashboardService
          .upcomingActivities(limit: 2);

      final Future<List<DashboardBirthday>> birthdaysFuture = _dashboardService
          .upcomingBirthdays(daysAhead: 3, limit: 3);

      final Future<List<DashboardAnnouncement>> announcementsFuture =
          _dashboardService.expiringAnnouncements(
            daysBeforeExpiry: 3,
            limit: 2,
          );

      final Future<Map<String, dynamic>?> financialFuture =
          _loadFinancialSummary();

      final List<dynamic> results =
          await Future.wait<dynamic>(<Future<dynamic>>[
            summaryFuture,
            activitiesFuture,
            birthdaysFuture,
            announcementsFuture,
            financialFuture,
          ]);

      final DashboardPlayerSummary summary =
          results[0] as DashboardPlayerSummary;

      final List<DashboardActivity> activities =
          results[1] as List<DashboardActivity>;

      final List<DashboardBirthday> birthdays =
          results[2] as List<DashboardBirthday>;

      final List<DashboardAnnouncement> announcements =
          results[3] as List<DashboardAnnouncement>;

      final Map<String, dynamic>? financialSummary =
          results[4] as Map<String, dynamic>?;

      if (!mounted) {
        return;
      }

      setState(() {
        _playerSummary = summary;
        _upcomingActivities = activities;
        _upcomingBirthdays = birthdays;
        _expiringAnnouncements = announcements;
        _financialSummary = financialSummary;
      });
    } catch (error) {
      debugPrint('Error al cargar el dashboard: $error');

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.fuchsia,
            content: Text('No fue posible actualizar el resumen.'),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.fuchsia,
      onRefresh: _loadDashboard,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const _DashboardHeader(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
            sliver: SliverList(
              delegate: SliverChildListDelegate(<Widget>[
                const _WelcomeMessage(),

                const SizedBox(height: 22),

                if (_loading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 14),
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      color: AppColors.yellow,
                      backgroundColor: Color(0xFFE6D3DE),
                    ),
                  ),

                _PlayerSummaryCard(
                  summary: _playerSummary,
                  onViewRoster: () {
                    widget.onModulePressed('Jugadores');
                  },
                ),

                const SizedBox(height: 22),

                _FinanceDashboardCard(
                  summary: _financialSummary,
                  onView: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const SchoolFinancialSummaryScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 22),

                _PolinesiosPulseCard(
                  birthdays: _upcomingBirthdays,
                  activities: _upcomingActivities,
                  announcements: _expiringAnnouncements,
                  onOpenActivities: () {
                    widget.onModulePressed('Entrenamientos');
                  },
                  onOpenAnnouncements: () {
                    widget.onModulePressed('Comunicados');
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 168,
      backgroundColor: AppColors.darkFuchsia,
      foregroundColor: AppColors.white,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text('No tienes notificaciones nuevas.'),
                ),
              );
          },
          tooltip: 'Notificaciones',
          icon: const Icon(Icons.notifications_outlined),
        ),
        const SizedBox(width: 6),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.darkFuchsia,
                AppColors.fuchsia,
                Color(0xFF7D0045),
              ],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool compact = constraints.maxWidth < 390;
                final double watermarkSize = compact ? 132 : 148;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      left: compact ? 4 : 8,
                      top: compact ? 8 : 4,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: 0.17,
                          child: SizedBox(
                            width: watermarkSize,
                            height: watermarkSize,
                            child: Image.asset(
                              AppAssets.logo,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.shield_rounded,
                                  color: AppColors.white,
                                  size: compact ? 92 : 104,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 24 : 30,
                        10,
                        compact ? 58 : 68,
                        18,
                      ),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'POLINESIOS GO',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: compact ? 23 : 27,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Escuela Formativa de Fútbol Polinesios',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: compact ? 11 : 13,
                                fontWeight: FontWeight.w600,
                              ),
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
      ),
    );
  }
}

class _WelcomeMessage extends StatelessWidget {
  const _WelcomeMessage();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 360;
        final double beeSize = compact ? 44 : 52;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: compact ? 16 : 19,
          ),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: beeSize + (compact ? 8 : 12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '¡A Por Todo!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.fuchsia,
                        fontSize: compact ? 19 : 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Coach Juan Pablo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: compact ? 16 : 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 0,
                child: _SimpleBeeMark(
                  color: AppColors.yellow,
                  facingRight: false,
                  size: beeSize,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PlayerSummaryCard extends StatelessWidget {
  const _PlayerSummaryCard({required this.summary, required this.onViewRoster});

  final DashboardPlayerSummary summary;
  final VoidCallback onViewRoster;

  @override
  Widget build(BuildContext context) {
    final List<_GroupSummaryData> groups = <_GroupSummaryData>[
      _GroupSummaryData(label: 'Kids AM', value: summary.countFor('Kids AM')),
      _GroupSummaryData(label: 'Kids PM', value: summary.countFor('Kids PM')),
      _GroupSummaryData(
        label: 'Junior AM',
        value: summary.countFor('Junior AM'),
      ),
      _GroupSummaryData(
        label: 'Junior PM',
        value: summary.countFor('Junior PM'),
      ),
    ];

    return Container(
      width: double.infinity,
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
            color: AppColors.fuchsia.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.yellow,
                size: 24,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'POLINESIOS HOY',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                summary.totalPlayers.toString(),
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 46,
                  height: 0.95,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    'jugadores activos',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: groups.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: constraints.maxWidth >= 620 ? 4 : 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.35,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final _GroupSummaryData data = groups[index];

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            data.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          data.value.toString(),
                          style: const TextStyle(
                            color: AppColors.yellow,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          if (summary.withoutGroup > 0) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.yellow.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_search_rounded,
                    color: AppColors.yellow,
                    size: 20,
                  ),
                  const SizedBox(width: 9),
                  const Expanded(
                    child: Text(
                      'Sin grupo asignado',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    summary.withoutGroup.toString(),
                    style: const TextStyle(
                      color: AppColors.yellow,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: onViewRoster,
              icon: const Icon(Icons.groups_2_rounded),
              label: const Text(
                'VER PLANTEL',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.yellow,
                foregroundColor: AppColors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceDashboardCard extends StatelessWidget {
  const _FinanceDashboardCard({required this.summary, required this.onView});

  final Map<String, dynamic>? summary;
  final VoidCallback onView;

  String _monthName(int month) {
    const List<String> months = <String>[
      'ENERO',
      'FEBRERO',
      'MARZO',
      'ABRIL',
      'MAYO',
      'JUNIO',
      'JULIO',
      'AGOSTO',
      'SEPTIEMBRE',
      'OCTUBRE',
      'NOVIEMBRE',
      'DICIEMBRE',
    ];

    if (month < 1 || month > 12) {
      return 'PERÍODO ACTUAL';
    }

    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final Map<String, dynamic>? data = summary;

    final double totalCollected = data == null
        ? 0
        : _dashboardToDouble(data['total_collected']);

    final int paymentCount = data == null
        ? 0
        : _dashboardToInt(data['payment_count']);

    final int playersWithPayments = data == null
        ? 0
        : _dashboardToInt(data['players_with_payments']);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.fuchsia.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 15,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.fuchsia.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.fuchsia,
                  size: 27,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FINANZAS',
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_monthName(now.month)} ${now.year}',
                      style: const TextStyle(
                        color: Color(0xFF81747A),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onView,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.fuchsia,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('VER', style: TextStyle(fontWeight: FontWeight.w900)),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (data == null)
            const Text(
              'Sin información financiera disponible para el período actual.',
              style: TextStyle(
                color: Color(0xFF81747A),
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            )
          else ...[
            const Text(
              'Ingresos confirmados',
              style: TextStyle(
                color: Color(0xFF81747A),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _dashboardFormatMoney(totalCollected),
              style: const TextStyle(
                color: AppColors.fuchsia,
                fontSize: 31,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _FinanceDashboardMetric(
                    label: 'Pagos',
                    value: '$paymentCount',
                    color: const Color(0xFF168A55),
                  ),
                ),
                Container(width: 1, height: 38, color: const Color(0xFFE7DDE2)),
                Expanded(
                  child: _FinanceDashboardMetric(
                    label: 'Jugadores',
                    value: '$playersWithPayments',
                    color: AppColors.fuchsia,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FinanceDashboardMetric extends StatelessWidget {
  const _FinanceDashboardMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF81747A),
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

double _dashboardToDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _dashboardToInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _dashboardFormatMoney(double amount) {
  final bool hasDecimals = amount != amount.roundToDouble();

  return hasDecimals
      ? '${amount.toStringAsFixed(2)} Bs'
      : '${amount.toStringAsFixed(0)} Bs';
}

class _PolinesiosPulseCard extends StatelessWidget {
  const _PolinesiosPulseCard({
    required this.birthdays,
    required this.activities,
    required this.announcements,
    required this.onOpenActivities,
    required this.onOpenAnnouncements,
  });

  final List<DashboardBirthday> birthdays;
  final List<DashboardActivity> activities;
  final List<DashboardAnnouncement> announcements;
  final VoidCallback onOpenActivities;
  final VoidCallback onOpenAnnouncements;

  @override
  Widget build(BuildContext context) {
    final bool hasContent =
        birthdays.isNotEmpty ||
        activities.isNotEmpty ||
        announcements.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.fuchsia.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 15,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.yellow.withValues(alpha: 0.30),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.fuchsia,
                  size: 27,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PULSO POLINESIOS',
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Lo que está pasando en nuestra escuela',
                      style: TextStyle(
                        color: Color(0xFF81747A),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!hasContent) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F4F6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: AppColors.fuchsia),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Todo tranquilo por ahora. Las novedades importantes '
                      'aparecerán aquí automáticamente.',
                      style: TextStyle(
                        color: Color(0xFF756A70),
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (birthdays.isNotEmpty) ...[
            const SizedBox(height: 18),
            _PulseSection(
              icon: Icons.cake_rounded,
              iconBackground: AppColors.fuchsia.withValues(alpha: 0.10),
              iconColor: AppColors.fuchsia,
              title: birthdays.length == 1
                  ? 'CUMPLEAÑOS'
                  : 'CUMPLEAÑOS PRÓXIMOS',
              child: Column(
                children: List<Widget>.generate(birthdays.length, (int index) {
                  final DashboardBirthday birthday = birthdays[index];

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == birthdays.length - 1 ? 0 : 10,
                    ),
                    child: _BirthdayPulseRow(birthday: birthday),
                  );
                }),
              ),
            ),
          ],
          if (activities.isNotEmpty) ...[
            const SizedBox(height: 14),
            _PulseSection(
              icon: Icons.emoji_events_rounded,
              iconBackground: AppColors.yellow.withValues(alpha: 0.28),
              iconColor: AppColors.black,
              title: activities.length == 1
                  ? 'PRÓXIMA ACTIVIDAD'
                  : 'PRÓXIMAS ACTIVIDADES',
              trailing: TextButton(
                onPressed: onOpenActivities,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.fuchsia,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 6,
                  ),
                ),
                child: const Text(
                  'VER',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              child: Column(
                children: List<Widget>.generate(
                  activities.length,
                  (int index) => Padding(
                    padding: EdgeInsets.only(
                      bottom: index == activities.length - 1 ? 0 : 12,
                    ),
                    child: _ActivityPulseContent(activity: activities[index]),
                  ),
                ),
              ),
            ),
          ],
          if (announcements.isNotEmpty) ...[
            const SizedBox(height: 14),
            _PulseSection(
              icon: Icons.campaign_rounded,
              iconBackground: const Color(0xFFFFF1C9),
              iconColor: const Color(0xFFB97800),
              title: announcements.length == 1 ? 'COMUNICADO' : 'COMUNICADOS',
              trailing: TextButton(
                onPressed: onOpenAnnouncements,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.fuchsia,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 6,
                  ),
                ),
                child: const Text(
                  'VER',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              child: Column(
                children: List<Widget>.generate(
                  announcements.length,
                  (int index) => Padding(
                    padding: EdgeInsets.only(
                      bottom: index == announcements.length - 1 ? 0 : 12,
                    ),
                    child: _AnnouncementPulseContent(
                      announcement: announcements[index],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PulseSection extends StatelessWidget {
  const _PulseSection({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8F9),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFEDE4E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: iconColor, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (trailing case final Widget trailingWidget) trailingWidget,
            ],
          ),
          const SizedBox(height: 11),
          child,
        ],
      ),
    );
  }
}

class _BirthdayPulseRow extends StatelessWidget {
  const _BirthdayPulseRow({required this.birthday});

  final DashboardBirthday birthday;

  @override
  Widget build(BuildContext context) {
    final String timing;

    if (birthday.isToday) {
      timing = '¡HOY!';
    } else if (birthday.daysUntilBirthday == 1) {
      timing = 'MAÑANA';
    } else {
      timing = 'EN ${birthday.daysUntilBirthday} DÍAS';
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            birthday.playerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.black,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: birthday.isToday
                ? AppColors.fuchsia
                : AppColors.fuchsia.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            timing,
            style: TextStyle(
              color: birthday.isToday ? AppColors.white : AppColors.fuchsia,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActivityPulseContent extends StatelessWidget {
  const _ActivityPulseContent({required this.activity});

  final DashboardActivity activity;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 62,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.fuchsia,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Column(
            children: [
              Text(
                _formatDate(activity.date),
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatTime(activity.startTime),
                style: const TextStyle(
                  color: AppColors.yellow,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.black,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFF887B81),
                    size: 16,
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      activity.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF786C72),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _formatDate(DateTime date) {
    const List<String> weekdays = <String>[
      'LUN',
      'MAR',
      'MIÉ',
      'JUE',
      'VIE',
      'SÁB',
      'DOM',
    ];

    return '${weekdays[date.weekday - 1]} '
        '${date.day.toString().padLeft(2, '0')}';
  }

  static String _formatTime(String time) {
    return time.length >= 5 ? time.substring(0, 5) : time;
  }
}

class _AnnouncementPulseContent extends StatelessWidget {
  const _AnnouncementPulseContent({required this.announcement});

  final DashboardAnnouncement announcement;

  @override
  Widget build(BuildContext context) {
    final int days = announcement.daysUntilExpiry(DateTime.now());

    final String expiryLabel;

    if (days == 0) {
      expiryLabel = 'VENCE HOY';
    } else if (days == 1) {
      expiryLabel = 'VENCE MAÑANA';
    } else {
      expiryLabel = 'VENCE EN $days DÍAS';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                announcement.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.black,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE7A3),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                expiryLabel,
                style: const TextStyle(
                  color: Color(0xFF8A5A00),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        if (announcement.message.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            announcement.message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF756A70),
              fontSize: 12.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _MoreModules extends StatelessWidget {
  const _MoreModules({
    required this.onModulePressed,
    required this.onLogoutPressed,
  });

  final ValueChanged<String> onModulePressed;

  final VoidCallback onLogoutPressed;

  @override
  Widget build(BuildContext context) {
    const List<_QuickAccessData> modules = <_QuickAccessData>[
      _QuickAccessData(
        title: 'Entrenamientos',
        icon: Icons.sports_soccer_rounded,
      ),
      _QuickAccessData(title: 'Partidos', icon: Icons.emoji_events_rounded),
      _QuickAccessData(title: 'Evaluaciones', icon: Icons.insights_rounded),
      _QuickAccessData(title: 'Comunicados', icon: Icons.campaign_rounded),
      _QuickAccessData(title: 'Documentos', icon: Icons.folder_rounded),
      _QuickAccessData(title: 'Acerca de', icon: Icons.info_outline_rounded),
      _QuickAccessData(
        title: 'Identidad Polinesios',
        icon: Icons.hive_outlined,
      ),
      _QuickAccessData(title: 'Configuración', icon: Icons.settings_rounded),
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 25, 20, 30),
        children: [
          const Text(
            'Más opciones',
            style: TextStyle(
              color: AppColors.black,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Accede a todas las herramientas de administración.',
            style: TextStyle(color: Color(0xFF766B70)),
          ),

          const SizedBox(height: 24),

          ...modules.map((_QuickAccessData module) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                onTap: () {
                  onModulePressed(module.title);
                },
                tileColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                leading: CircleAvatar(
                  backgroundColor: AppColors.fuchsia.withValues(alpha: 0.12),
                  child: module.title == 'Identidad Polinesios'
                      ? const _SimpleBeeMark(
                          color: AppColors.fuchsia,
                          facingRight: true,
                          size: 28,
                        )
                      : Icon(module.icon, color: AppColors.fuchsia),
                ),
                title: Text(
                  module.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
            );
          }),

          const SizedBox(height: 14),

          OutlinedButton.icon(
            onPressed: onLogoutPressed,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Cerrar sesión'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleBeeMark extends StatelessWidget {
  const _SimpleBeeMark({
    required this.color,
    required this.facingRight,
    required this.size,
  });

  final Color color;
  final bool facingRight;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _SimpleBeePainter(color: color, facingRight: facingRight),
      ),
    );
  }
}

class _SimpleBeePainter extends CustomPainter {
  const _SimpleBeePainter({required this.color, required this.facingRight});

  final Color color;
  final bool facingRight;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    if (!facingRight) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }

    final double w = size.width;
    final double h = size.height;

    final Color detailColor = color == AppColors.yellow
        ? const Color(0xFF3E3036)
        : AppColors.darkFuchsia;

    final Paint bodyPaint = Paint()..color = color;
    final Paint detailPaint = Paint()
      ..color = detailColor
      ..strokeWidth = w * 0.055
      ..strokeCap = StrokeCap.round;
    final Paint wingPaint = Paint()
      ..color = color.withValues(alpha: 0.17)
      ..style = PaintingStyle.fill;
    final Paint wingStroke = Paint()
      ..color = color.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035;

    // Alas simples: silueta limpia tipo logo.
    final Rect upperWing = Rect.fromCenter(
      center: Offset(w * 0.38, h * 0.29),
      width: w * 0.34,
      height: h * 0.28,
    );
    final Rect lowerWing = Rect.fromCenter(
      center: Offset(w * 0.38, h * 0.64),
      width: w * 0.32,
      height: h * 0.24,
    );
    canvas.drawOval(upperWing, wingPaint);
    canvas.drawOval(upperWing, wingStroke);
    canvas.drawOval(lowerWing, wingPaint);
    canvas.drawOval(lowerWing, wingStroke);

    // Cuerpo horizontal y cabeza.
    final RRect body = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.27, h * 0.36, w * 0.47, h * 0.34),
      Radius.circular(h * 0.17),
    );
    canvas.drawRRect(body, bodyPaint);

    canvas.drawCircle(Offset(w * 0.73, h * 0.52), w * 0.16, bodyPaint);

    // Dos franjas, suficientes para que se lea inmediatamente como abeja.
    canvas.drawLine(
      Offset(w * 0.42, h * 0.39),
      Offset(w * 0.42, h * 0.67),
      detailPaint,
    );
    canvas.drawLine(
      Offset(w * 0.56, h * 0.38),
      Offset(w * 0.56, h * 0.68),
      detailPaint,
    );

    // Aguijón discreto.
    final Path sting = Path()
      ..moveTo(w * 0.25, h * 0.47)
      ..lineTo(w * 0.10, h * 0.53)
      ..lineTo(w * 0.25, h * 0.59)
      ..close();
    canvas.drawPath(sting, bodyPaint);

    // Ojo.
    canvas.drawCircle(
      Offset(w * 0.79, h * 0.48),
      w * 0.025,
      Paint()..color = detailColor,
    );

    // Antenas.
    canvas.drawLine(
      Offset(w * 0.77, h * 0.38),
      Offset(w * 0.82, h * 0.25),
      detailPaint,
    );
    canvas.drawLine(
      Offset(w * 0.84, h * 0.40),
      Offset(w * 0.91, h * 0.29),
      detailPaint,
    );
    canvas.drawCircle(
      Offset(w * 0.82, h * 0.25),
      w * 0.025,
      Paint()..color = detailColor,
    );
    canvas.drawCircle(
      Offset(w * 0.91, h * 0.29),
      w * 0.025,
      Paint()..color = detailColor,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SimpleBeePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.facingRight != facingRight;
  }
}

class _NavigationItemData {
  const _NavigationItemData({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _GroupSummaryData {
  const _GroupSummaryData({required this.label, required this.value});

  final String label;
  final int value;
}

class _QuickAccessData {
  const _QuickAccessData({required this.title, required this.icon});

  final String title;
  final IconData icon;
}
