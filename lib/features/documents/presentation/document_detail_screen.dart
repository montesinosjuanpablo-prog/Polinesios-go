import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/document_model.dart';
import '../repositories/document_repository.dart';
import 'document_form_screen.dart';

class DocumentDetailScreen extends StatefulWidget {
  const DocumentDetailScreen({required this.document, super.key});

  final DocumentModel document;

  @override
  State<DocumentDetailScreen> createState() {
    return _DocumentDetailScreenState();
  }
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  final DocumentRepository _repository = const DocumentRepository();

  late DocumentModel _document;

  bool _isWorking = false;
  bool _wasChanged = false;

  @override
  void initState() {
    super.initState();
    _document = widget.document;
  }

  Future<void> _editDocument() async {
    final DocumentModel? updated = await Navigator.of(context)
        .push<DocumentModel>(
          MaterialPageRoute<DocumentModel>(
            builder: (_) => DocumentFormScreen(document: _document),
          ),
        );

    if (updated == null || !mounted) {
      return;
    }

    setState(() {
      _document = updated;
      _wasChanged = true;
    });

    _showMessage('Documento actualizado correctamente.');
  }

  Future<void> _archiveDocument() async {
    final bool? confirmed = await _confirmationDialog(
      title: 'Archivar documento',
      message:
          'El documento seguirá guardado, pero quedará marcado como archivado.',
      confirmLabel: 'ARCHIVAR',
      confirmColor: const Color(0xFF81747A),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isWorking = true;
    });

    try {
      await _repository.archiveDocument(_document.id);

      final DocumentModel? refreshed = await _repository.getDocumentById(
        _document.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        if (refreshed != null) {
          _document = refreshed;
        } else {
          _document = _document.copyWith(status: 'archived');
        }

        _wasChanged = true;
      });

      _showMessage('Documento archivado correctamente.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('No fue posible archivar el documento.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  Future<void> _restoreDocument() async {
    final bool? confirmed = await _confirmationDialog(
      title: 'Restaurar documento',
      message: 'El documento volverá a quedar activo.',
      confirmLabel: 'RESTAURAR',
      confirmColor: AppColors.fuchsia,
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isWorking = true;
    });

    try {
      await _repository.restoreDocument(_document.id);

      final DocumentModel? refreshed = await _repository.getDocumentById(
        _document.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        if (refreshed != null) {
          _document = refreshed;
        } else {
          _document = _document.copyWith(status: 'active');
        }

        _wasChanged = true;
      });

      _showMessage('Documento restaurado correctamente.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('No fue posible restaurar el documento.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  Future<void> _deleteDocument() async {
    final bool? confirmed = await _confirmationDialog(
      title: 'Eliminar documento',
      message:
          '¿Quieres eliminar definitivamente "${_document.title}"?\n\nEsta acción no se puede deshacer.',
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
      await _repository.deleteDocument(_document.id);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop<bool>(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isWorking = false;
      });

      _showMessage('No fue posible eliminar el documento.', isError: true);
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          return;
        }

        _closeScreen();
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.darkFuchsia,
          foregroundColor: AppColors.white,
          leading: IconButton(
            tooltip: 'Volver',
            onPressed: _closeScreen,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text(
            'Detalle del documento',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          actions: [
            IconButton(
              tooltip: 'Editar',
              onPressed: _isWorking ? null : _editDocument,
              icon: const Icon(Icons.edit_rounded),
            ),
          ],
        ),
        body: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 120),
              children: [
                _HeaderCard(document: _document),
                const SizedBox(height: 16),
                _DescriptionCard(description: _document.description),
                const SizedBox(height: 16),
                _InformationCard(document: _document),
                const SizedBox(height: 16),
                _ActionsCard(
                  document: _document,
                  isWorking: _isWorking,
                  onEdit: _editDocument,
                  onArchive: _archiveDocument,
                  onRestore: _restoreDocument,
                  onDelete: _deleteDocument,
                ),
              ],
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
  const _HeaderCard({required this.document});

  final DocumentModel document;

  @override
  Widget build(BuildContext context) {
    final bool archived = document.isArchived;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.darkFuchsia, AppColors.fuchsia],
        ),
        borderRadius: BorderRadius.circular(24),
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
                document.statusLabel.toUpperCase(),
                style: TextStyle(
                  color: archived ? const Color(0xFFD0C5CA) : AppColors.yellow,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: AppColors.yellow,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.description_rounded,
              color: AppColors.darkFuchsia,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            document.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            document.typeLabel,
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

class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Descripción',
      icon: Icons.notes_rounded,
      child: SelectableText(
        description.trim().isEmpty ? 'Sin descripción.' : description,
        style: const TextStyle(
          color: Color(0xFF675B61),
          fontSize: 13,
          height: 1.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({required this.document});

  final DocumentModel document;

  @override
  Widget build(BuildContext context) {
    final String destination = document.isPlayerDocument
        ? document.playerName.trim().isEmpty
              ? 'Jugador no registrado'
              : document.playerName
        : 'Escuela Formativa Polinesios';

    return _SectionCard(
      title: 'Información',
      icon: Icons.info_outline_rounded,
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.category_rounded,
            label: 'Tipo',
            value: document.typeLabel,
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.groups_rounded,
            label: 'Corresponde a',
            value: destination,
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.calendar_month_rounded,
            label: 'Fecha',
            value: _formatDate(document.documentDate),
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.person_rounded,
            label: 'Registrado por',
            value: document.creatorName.trim().isEmpty
                ? 'Usuario no registrado'
                : document.creatorName,
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.fact_check_rounded,
            label: 'Estado',
            value: document.statusLabel,
          ),
        ],
      ),
    );
  }
}

class _ActionsCard extends StatelessWidget {
  const _ActionsCard({
    required this.document,
    required this.isWorking,
    required this.onEdit,
    required this.onArchive,
    required this.onRestore,
    required this.onDelete,
  });

  final DocumentModel document;
  final bool isWorking;

  final VoidCallback onEdit;
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
              'EDITAR DOCUMENTO',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 10),

          if (document.isArchived)
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
                'RESTAURAR DOCUMENTO',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            )
          else
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
                'ARCHIVAR DOCUMENTO',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),

          const SizedBox(height: 10),

          TextButton.icon(
            onPressed: isWorking ? null : onDelete,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFC62828),
              minimumSize: const Size.fromHeight(48),
            ),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text(
              'ELIMINAR DOCUMENTO',
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

String _formatDate(DateTime date) {
  final String day = date.day.toString().padLeft(2, '0');

  final String month = date.month.toString().padLeft(2, '0');

  return '$day/$month/${date.year}';
}
