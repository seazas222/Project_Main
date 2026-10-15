import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/api_service.dart';

class RestaurantStatsPage extends StatefulWidget {
  const RestaurantStatsPage({super.key});
  @override
  State<RestaurantStatsPage> createState() => _RestaurantStatsPageState();
}

class _RestaurantStatsPageState extends State<RestaurantStatsPage> {
  late String month;
  late Future<List<Map<String, dynamic>>> future;
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    future = ApiService.getPopularMenus(month);
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text('เมนูยอดนิยมประจำเดือน')),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData && !snapshot.hasError) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
        final rows = snapshot.data!;
        if (rows.isEmpty) return const Center(child: Text('เดือนนี้ยังไม่มีออร์เดอร์ที่ชำระเงินแล้ว'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final row = rows[index];
            final percent = double.tryParse('${row['percentage'] ?? row['percent'] ?? 0}') ?? 0;
            return Card(child: ListTile(
              leading: CircleAvatar(backgroundColor: AppColors.orangeLight, child: Text('${index + 1}')),
              title: Text('${row['menu_name'] ?? row['name'] ?? 'เมนู'}'),
              subtitle: Text('จำนวน ${row['plates'] ?? row['quantity'] ?? row['total_quantity'] ?? 0} จาน'),
              trailing: Text('${percent.toStringAsFixed(1)}%', style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold)),
            ));
          },
        );
      },
    ),
  );
}
