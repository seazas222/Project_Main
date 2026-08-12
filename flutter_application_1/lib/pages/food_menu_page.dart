import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../data/food_data.dart';
import '../services/cart_service.dart';

import '../widgets/food_card.dart';
import '../widgets/search_field.dart';
import 'food_detail_page.dart';
import 'cart_page.dart';

class FoodMenuPage extends StatefulWidget {
  const FoodMenuPage({super.key});

  @override
  State<FoodMenuPage> createState() => _FoodMenuPageState();
}

class _FoodMenuPageState extends State<FoodMenuPage> {
  String category = 'All';
  String search = '';

  @override
  Widget build(BuildContext context) {
    final categories = ['All', 'Thai', 'Main', 'Drinks'];
    final filtered = foods.where((food) {
      final matchCategory =
          category == 'All' || food.category == category;
      final matchSearch =
          food.name.toLowerCase().contains(search.toLowerCase());
      return matchCategory && matchSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.background,
              title: const Text(
                'Food Menu',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 24,
                ),
              ),
              actions: [
                AnimatedBuilder(
                  animation: CartService.instance,
                  builder: (_, __) => Badge(
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
                  ),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              sliver: SliverToBoxAdapter(
                child: AppSearchField(
                  hint: 'Search menu',
                  onChanged: (value) => setState(() => search = value),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 58,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final item = categories[index];
                    final selected = category == item;
                    return ChoiceChip(
                      label: Text(item),
                      selected: selected,
                      onSelected: (_) =>
                          setState(() => category = item),
                      selectedColor: AppColors.orange,
                      labelStyle: TextStyle(
                        color: selected
                            ? Colors.white
                            : AppColors.text,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 30),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final food = filtered[index];
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
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${food.name} added'),
                            duration: const Duration(milliseconds: 800),
                          ),
                        );
                      },
                    );
                  },
                  childCount: filtered.length,
                ),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 13,
                  mainAxisSpacing: 13,
                  mainAxisExtent: 280,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
