import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lad_admin/providers/dashboard_provider.dart';
import 'package:lad_admin/core/auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:lad_admin/core/update_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _hasCheckedForUpdates = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    if (_hasCheckedForUpdates) return;
    _hasCheckedForUpdates = true;

    final updateService = UpdateService();
    final updateInfo = await updateService.checkForUpdates();
    
    if (updateInfo != null && mounted) {
      _showUpdateDialog(updateInfo);
    }
  }

  void _showUpdateDialog(UpdateInfo updateInfo) {
    showDialog(
      context: context,
      barrierDismissible: !updateInfo.mandatory,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          bool isDownloading = false;
          double progress = 0;

          return AlertDialog(
            title: Text('Доступно обновление ${updateInfo.version}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(updateInfo.releaseNotes.isNotEmpty 
                  ? updateInfo.releaseNotes 
                  : 'Появилась новая версия приложения. Рекомендуем обновиться!'),
                if (isDownloading) ...[
                  const SizedBox(height: 20),
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 8),
                  Text('Загрузка: ${(progress * 100).toStringAsFixed(0)}%'),
                ]
              ],
            ),
            actions: [
              if (!updateInfo.mandatory && !isDownloading)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Позже'),
                ),
              if (!isDownloading)
                ElevatedButton(
                  onPressed: () async {
                    setState(() => isDownloading = true);
                    try {
                      await UpdateService().applyUpdate(updateInfo, (p) {
                        setState(() => progress = p);
                      });
                    } catch (e) {
                      setState(() => isDownloading = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Ошибка обновления: $e')),
                      );
                    }
                  },
                  child: const Text('Обновить сейчас'),
                ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final bool isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F5),
      appBar: isDesktop ? null : AppBar(title: const Text('Дашборд')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardProvider.notifier).fetchData(),
        child: dashboardAsync.when(
          data: (data) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isDesktop) ...[
                      const Text('Дашборд', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                    ],
                    _buildStatsGrid(data.totals, data.totalApplications, isDesktop),
                    const SizedBox(height: 48),
                    const Text(
                      'Последние заявки',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ...data.applications.take(5).map((app) => _buildApplicationCard(context, app)),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () => context.push('/applications'),
                        child: const Text('Смотреть все заявки', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, int> totals, int total, bool isDesktop) {
    return GridView.count(
      crossAxisCount: isDesktop ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      childAspectRatio: isDesktop ? 1.8 : 1.4,
      children: [
        _buildStatCard('Всего', total.toString(), Colors.blueGrey),
        _buildStatCard('Новые', (totals['new'] ?? 0).toString(), Colors.orange),
        _buildStatCard('В работе', (totals['in_progress'] ?? 0).toString(), Colors.blue),
        _buildStatCard('Завершено', (totals['completed'] ?? 0).toString(), Colors.green),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationCard(BuildContext context, dynamic app) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        title: Text(app.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${app.contactMethod}: ${app.contactValue ?? "-"}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(app.status).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            app.status,
            style: TextStyle(color: _getStatusColor(app.status), fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        onTap: () => context.push('/applications/${app.id}'),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'new': return Colors.orange;
      case 'in_progress': return Colors.blue;
      case 'completed': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }
}
