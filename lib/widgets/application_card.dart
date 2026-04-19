import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lad_admin/models/application.dart';

class ApplicationCard extends StatefulWidget {
  final Application application;
  final VoidCallback onTap;

  const ApplicationCard({
    super.key,
    required this.application,
    required this.onTap,
  });

  @override
  State<ApplicationCard> createState() => _ApplicationCardState();
}

class _ApplicationCardState extends State<ApplicationCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final app = widget.application;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: _isHovered 
            ? (Matrix4.identity()..translate(0, -4, 0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: _isHovered 
                ? const Color(0xFF4A6741).withOpacity(0.3)
                : const Color(0xFFE8EDE4).withOpacity(0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered 
                  ? Colors.black.withOpacity(0.12)
                  : Colors.black.withOpacity(0.04),
              blurRadius: _isHovered ? 24 : 8,
              offset: Offset(0, _isHovered ? 8 : 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: InkWell(
            onTap: widget.onTap,
            hoverColor: Colors.transparent,
            splashColor: const Color(0xFF4A6741).withOpacity(0.05),
            child: Stack(
              children: [
                // Background Gradient Header
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 110,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFE8EDE4), // sage-light
                          Color(0xFFF9F7F2), // cream
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  app.source.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 3,
                                    color: Color(0xFF5D7453),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  app.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1B2C16), // forest
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${app.gender ?? "Пол не указан"}${app.age != null ? ", ${app.age} лет" : ""}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: const Color(0xFF1B2C16).withOpacity(0.55),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Application ID Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE8EDE4).withOpacity(0.5)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  "НОМЕР",
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2,
                                    color: Color(0x591B2C16),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "#${app.id.toString().padLeft(4, '0')}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1B2C16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Reason Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F7F2).withOpacity(0.7),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE8EDE4).withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "ПРИЧИНА ОБРАЩЕНИЯ",
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                                color: Color(0x591B2C16),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              app.reason,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.6,
                                color: const Color(0xFF1B2C16).withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Info Grid
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildMiniInfo("Время", app.preferredTime ?? "Любое"),
                          _buildMiniInfo("Связь", app.contactMethod),
                          _buildMiniInfo("Дата", DateFormat('dd.MM.yyyy').format(app.createdAt)),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Footer Status
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE8EDE4).withOpacity(0.3)),
                        ),
                        child: _buildStatusRow(app.status),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniInfo(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EDE4).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(fontSize: 11, color: Color(0xFF5D7453)),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1B2C16)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String status) {
    Color color;
    String label;
    IconData icon;
    
    switch (status) {
      case 'new': 
        color = Colors.orange; 
        label = "Новая";
        icon = Icons.fiber_new;
        break;
      case 'in_progress': 
        color = Colors.blue; 
        label = "В работе";
        icon = Icons.sync;
        break;
      case 'completed': 
        color = Colors.green; 
        label = "Завершена";
        icon = Icons.check_circle;
        break;
      case 'rejected': 
        color = Colors.red; 
        label = "Отклонена";
        icon = Icons.cancel;
        break;
      default: 
        color = Colors.grey; 
        label = status;
        icon = Icons.help;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color, 
                fontSize: 13, 
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Icon(Icons.chevron_right, size: 20, color: const Color(0xFF1B2C16).withOpacity(0.3)),
      ],
    );
  }
}
