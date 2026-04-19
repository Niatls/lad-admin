import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lad_admin/core/api_client.dart';
import 'package:lad_admin/models/dashboard_data.dart';

final apiClientProvider = Provider((ref) => ApiClient());

final dashboardProvider = StateNotifierProvider<DashboardNotifier, AsyncValue<DashboardData>>((ref) {
  return DashboardNotifier(ref.watch(apiClientProvider));
});

class DashboardNotifier extends StateNotifier<AsyncValue<DashboardData>> {
  final ApiClient _api;

  DashboardNotifier(this._api) : super(const AsyncValue.loading()) {
    fetchData();
  }

  Future<void> fetchData() async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.get('/admin/applications');
      final data = DashboardData.fromJson(response.data);
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
