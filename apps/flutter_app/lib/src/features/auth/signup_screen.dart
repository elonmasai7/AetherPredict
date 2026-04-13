import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../widgets/enterprise/enterprise_components.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final displayName = _displayNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Email and password are required.');
      return;
    }
    if (password.length < 8) {
      setState(() => _error = 'Use at least 8 characters for password.');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final authPayload = await ref.read(apiClientProvider).register(
            email: email,
            password: password,
            displayName: displayName.isEmpty ? null : displayName,
          );
      final accessToken = authPayload['access_token']?.toString();
      final refreshToken = authPayload['refresh_token']?.toString();
      final tokenType = authPayload['token_type']?.toString() ?? 'bearer';
      if (accessToken == null ||
          accessToken.isEmpty ||
          refreshToken == null ||
          refreshToken.isEmpty) {
        throw StateError('Authentication response did not include tokens.');
      }

      await ref.read(authSessionProvider.notifier).saveTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            tokenType: tokenType,
          );

      if (!mounted) return;
      context.go('/forecast-overview');
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authSessionProvider);

    ref.read(authSessionProvider.notifier).restore();

    if (auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go('/forecast-overview');
        }
      });
    }

    return Scaffold(
      backgroundColor: AetherColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AetherSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: EnterprisePanel(
                title: 'Create Account',
                subtitle:
                    'Provision access for the institutional prediction intelligence workspace.',
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _displayNameController,
                      decoration: const InputDecoration(
                          labelText: 'Display Name (Optional)'),
                    ),
                    const SizedBox(height: AetherSpacing.sm),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: AetherSpacing.sm),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                    ),
                    const SizedBox(height: AetherSpacing.sm),
                    TextField(
                      controller: _confirmPasswordController,
                      decoration:
                          const InputDecoration(labelText: 'Confirm Password'),
                      obscureText: true,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AetherSpacing.sm),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _error!,
                          style: const TextStyle(color: AetherColors.critical),
                        ),
                      ),
                    ],
                    const SizedBox(height: AetherSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _submitting ? null : _submit,
                        child: Text(
                          _submitting
                              ? 'Creating account...'
                              : 'Create Account',
                        ),
                      ),
                    ),
                    const SizedBox(height: AetherSpacing.sm),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed:
                            _submitting ? null : () => context.go('/login'),
                        child: const Text('Back to Sign In'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
