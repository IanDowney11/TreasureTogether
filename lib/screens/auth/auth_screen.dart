import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../version.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _isSignUp = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: Consumer<AuthService>(
          builder: (context, authService, _) {
            if (authService.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            return SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 48,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo Section
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'TreasureTogether',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${AppVersion.fullVersion}${kIsWeb ? ' • Web' : ''}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 40),
                          // Floating Card with Form
                          Card(
                            elevation: 8,
                            shadowColor: Colors.black.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                        if (_isSignUp)
                          TextFormField(
                            controller: _displayNameController,
                            decoration: const InputDecoration(
                              labelText: 'Display Name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (_isSignUp && (value == null || value.isEmpty)) {
                                return 'Please enter a display name';
                              }
                              return null;
                            },
                          ),
                        if (_isSignUp) const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (_isSignUp && value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        if (authService.error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              authService.error!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _handleSubmit,
                            child: Text(_isSignUp ? 'Sign Up' : 'Sign In'),
                          ),
                        ),
                        if (!_isSignUp)
                          TextButton(
                            onPressed: () => _showForgotPasswordDialog(context),
                            child: const Text('Forgot Password?'),
                          ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isSignUp = !_isSignUp;
                              authService.clearError();
                            });
                          },
                          child: Text(_isSignUp
                              ? 'Already have an account? Sign In'
                              : "Don't have an account? Sign Up"),
                        ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // APK Download Section (outside the card)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.android, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () {
                                    final url = 'https://github.com/IanDowney11/TreasureTogether/releases/latest';
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Download APK from: $url'),
                                        duration: const Duration(seconds: 5),
                                        action: SnackBarAction(
                                          label: 'Copy',
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(text: url));
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Download Android App (APK)'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = context.read<AuthService>();

    if (_isSignUp) {
      await authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _displayNameController.text.trim(),
      );
    } else {
      await authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your email address and we\'ll send you a link to reset your password.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
                autofocus: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                final authService = context.read<AuthService>();

                navigator.pop();

                final success = await authService.resetPassword(
                  emailController.text.trim(),
                );

                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Password reset email sent! Check your inbox.'
                          : authService.error ?? 'Failed to send reset email',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            },
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }
}
