import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lad_admin/models/application.dart';
import 'package:lad_admin/widgets/application_card.dart';
import 'package:lad_admin/providers/dashboard_provider.dart';

final filterStatusProvider = StateProvider<String?>((ref) => null);

final filteredApplicationsProvider = FutureProvider<List<Application>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final status = ref.watch(filterStatusProvider);
  
  final queryParams = <String, dynamic>{};
  if (status != null) queryParams['status'] = status;
  
  final response = await api.get('/admin/applications', queryParameters: queryParams);
  final data = response.data['applications'] as List;
  return data.map((e) => Application.fromJson(e)).toList();
});

class ApplicationsScreen extends ConsumerWidget {
  const ApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(filteredApplicationsProvider);
    final currentFilter = ref.watch(filterStatusProvider);
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F5),
      appBar: isDesktop ? null : AppBar(
        title: const Text('Все заявки'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          _buildFilterButton(context, ref, currentFilter),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            children: [
              if (isDesktop) 
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 48, 32, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Все заявки', 
                        style: TextStyle(
                          fontSize: 36, 
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1B2C16),
                        )
                      ),
                      _buildFilterButton(context, ref, currentFilter),
                    ],
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => ref.refresh(filteredApplicationsProvider.future),
                  child: applicationsAsync.when(
                    data: (apps) {
                      if (apps.isEmpty) {
                        return const Center(child: Text("Заявок не найдено"));
                      }
                      
                      return GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: screenWidth > 1200 ? 3 : (screenWidth > 700 ? 2 : 1),
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                          mainAxisExtent: 380,
                        ),
                        itemCount: apps.length,
                        itemBuilder: (context, index) {
                          final app = apps[index];
                          return ApplicationCard(
                            application: app,
                            onTap: () => context.push('/applications/${app.id}'),
                          );
                        },
                      );
                    },
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

}
