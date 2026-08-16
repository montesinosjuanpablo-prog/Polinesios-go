import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/document_model.dart';
import '../repositories/document_repository.dart';
import 'document_detail_screen.dart';
import 'document_form_screen.dart';

class DocumentListScreen extends StatefulWidget {
  const DocumentListScreen({super.key});

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  final DocumentRepository _repository = const DocumentRepository();

  List<DocumentModel> _documents = <DocumentModel>[];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final List<DocumentModel> documents = await _repository.getDocuments();

      if (!mounted) {
        return;
      }

      setState(() {
        _documents = documents;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _createDocument() async {
    final DocumentModel? created = await Navigator.of(context)
        .push<DocumentModel>(
          MaterialPageRoute<DocumentModel>(
            builder: (_) => const DocumentFormScreen(),
          ),
        );

    if (created == null || !mounted) {
      return;
    }

    await _loadDocuments();

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
            'Documento registrado correctamente.',
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
  }

  Future<void> _openDocument(DocumentModel document) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => DocumentDetailScreen(document: document),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadDocuments();
  }

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');

    final String month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  IconData _typeIcon(String documentType) {
    switch (documentType) {
      case 'registration':
        return Icons.assignment_ind_rounded;

      case 'identity':
        return Icons.badge_rounded;

      case 'medical':
        return Icons.medical_information_rounded;

      case 'authorization':
        return Icons.verified_user_rounded;

      case 'contract':
        return Icons.handshake_rounded;

      case 'payment':
        return Icons.receipt_long_rounded;

      case 'institutional':
        return Icons.account_balance_rounded;

      default:
        return Icons.description_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.darkFuchsia,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Documentos',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _isLoading ? null : _loadDocuments,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.fuchsia,
        onRefresh: _loadDocuments,
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.fuchsia,
        foregroundColor: AppColors.white,
        onPressed: _createDocument,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'NUEVO',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const <Widget>[
          SizedBox(height: 180),
          Center(child: CircularProgressIndicator(color: AppColors.fuchsia)),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const SizedBox(height: 80),
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: AppColors.fuchsia.withValues(alpha: 0.75),
          ),
          const SizedBox(height: 18),
          const Text(
            'No pudimos cargar los documentos.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 24),
          Center(
            child: FilledButton.icon(
              onPressed: _loadDocuments,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('REINTENTAR'),
            ),
          ),
        ],
      );
    }

    if (_documents.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 28),
        children: <Widget>[
          const SizedBox(height: 125),
          Container(
            width: 105,
            height: 105,
            decoration: BoxDecoration(
              color: AppColors.yellow.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.folder_open_rounded,
              size: 55,
              color: AppColors.darkFuchsia,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aún no hay documentos',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(
            'Aquí podrás organizar los documentos '
            'de la Escuela y de nuestros jugadores.',
            textAlign: TextAlign.center,
            style: TextStyle(
              height: 1.45,
              fontSize: 16,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 110),
      itemCount: _documents.length,
      separatorBuilder: (BuildContext context, int index) {
        return const SizedBox(height: 12);
      },
      itemBuilder: (BuildContext context, int index) {
        final DocumentModel document = _documents[index];

        return _DocumentCard(
          document: document,
          formattedDate: _formatDate(document.documentDate),
          icon: _typeIcon(document.documentType),
          onTap: () {
            _openDocument(document);
          },
        );
      },
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.document,
    required this.formattedDate,
    required this.icon,
    required this.onTap,
  });

  final DocumentModel document;
  final String formattedDate;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool archived = document.isArchived;

    final String secondaryText = document.isPlayerDocument
        ? document.playerName.isNotEmpty
              ? document.playerName
              : 'Jugador'
        : 'Escuela Formativa Polinesios';

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.fuchsia.withValues(alpha: 0.16),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: AppColors.yellow.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: AppColors.darkFuchsia, size: 31),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      document.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      secondaryText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _DocumentChip(
                          icon: Icons.category_rounded,
                          label: document.typeLabel,
                          foreground: AppColors.darkFuchsia,
                        ),
                        _DocumentChip(
                          icon: Icons.calendar_month_rounded,
                          label: formattedDate,
                          foreground: Colors.grey.shade700,
                        ),
                        _DocumentChip(
                          icon: archived
                              ? Icons.inventory_2_rounded
                              : Icons.check_circle_rounded,
                          label: document.statusLabel,
                          foreground: archived
                              ? Colors.grey.shade700
                              : Colors.green.shade700,
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
                size: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentChip extends StatelessWidget {
  const _DocumentChip({
    required this.icon,
    required this.label,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: foreground.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: foreground),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
