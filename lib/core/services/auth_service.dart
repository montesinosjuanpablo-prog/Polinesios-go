import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService._();

  static SupabaseClient get client => Supabase.instance.client;

  static User? get currentUser => client.auth.currentUser;

  static Session? get currentSession => client.auth.currentSession;

  static bool get isAuthenticated => currentSession != null;

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<Map<String, dynamic>> getCurrentProfile() async {
    final User? user = currentUser;

    if (user == null) {
      throw const AuthException('No existe una sesión activa.');
    }

    final Map<String, dynamic> profile = await client
        .from('profiles')
        .select(
          'id, school_id, first_name, last_name, '
          'phone, photo_url, role, status',
        )
        .eq('id', user.id)
        .single();

    return profile;
  }

  static Future<void> signOut() {
    return client.auth.signOut();
  }
}
