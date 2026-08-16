import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/training_session_model.dart';
import '../repositories/training_repository.dart';
import 'training_detail_screen.dart';
import 'training_form_screen.dart';
import 'widgets/training_card.dart';

class TrainingListScreen extends StatefulWidget {
  const TrainingListScreen({super.key});

  @override
  State<TrainingListScreen> createState() {
    return _TrainingListScreenState();
  }
}

class _TrainingListScreenState extends State<TrainingListScreen> {
  final TrainingRepository _repository = const TrainingRepository();

  bool _isLoading = true;
  String? _errorMessage;

  List<TrainingSessionModel> _sessions = <TrainingSessionModel>[];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<TrainingSessionModel> sessions = await _repository
          .getTrainingSessions();

      if (!mounted) {
        return;
      }

      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Error al cargar entrenamientos: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'No fue posible cargar los entrenamientos.\n\n$error';
      });
    }
  }

  Future<void> _openTraining(TrainingSessionModel session) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TrainingDetailScreen(session: session),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadSessions();
  }

  Future<void> _createTraining() async {
    final TrainingSessionModel? created = await Navigator.of(context).push(
      MaterialPageRoute<TrainingSessionModel>(
        builder: (_) => const TrainingFormScreen(),
      ),
    );

    if (created == null || !mounted) {
      return;
    }

    await _loadSessions();

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
            'Entrenamiento creado correctamente.',
            style: TextStyle(
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
      backgroundColor: const Color(0xFFF8F6FA),
      appBar: AppBar(
        title: const Text(
          'Entrenamientos',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: AppColors.darkFuchsia,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadSessions,
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.fuchsia,
        foregroundColor: AppColors.white,
        onPressed: _createTraining,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'NUEVO',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.fuchsia,
        onRefresh: _loadSessions,
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
              onPressed: _loadSessions,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('REINTENTAR'),
            ),
          ),
        ],
      );
    }

    if (_sessions.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: AppColors.fuchsia.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sports_soccer_rounded,
              color: AppColors.fuchsia,
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Todavía no existen entrenamientos registrados.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.black,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pulsa NUEVO para registrar la primera sesión de entrenamiento.',
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      itemCount: _sessions.length,
      separatorBuilder: (BuildContext context, int index) {
        return const SizedBox(height: 14);
      },
      itemBuilder: (BuildContext context, int index) {
        final TrainingSessionModel session = _sessions[index];

        return TrainingCard(
          session: session,
          onPressed: () {
            _openTraining(session);
          },
        );
      },
    );
  }
}
