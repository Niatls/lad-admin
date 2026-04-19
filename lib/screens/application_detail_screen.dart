import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lad_admin/providers/dashboard_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

final applicationDetailProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, id) async {
  final api = ref.watch(apiClientProvider);
  // In a real app, we might have a GET /api/admin/applications/[id]
  // For now, let's assume we can fetch it or find it in the dashboard list
  // or just fetch all and filter (less efficient but works for now)
  final response = await api.get('/admin/applications');
  final List apps = response.data['applications'];
  return apps.firstWhere((a) => a['id'] == id);
});

class ApplicationDetailScreen extends ConsumerStatefulWidget {
  final int id;
  const ApplicationDetailScreen({super.key, required this.id});

  @override
  ConsumerState<ApplicationDetailScreen> createState() => _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends ConsumerState<ApplicationDetailScreen> {
  bool _isUpdating = false;

  Future<void> _updateStatus(String status) async {
    setState(() => _isUpdating = true);
    final api = ref.read(apiClientProvider);
    try {
      await api.patch('/admin/applications/${widget.id}', data: {'status': status});
      ref.refresh(applicationDetailProvider(widget.id));
      ref.read(dashboardProvider.notifier).fetchData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Статус обновлен на: $status')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при обновлении статуса')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(applicationDetailProvider(widget.id));
    final bool isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F5),
      appBar: isDesktop ? null : AppBar(title: Text('Заявка #${widget.id}')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: detailAsync.when(
            data: (app) => SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isDesktop) ...[
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildHeader(app),
                  const SizedBox(height: 32),
                  _buildSection('Контактные данные', [
                    _buildInfoRow('Метод', app['contactMethod']),
                    _buildInfoRow('Значение', app['contactValue'] ?? 'Не указано'),
                    _buildInfoRow('Email', app['email'] ?? 'Нет'),
                    _buildInfoRow('Телефон', app['phone'] ?? 'Нет'),
                  ]),
                  const SizedBox(height: 24),
                  _buildSection('Информация', [
                    _buildInfoRow('Возраст', app['age']?.toString() ?? '-'),
                    _buildInfoRow('Пол', app['gender'] ?? '-'),
                    _buildInfoRow('Источник', app['source']),
                    _buildInfoRow('Время', app['preferredTime'] ?? 'Любое'),
                  ]),
                  const SizedBox(height: 24),
                  _buildSection('Причина обращения', [
                    Text(app['reason'], style: const TextStyle(fontSize: 16)),
                  ]),
                  const SizedBox(height: 32),
                  const Text('Изменить статус', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildStatusActions(app['status']),
                  if (_isUpdating) const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())),
                ],
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, st) => Center(child: Text('Error: $err')),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> app) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(app['name'], style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          'Создана ${DateFormat('dd MMMM yyyy HH:mm').format(DateTime.parse(app['createdAt']))}',
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A6741))),
        const Divider(),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStatusActions(String currentStatus) {
    final statuses = {
      'new': Colors.orange,
      'in_progress': Colors.blue,
      'completed': Colors.green,
      'rejected': Colors.red,
    };

    return Wrap(
      spacing: 8,
      children: statuses.entries.map((e) {
        final isCurrent = currentStatus == e.key;
        return ActionChip(
          label: Text(e.key),
          onPressed: isCurrent ? null : () => _updateStatus(e.key),
          backgroundColor: isCurrent ? e.value.withOpacity(0.5) : e.value.withOpacity(0.1),
          labelStyle: TextStyle(color: isCurrent ? Colors.white : e.value, fontWeight: FontWeight.bold),
        );
      }).toList(),
    );
  }
}
