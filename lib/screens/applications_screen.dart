import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lad_admin/providers/dashboard_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

final filterStatusProvider = StateProvider<String?>((ref) => null);

final filteredApplicationsProvider = FutureProvider((ref) async {
  final api = ref.watch(apiClientProvider);
  final status = ref.watch(filterStatusProvider);
  
  final queryParams = <String, dynamic>{};
  if (status != null) queryParams['status'] = status;
  
  final response = await api.get('/admin/applications', queryParameters: queryParams);
  final data = response.data['applications'] as List;
  // We can reuse the model here or define a specific fetch relative to parameters
  return data; // Simple list for now, we could map to Application models
});

class ApplicationsScreen extends ConsumerWidget {
  const ApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(filteredApplicationsProvider);
    final currentFilter = ref.watch(filterStatusProvider);
    final bool isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F5),
      appBar: isDesktop ? null : AppBar(
        title: const Text('Все заявки'),
        actions: [
          _buildFilterButton(context, ref, currentFilter),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              if (isDesktop) 
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Все заявки', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                      _buildFilterButton(context, ref, currentFilter),
                    ],
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => ref.refresh(filteredApplicationsProvider.future),
                  child: applicationsAsync.when(
                    data: (apps) => ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: apps.length,
                      itemBuilder: (context, index) {
                        final app = apps[index];
                        final date = DateFormat('dd.MM HH:mm').format(DateTime.parse(app['createdAt']));
                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            title: Text(app['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('$date • ${app['source']}'),
                            trailing: _buildStatusBadge(app['status']),
                            onTap: () => context.push('/applications/${app['id']}'),
                          ),
                        );
                      },
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, st) => Center(child: Text('Error: $err')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context, WidgetRef ref, String? currentFilter) {
    return PopupMenuButton<String?>(
      initialValue: currentFilter,
      icon: const Icon(Icons.filter_list),
      onSelected: (val) => ref.read(filterStatusProvider.notifier).state = val,
      itemBuilder: (context) => [
        const PopupMenuItem(value: null, child: Text('Все')),
        const PopupMenuItem(value: 'new', child: Text('Новые')),
        const PopupMenuItem(value: 'in_progress', child: Text('В работе')),
        const PopupMenuItem(value: 'completed', child: Text('Завершены')),
        const PopupMenuItem(value: 'rejected', child: Text('Отклонены')),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'new': color = Colors.orange; break;
      case 'in_progress': color = Colors.blue; break;
      case 'completed': color = Colors.green; break;
      case 'rejected': color = Colors.red; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
