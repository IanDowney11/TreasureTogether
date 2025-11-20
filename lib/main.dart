import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'services/auth_service.dart';
import 'services/photo_service.dart';
import 'services/group_service.dart';
import 'services/sync_service.dart';
import 'services/preferences_service.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/camera/camera_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      // Auto-refresh tokens before expiry to keep session alive
      autoRefreshToken: true,
    ),
  );

  runApp(const PhotoSharingApp());
}

class PhotoSharingApp extends StatelessWidget {
  const PhotoSharingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => PreferencesService()),
        ChangeNotifierProvider(create: (_) => PhotoService()),
        ChangeNotifierProvider(create: (_) => GroupService()),
        ChangeNotifierProvider(create: (_) => SyncService()),
      ],
      child: MaterialApp(
        title: 'TreasureTogether',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isPasswordRecovery = false;

  @override
  void initState() {
    super.initState();
    _checkForPasswordRecovery();

    // Listen for auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        setState(() {
          _isPasswordRecovery = true;
        });
      } else if (event == AuthChangeEvent.signedOut) {
        setState(() {
          _isPasswordRecovery = false;
        });
      }
    });
  }

  Future<void> _checkForPasswordRecovery() async {
    // Check if we're coming from a password recovery link
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      // Check if this is a recovery session by looking at the URL
      // Supabase automatically handles the token exchange
      setState(() {
        _isPasswordRecovery = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If password recovery mode, show reset password screen
    if (_isPasswordRecovery) {
      return const ResetPasswordScreen();
    }

    return Consumer<AuthService>(
      builder: (context, authService, _) {
        if (authService.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (authService.currentUser == null) {
          return const AuthScreen();
        }

        return const CameraScreen();
      },
    );
  }
}