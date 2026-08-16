import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/auth_service.dart';
import '../models/document_model.dart';

class DocumentRepository {
  const DocumentRepository();

  static const String tableName = 'documents';

  SupabaseClient get _client => Supabase.instance.client;

  static const String _documentSelect = '''
    id,
    school_id,
    player_id,
    title,
    description,
    document_type,
    scope,
    document_date,
    status,
    file_name,
    file_path,
    created_by,
    created_at,
    updated_at,
    players (
      first_name,
      last_name
    ),
    profiles (
      first_name,
      last_name
    )
  ''';

  Future<List<DocumentModel>> getDocuments() async {
    final Map<String, dynamic> profile = await AuthService.getCurrentProfile();

    final String? schoolId = profile['school_id']?.toString();

    if (schoolId == null || schoolId.trim().isEmpty) {
      throw const AuthException(
        'El usuario actual no tiene una escuela asignada.',
      );
    }

    final List<dynamic> response = await _client
        .from(tableName)
        .select(_documentSelect)
        .eq('school_id', schoolId)
        .order('document_date', ascending: false)
        .order('created_at', ascending: false);

    return response
        .map(
          (dynamic item) =>
              DocumentModel.fromMap(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<DocumentModel?> getDocumentById(String id) async {
    final Map<String, dynamic>? response = await _client
        .from(tableName)
        .select(_documentSelect)
        .eq('id', id)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return DocumentModel.fromMap(response);
  }

  Future<DocumentModel> createDocument(DocumentModel document) async {
    final Map<String, dynamic> profile = await AuthService.getCurrentProfile();

    final String? schoolId = profile['school_id']?.toString();

    final String? userId = _client.auth.currentUser?.id;

    if (schoolId == null || schoolId.trim().isEmpty) {
      throw const AuthException(
        'El usuario actual no tiene una escuela asignada.',
      );
    }

    if (userId == null || userId.trim().isEmpty) {
      throw Exception('No fue posible identificar al usuario actual.');
    }

    final Map<String, dynamic> data = Map<String, dynamic>.from(
      document.toMap(),
    );

    data['school_id'] = schoolId;
    data['created_by'] = userId;

    // Un documento institucional nunca debe
    // quedar asociado accidentalmente a un jugador.
    if (data['scope'] == 'school') {
      data['player_id'] = null;
    }

    final Map<String, dynamic> response = await _client
        .from(tableName)
        .insert(data)
        .select(_documentSelect)
        .single();

    return DocumentModel.fromMap(response);
  }

  Future<DocumentModel> updateDocument(DocumentModel document) async {
    if (document.id.trim().isEmpty) {
      throw Exception('No fue posible identificar el documento.');
    }

    final Map<String, dynamic> data = Map<String, dynamic>.from(
      document.toMap(),
    );

    // Estos datos son establecidos al crear el registro
    // y no deben modificarse desde el formulario.
    data.remove('school_id');
    data.remove('created_by');

    if (data['scope'] == 'school') {
      data['player_id'] = null;
    }

    final Map<String, dynamic> response = await _client
        .from(tableName)
        .update(data)
        .eq('id', document.id)
        .select(_documentSelect)
        .single();

    return DocumentModel.fromMap(response);
  }

  Future<void> updateStatus({
    required String id,
    required String status,
  }) async {
    if (id.trim().isEmpty) {
      throw Exception('No fue posible identificar el documento.');
    }

    await _client
        .from(tableName)
        .update(<String, dynamic>{'status': status})
        .eq('id', id);
  }

  Future<void> archiveDocument(String id) async {
    await updateStatus(id: id, status: 'archived');
  }

  Future<void> restoreDocument(String id) async {
    await updateStatus(id: id, status: 'active');
  }

  Future<void> deleteDocument(String id) async {
    if (id.trim().isEmpty) {
      throw Exception('No fue posible identificar el documento.');
    }

    await _client.from(tableName).delete().eq('id', id);
  }
}
