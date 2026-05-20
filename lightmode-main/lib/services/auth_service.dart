import 'package:supabase_flutter/supabase_flutter.dart';
import 'storage_service.dart';
import 'supabase_service.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseService _supabaseService;
  final _storage = StorageService.instance;
  final _supabase = Supabase.instance.client;
  
  SupabaseService get supabaseService => _supabaseService;

  AuthService(this._supabaseService);

  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      // Sign in with Supabase
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      if (response.user == null) {
        throw Exception('Login failed. Please check your credentials.');
      }

      // Fetch user profile from database
      final userProfile = await _supabase
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .maybeSingle(); // Use maybeSingle to handle missing profiles

      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      // Save session token
      if (response.session?.accessToken != null) {
        await _storage.setString('auth_token', response.session!.accessToken);
      }

      return UserModel.fromJson(userProfile);
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Failed to sign in: ${e.toString()}');
    }
  }

  Future<UserModel?> signInWithStudentId(String studentId, String password) async {
    try {
      // Get user by student ID
      final user = await _supabaseService.getUserByStudentId(studentId);
      if (user == null) {
        throw Exception('Student ID not found');
      }

      // Sign in with email (students use email for auth)
      final response = await _supabase.auth.signInWithPassword(
        email: user.email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Login failed. Please check your credentials.');
      }

      // Fetch user profile from database
      final userProfile = await _supabase
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .maybeSingle();

      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      // Save session token
      if (response.session?.accessToken != null) {
        await _storage.setString('auth_token', response.session!.accessToken);
      }

      return UserModel.fromJson(userProfile);
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Failed to sign in with student ID: ${e.toString()}');
    }
  }

  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String role = 'student',
  }) async {
    try {
      // Sign up with Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
        data: {
          'full_name': fullName,
        },
      );

      if (response.user == null) {
        throw Exception('Signup failed. Please try again.');
      }

      // Create user profile in database
      final userProfile = await _supabase.from('users').insert({
        'id': response.user!.id,
        'email': email.trim().toLowerCase(),
        'full_name': fullName,
        'role': role,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      // Save session token if available
      if (response.session?.accessToken != null) {
        await _storage.setString('auth_token', response.session!.accessToken);
      }

      return UserModel.fromJson(userProfile);
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Failed to sign up: ${e.toString()}');
    }
  }

  Future<UserModel?> signUpWithStudentId({
    required String studentId,
    required String password,
    required String fullName,
    String role = 'student',
  }) async {
    try {
      // Check if student ID exists
      final existingUser = await _supabaseService.getUserByStudentId(studentId);
      if (existingUser == null) {
        throw Exception('Student ID not found in system');
      }

      // Check if user already has an account
      final email = existingUser.email;
      
      // Try to sign up (will fail if email already exists)
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
        },
      );

      if (response.user == null) {
        throw Exception('Signup failed. This student ID may already be registered.');
      }

      // Update user profile with full name and role if needed
      await _supabase.from('users').update({
        'full_name': fullName,
        'role': role,
      }).eq('id', response.user!.id);

      // Fetch updated user profile
      final userProfile = await _supabase
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .single();

      // Save session token if available
      if (response.session?.accessToken != null) {
        await _storage.setString('auth_token', response.session!.accessToken);
      }

      return UserModel.fromJson(userProfile);
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Failed to sign up with student ID: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      // Continue with local cleanup even if signOut fails
    }
    
    // Clear local storage
    await _storage.remove('auth_token');
    await _storage.remove('user_data');
  }

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final session = _supabase.auth.currentSession;
    return session != null;
  }

  // Get current user profile
  Future<UserModel?> getCurrentUserProfile() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      
      if (currentUser == null) {
        return null;
      }

      // Fetch user profile from database
      final userProfile = await _supabase
          .from('users')
          .select()
          .eq('id', currentUser.id)
          .maybeSingle();

      if (userProfile == null) {
        return null;
      }

      return UserModel.fromJson(userProfile);
    } catch (e) {
      return null;
    }
  }

  String getRedirectPathByRole(String? role) {
    switch (role) {
      case 'student':
      case 'staff':
        return '/my-devices';
      case 'officer':
        return '/officer-home';
      case 'admin':
        return '/dashboard';
      default:
        return '/login';
    }
  }
}
