import 'package:flutter/material.dart';
import 'package:launchfast/constants/app_colors.dart';
import 'package:launchfast/services/api_service.dart';
import 'package:intl/intl.dart';

class ActivityMonitorScreen extends StatefulWidget {
  const ActivityMonitorScreen({super.key});

  @override
  State<ActivityMonitorScreen> createState() => _ActivityMonitorScreenState();
}

class _ActivityMonitorScreenState extends State<ActivityMonitorScreen> {
  List<dynamic> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      final res = await apiService.dio.get('/admin/audit-logs');
      setState(() {
        _logs = res.data;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Activity Monitor',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadLogs,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  return _buildLogCard(log, isDark, textColor, muted);
                },
              ),
            ),
    );
  }

  Widget _buildLogCard(
    Map<String, dynamic> log,
    bool isDark,
    Color textColor,
    Color muted,
  ) {
    final action = log['action'] as String;
    final date = DateTime.parse(log['createdAt']);
    final admin = log['admin']?['name'] ?? 'System';

    IconData actionIcon = Icons.info_outline_rounded;
    Color actionColor = Colors.blue;

    if (action.contains('CREATE')) {
      actionIcon = Icons.add_circle_outline_rounded;
      actionColor = Colors.green;
    } else if (action.contains('UPDATE')) {
      actionIcon = Icons.edit_note_rounded;
      actionColor = Colors.orange;
    } else if (action.contains('DELETE') || action.contains('SUSPEND')) {
      actionIcon = Icons.warning_amber_rounded;
      actionColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: actionColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(actionIcon, color: actionColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      action.replaceAll('_', ' '),
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm').format(date),
                      style: TextStyle(color: muted, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('By $admin', style: TextStyle(color: muted, fontSize: 12)),
                if (log['resource'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Resource: ${log['resource']} (${log['resourceId']?.toString().substring(0, 8) ?? 'N/A'})',
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
