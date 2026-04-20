import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

class AuthState {
  const AuthState({
    this.email,
    this.balance = 0,
    this.loading = false,
    this.isLoggedIn = false,
    this.error,
  });

  final String? email;
  final double balance;
  final bool loading;
  final bool isLoggedIn;
  final String? error;

  AuthState copyWith({
    String? email,
    double? balance,
    bool? loading,
    bool? isLoggedIn,
    String? error,
  }) {
    return AuthState(
      email: email ?? this.email,
      balance: balance ?? this.balance,
      loading: loading ?? this.loading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._api) : super(const AuthState());

  final ApiService _api;

  Future<void> bootstrap() async {
    state = state.copyWith(loading: true, error: null);
    await _api.initialize();
    final token = await _api.token();
    if (token == null || token.isEmpty) {
      state = state.copyWith(loading: false, isLoggedIn: false);
      return;
    }
    try {
      final me = await _api.me();
      state = state.copyWith(
        loading: false,
        isLoggedIn: true,
        email: me['email'] as String?,
        balance: (me['balance'] as num).toDouble(),
      );
    } catch (error) {
      state = state.copyWith(loading: false, isLoggedIn: false, error: error.toString());
    }
  }

  Future<void> registerAndLogin(String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _api.register(email, password);
      await _api.login(email, password);
      await bootstrap();
    } catch (error) {
      state = state.copyWith(loading: false, error: error.toString());
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _api.login(email, password);
      await bootstrap();
    } catch (error) {
      state = state.copyWith(loading: false, error: error.toString());
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(apiServiceProvider));
});
