import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../data/food_data.dart';
import '../services/cart_service.dart';
import '../widgets/food_card.dart';
import '../widgets/section_header.dart';
import '../widgets/search_field.dart';
import 'reservation_page.dart';
import 'food_detail_page.dart';
import 'cart_page.dart';
import 'food_menu_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final popular = foods.take(4).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _Hero(
                onReserve: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ReservationPage(),
                  ),
                ),
                onMenu: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FoodMenuPage(),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                    ),
                    AnimatedBuilder(
                      animation: CartService.instance,
                      builder: (_, __) {
                        return Badge(
                          isLabelVisible:
                              CartService.instance.itemCount > 0,
                          label: Text(
                            '${CartService.instance.itemCount}',
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CartPage(),
                              ),
                            ),
                            icon: const Icon(
                              Icons.shopping_bag_outlined,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(35, 18, 20, 0),
              sliver: SliverToBoxAdapter(
                child: AppSearchField(
                  hint: 'Search',
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _ReservationPreview(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ReservationPage(),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 0),
              sliver: SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'เมนูยอดนิยม',
                  action: 'ดูทั้งหมด',
                  onAction: () {},
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final food = popular[index];
                    return FoodCard(
                      food: food,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FoodDetailPage(food: food),
                        ),
                      ),
                      onAdd: () {
                        CartService.instance.add(food);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${food.name} added to cart'),
                            duration: const Duration(milliseconds: 900),
                          ),
                        );
                      },
                    );
                  },
                  childCount: popular.length,
                ),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 13,
                  mainAxisSpacing: 13,
                  childAspectRatio: .72,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final VoidCallback onReserve;
  final VoidCallback onMenu;

  const _Hero({
    required this.onReserve,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 330,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/restaurant.jpg',
                fit: BoxFit.cover,
              ),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x77000000),
                      Color(0x00000000),
                      Color(0x88000000),
                    ],
                  ),
                ),
              ),
              const Positioned(
                left: 24,
                top: 24,
                child: Text(
                  'Restaurant',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Positioned(
                left: 22,
                right: 22,
                top: 72,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.92),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      filled: false,
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search for a dish or table',
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 18,
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onReserve,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orange,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Reserve a Table'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onMenu,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(.92),
                          foregroundColor: AppColors.text,
                          minimumSize: const Size(0, 48),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Order Food'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReservationPreview extends StatelessWidget {
  final VoidCallback onTap;

  const _ReservationPreview({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.orangeLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.calendar_month,
                color: AppColors.orange,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your next reservation',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.grey,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Today • 18:30 • Table T004',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
