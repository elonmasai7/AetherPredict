import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../widgets/glass_card.dart';

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
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Email and password are required.');
      return;
    }
    if (password.length < 8) {
      setState(() => _error = 'Use at least 8 characters for password.');
      return;
    }
    if (password != confirmPassword) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully.')),
      );
      context.go('/dashboard');
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
          context.go('/dashboard');
        }
      });
    }
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF07111F), Color(0xFF13325B), Color(0xFF07111F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: GlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create your AetherPredict account',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Sign up to start tracking markets, vaults, and AI signals.',
                    style:
                        TextStyle(color: Colors.white.withValues(alpha: 0.72)),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(
                        labelText: 'Display name (optional)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'Confirm password'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: const TextStyle(color: Colors.redAccent)),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child:
                          Text(_submitting ? 'Creating account...' : 'Sign up'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed:
                          _submitting ? null : () => context.go('/login'),
                      child: const Text('Back to sign in'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
