import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  AppUser? _currentUser;
  bool _isLoading = true;
  String? _error;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  AuthService() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Listen to auth state changes
      _supabase.auth.onAuthStateChange.listen((data) {
        _handleAuthStateChange(data.session);
      });

      // Check current session
      final session = _supabase.auth.currentSession;
      await _handleAuthStateChange(session);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _handleAuthStateChange(Session? session) async {
    if (session?.user != null) {
      await _loadUserProfile(session!.user.id);
    } else {
      _currentUser = null;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      _currentUser = AppUser.fromJson(response);
      _error = null;
    } catch (e) {
      _error = 'Failed to load user profile: $e';
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName},
        emailRedirectTo: 'https://treasuretogether.com',
      );

      if (response.user != null) {
        // Check if email confirmation is required
        final session = response.session;
        final emailConfirmedAt = response.user?.emailConfirmedAt;

        if (session == null && emailConfirmedAt == null) {
          // Email confirmation required - user created but not confirmed
          _error = 'Please check your email to confirm your account before signing in.';
          return true; // Still return true because account was created
        } else if (emailConfirmedAt != null) {
          return true;
        } else if (session != null) {
          return true;
        }
        return true;
      } else {
        _error = 'Sign up failed. Please try again.';
        return false;
      }
    } catch (e) {
      // Better error messages
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('already registered') || errorMsg.contains('already exists')) {
        _error = 'This email is already registered. Try signing in instead.';
      } else if (errorMsg.contains('invalid email')) {
        _error = 'Please enter a valid email address.';
      } else if (errorMsg.contains('password')) {
        _error = 'Password must be at least 6 characters long.';
      } else {
        _error = 'Sign up failed: ${e.toString()}';
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        return true;
      } else {
        _error = 'Sign in failed';
        return false;
      }
    } catch (e) {
      // Check for specific error types
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('email not confirmed') ||
          errorMessage.contains('email confirmation')) {
        _error = 'Please confirm your email address before signing in. Check your inbox for the confirmation link.';
      } else if (errorMessage.contains('invalid') ||
          errorMessage.contains('credentials') ||
          errorMessage.contains('wrong') ||
          errorMessage.contains('incorrect')) {
        _error = "Doh! That's not it. Wrong email or password?";
      } else if (errorMessage.contains('not found') || errorMessage.contains('user not found')) {
        _error = 'No account found with this email. Try signing up first!';
      } else {
        _error = e.toString();
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      _currentUser = null;
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'treasuretogether://reset-password',
      );

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}