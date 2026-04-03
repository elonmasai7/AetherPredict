import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/glass_card.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  const Text('Institutional prediction intelligence', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    'Trade on-chain probabilities with AI-driven confidence, dispute intelligence, and autonomous liquidity support.',
                    style: TextStyle(color: Colors.white.withOpacity(0.72)),
                  ),
                  const SizedBox(height: 24),
                  const TextField(decoration: InputDecoration(labelText: 'Email')),
                  const SizedBox(height: 12),
                  const TextField(obscureText: true, decoration: InputDecoration(labelText: 'Password')),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => context.go('/dashboard'),
                      child: const Text('Sign in'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.go('/dashboard'),
                    child: const Text('Connect Wallet'),
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
