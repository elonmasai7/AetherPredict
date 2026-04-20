import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/portfolio.dart';
import 'auth_provider.dart';

final dashboardProvider = FutureProvider<DashboardModel>((ref) async {
  return ref.read(apiServiceProvider).fetchDashboard();
});
