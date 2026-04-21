import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/wallet_service.dart';
import '../../widgets/enterprise/enterprise_components.dart';

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
      context.go('/overview');
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _walletConnect() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref
          .read(walletSessionProvider.notifier)
          .connect(WalletType.walletConnect);
      if (!mounted) return;
      context.go('/overview');
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
    final wallet = ref.watch(walletSessionProvider);

    ref.read(authSessionProvider.notifier).restore();

    if (auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go('/overview');
        }
      });
    }

    final infoPanel = EnterprisePanel(
      title: 'AetherPredict',
      subtitle: 'AI-powered NBA prediction intelligence platform',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'AetherPredict is an AI-powered NBA prediction market built for game outcomes, player props, season markets, real-time news signals, and on-chain or MVP settlement.',
          ),
          SizedBox(height: AetherSpacing.md),
          Text(
              '• NBA-first forecasting workflows with clean probability intelligence'),
          SizedBox(height: 6),
          Text(
              '• AI agents for game analysis, player props, news impact, and custom strategies'),
          SizedBox(height: 6),
          Text(
              '• Wallet-aware execution with MVP settlement support and production-ready chain hooks'),
        ],
      ),
    );

    final formPanel = EnterprisePanel(
      title: 'Sign In',
      subtitle: 'Access your NBA prediction workspace.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
              child: Text(_submitting ? 'Signing in...' : 'Sign In'),
            ),
          ),
          const SizedBox(height: AetherSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _submitting ? null : _walletConnect,
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: Text(
                wallet.connected
                    ? 'Wallet Connected'
                    : 'Connect Wallet and Continue',
              ),
            ),
          ),
          const SizedBox(height: AetherSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _submitting ? null : () => context.go('/signup'),
              child: const Text('Create Account'),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: AetherColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AetherSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 860;
                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        infoPanel,
                        const SizedBox(height: AetherSpacing.lg),
                        formPanel,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: infoPanel),
                      const SizedBox(width: AetherSpacing.lg),
                      SizedBox(width: 420, child: formPanel),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
