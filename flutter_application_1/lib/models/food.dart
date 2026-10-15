import '../services/api_service.dart';

class Food {
  final String id;
  final String name;
  final String price;
  final double rating;
  final String category;
  final String imageAsset;
  final String? imageUrl;
  final String description;
  final List<Map<String, dynamic>> optionGroups;

  const Food({
    required this.id,
    required this.name,
    required this.price,
    required this.rating,
    required this.category,
    required this.imageAsset,
    this.imageUrl,
    required this.description,
    this.optionGroups = const [],
  });

  double get minimumOrderPrice {
    var amount = double.tryParse(price.replaceAll('฿', '').replaceAll(',', '').trim()) ?? 0;
    for (final group in optionGroups) {
      if (group['required'] == false) continue;
      final available = (group['options'] as List<dynamic>? ?? [])
          .where((raw) => raw is Map && raw['available'] != false && raw['sold_out'] != true)
          .map((raw) => double.tryParse((raw as Map)['extra_price']?.toString() ?? '') ?? 0)
          .toList();
      if (available.isNotEmpty) {
        available.sort();
        amount += available.first;
      }
    }
    return amount;
  }

  String get startingPrice {
    final amount = minimumOrderPrice;
    return 'เริ่มต้น ฿${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}';
  }

  factory Food.fromJson(Map<String, dynamic> json) {
    final id = json['menu_id']?.toString() ?? '';
    final name = json['menu_name']?.toString() ?? '';

    String imageAsset;

    if (json['imageAsset'] != null &&
        json['imageAsset'].toString().isNotEmpty) {
      imageAsset = json['imageAsset'].toString();
    } else {
      const menuImageIds = <String, String>{
        'ข้าวผัด': '1',
        'ข้าวผัดกะเพรา': '2',
        'ข้าวเครื่องแกง': '3',
        'ผัดซีอิ๊ว': '4',
        'ข้าวไข่เจียว': '6',
        'ข้าวผัดคะน้า': '14',
        'ข้าวผัดกระเทียม': '15',
        'ข้าวผัดผักรวมมิตร': '18',
        'สุกี้แห้ง': '26',
        'ก๋วยเตี๋ยวคั่ว': '28',
        'ไข่ดาว': '31',
        'ไข่เจียว': '32',
        'ก๋วยเตี๋ยว': '33',
        'ก๋วยเตี๋ยวน้ำ': '33',
        'เกาเหลา': '34',
        'โค้ก': '35',
        'น้ำแดง': '36',
        'สไปร์': '37',
      };
      final imageId = menuImageIds[name];
      imageAsset = imageId == null
          ? 'assets/restaurant.jpg'
          : 'assets/menu/menu_$imageId.png';
    }

    return Food(
      id: id,
      name: name,
      price: '฿${json['price']}',
      rating: double.tryParse(
            json['rating']?.toString() ?? '',
          ) ??
          0.0,
      category: const ['ข้าว', 'เส้น', 'น้ำดื่ม', 'อื่นๆ'].contains(json['category']?.toString()) ? json['category'].toString() : (name.contains('ข้าว') ? 'ข้าว' : (name.contains('เส้น') || name.contains('ก๋วยเตี๋ยว') || name.contains('เกาเหลา') ? 'เส้น' : 'อื่นๆ')),
      imageAsset: imageAsset,
      imageUrl: json['menu_image'] == null || json['menu_image'].toString().isEmpty
          ? null
          : '${ApiService.baseUrl}/menu/$id/image?v=${Uri.encodeComponent(json['menu_image'].toString())}',
      description: json['description']?.toString() ?? '',
      optionGroups: (json['option_groups'] as List<dynamic>? ?? [])
          .map((group) => Map<String, dynamic>.from(group as Map))
          .toList(),
    );
  }

}
