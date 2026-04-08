import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/wallet_service.dart';
import '../../widgets/glass_card.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Email and password are required.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final authPayload = await ref
          .read(apiClientProvider)
          .login(email: email, password: password);
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
    final wallet = ref.watch(walletSessionProvider);
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
            constraints: const BoxConstraints(maxWidth: 540),
            child: GlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Institutional prediction intelligence',
                      style:
                          TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    'Trade on-chain probabilities with AI-driven confidence, dispute intelligence, and autonomous liquidity support.',
                    style:
                        TextStyle(color: Colors.white.withValues(alpha: 0.72)),
                  ),
                  const SizedBox(height: 24),
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
                      child: Text(_submitting ? 'Signing in...' : 'Sign in'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed:
                          _submitting ? null : () => context.go('/signup'),
                      child: const Text('Create account'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _submitting
                        ? null
                        : () async {
                            await ref
                                .read(walletSessionProvider.notifier)
                                .connect(WalletType.walletConnect);
                            if (context.mounted) {
                              context.go('/dashboard');
                            }
                          },
                    child: Text(wallet.connected
                        ? 'Wallet Connected'
                        : 'Connect Wallet'),
                  ),
                  if (wallet.error != null) ...[
                    const SizedBox(height: 12),
                    Text(wallet.error!,
                        style: const TextStyle(color: Colors.redAccent)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
