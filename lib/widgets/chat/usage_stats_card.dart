import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as Math;
import 'package:lad_admin/models/admin_chat_usage.dart';


class UsageStatsCard extends StatelessWidget {
  final AdminChatUsage usage;

  const UsageStatsCard({super.key, required this.usage});

  @override
  Widget build(BuildContext context) {
    final percent = usage.percent.clamp(0.0, 100.0);
    final String sizeText = _formatBytes(usage.totalBytes);
    final String capText = _formatBytes(usage.monthlyCapBytes);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Использование трафика',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$sizeText / $capText',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${percent.toStringAsFixed(2)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 12,
              backgroundColor: const Color(0xFFE5E7EB),
              color: _getColor(percent),
            ),
          ).animate().shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.mic, size: 14, color: Color(0xFF6B7280)),
              const SizedBox(width: 4),
              Text(
                'Звонков совершено: ${usage.inviteCount}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getColor(double percent) {
    if (percent < 70) return const Color(0xFF10B981); // Green
    if (percent < 90) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFFEF4444); // Red
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (Math.log(bytes) / Math.log(1024)).floor();
    return ((bytes / Math.pow(1024, i)).toStringAsFixed(2)) + ' ' + suffixes[i];
  }
}


