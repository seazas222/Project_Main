import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/api_service.dart';

class NotificationInboxPage extends StatefulWidget {
  const NotificationInboxPage({super.key});
  @override
  State<NotificationInboxPage> createState() => _NotificationInboxPageState();
}

class _NotificationInboxPageState extends State<NotificationInboxPage> {
  late Future<List<Map<String, dynamic>>> future;
  @override
  void initState() { super.initState(); future = ApiService.getNotifications(); }
  Future<void> _refresh() async {
    final refreshed = ApiService.getNotifications();
    if (mounted) {
      setState(() {
        future = refreshed;
      });
    }
    try {
      await refreshed;
    } catch (_) {
      // FutureBuilder renders the error state.
    }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text('การแจ้งเตือน')),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData && !snapshot.hasError) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
        final rows = snapshot.data!;
        if (rows.isEmpty) return const Center(child: Text('ยังไม่มีการแจ้งเตือน'));
        return RefreshIndicator(onRefresh: _refresh, child: ListView.builder(
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final row = rows[index];
            final enabledWhenSent = row['notifications_enabled'] == true ||
                row['notifications_enabled'].toString() == '1';
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 28,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: IgnorePointer(
                        child: Icon(
                          enabledWhenSent ? Icons.notifications_active : Icons.notifications_none,
                          color: enabledWhenSent ? AppColors.orange : AppColors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${row['title'] ?? 'แจ้งเตือน'}'),
                        Text('${row['body'] ?? row['message'] ?? ''}'),
                        Text(
                          '${row['sent_at'] ?? row['created_at'] ?? ''}',
                          style: const TextStyle(color: AppColors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ));
      },
    ),
  );
}
