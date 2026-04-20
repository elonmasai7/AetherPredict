import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _email = TextEditingController(text: 'demo@predictodds.pro');
  final _password = TextEditingController(text: 'DemoPass123!');
  final _apiKey = TextEditingController();
  final _apiSecret = TextEditingController();
  final _privateKey = TextEditingController();
  String _provider = 'kalshi';
  String? _message;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Account', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 12),
          TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: auth.loading
                      ? null
                      : () async {
                          await ref.read(authProvider.notifier).registerAndLogin(_email.text.trim(), _password.text);
                          setState(() => _message = 'Registered and logged in.');
                        },
                  child: const Text('Register'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: auth.loading
                      ? null
                      : () async {
                          await ref.read(authProvider.notifier).login(_email.text.trim(), _password.text);
                          setState(() => _message = 'Logged in.');
                        },
                  child: const Text('Login'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Provider API Keys', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _provider,
            items: const [
              DropdownMenuItem(value: 'kalshi', child: Text('Kalshi')),
              DropdownMenuItem(value: 'alpaca', child: Text('Alpaca')),
            ],
            onChanged: (value) => setState(() => _provider = value ?? 'kalshi'),
          ),
          const SizedBox(height: 12),
          TextField(controller: _apiKey, decoration: const InputDecoration(labelText: 'API key / client id')),
          const SizedBox(height: 12),
          TextField(controller: _apiSecret, decoration: const InputDecoration(labelText: 'API secret / OAuth token')),
          const SizedBox(height: 12),
          if (_provider == 'kalshi')
            TextField(
              controller: _privateKey,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Kalshi private key PEM'),
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () async {
              final payload = {
                'provider': _provider,
                'api_key': _apiKey.text.trim().isEmpty ? null : _apiKey.text.trim(),
                if (_provider == 'kalshi')
                  'private_key_pem': _privateKey.text.trim().isEmpty ? null : _privateKey.text.trim(),
                if (_provider == 'alpaca')
                  'api_secret': _apiSecret.text.trim().isEmpty ? null : _apiSecret.text.trim(),
              };
              await ref.read(apiServiceProvider).saveProviderCredentials(payload);
              setState(() => _message = 'Provider credentials saved securely.');
            },
            child: const Text('Save credentials'),
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(_message!),
          ],
          if (auth.error != null) ...[
            const SizedBox(height: 12),
            Text(auth.error!, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
    );
  }
}
