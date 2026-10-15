import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/food.dart';
import '../models/table_model.dart';
import '../services/api_service.dart';
import '../services/cart_service.dart';

import '../widgets/food_card.dart';
import '../widgets/section_header.dart';
import '../widgets/search_field.dart';

import 'reservation_page.dart';
import 'food_menu_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
  });

  @override
  State<HomePage> createState() =>
      _HomePageState();
}

class _HomePageState
    extends State<HomePage> {
  late Future<List<Food>> _foodsFuture;
  String? _restaurantBannerImage;
  String _restaurantBannerTitle = 'ร้านอาหาร';

  String search = '';
  String selectedCategory = 'ทั้งหมด';

  Future<void> _openHomeCategoryFilter() async {
    const categories = ['ทั้งหมด', 'ข้าว', 'เส้น', 'น้ำดื่ม', 'อื่นๆ'];
    final chosen = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: Align(alignment: Alignment.centerLeft, child: Text('กรองหมวดเมนู', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
          ),
          ...categories.map((category) => ListTile(
                leading: Icon(
                  selectedCategory == category ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: selectedCategory == category ? AppColors.orange : AppColors.grey,
                ),
                title: Text(category),
                onTap: () => Navigator.pop(sheetContext, category),
              )),
          const SizedBox(height: 10),
        ]),
      ),
    );
    if (chosen != null && mounted) setState(() => selectedCategory = chosen);
  }

  String _foodCategory(Food food) {
    return food.category;
  }

  @override
  void initState() {
    super.initState();

    _foodsFuture =
        ApiService.getMenus();
    _loadRestaurantBanner();
  }

  Future<void> _loadRestaurantBanner() async {
    try {
      final banner = await ApiService.getRestaurantBanner();
      if (mounted) {
        setState(() {
          _restaurantBannerImage = banner['banner_image']?.toString();
          if (_restaurantBannerImage?.isEmpty == true) _restaurantBannerImage = null;
          final title = banner['banner_title']?.toString().trim();
          _restaurantBannerTitle = title == null || title.isEmpty ? 'ร้านอาหาร' : title;
        });
      }
    } catch (_) {
      // Keep the bundled restaurant photo when the server is unavailable.
    }
  }

  void _reloadMenu() {
    setState(() {
      _foodsFuture =
          ApiService.getMenus();
    });
  }

  void _openFoodMenu() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FoodMenuPage(
          initialCategory: selectedCategory,
          initialSearch: search,
        ),
      ),
    );
  }

  Future<void> _openWalkInOrder() async {
    try {
      final tables = await ApiService.getWalkInTables();
      if (!mounted) return;
      if (tables.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ตอนนี้ไม่มีโต๊ะว่างสำหรับสั่งอาหารที่ร้าน')),
        );
        return;
      }
      final selected = await showModalBottomSheet<RestaurantTable>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            children: [
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('เลือกโต๊ะที่นั่งอยู่', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Text('เลือกโต๊ะที่คุณนั่งอยู่จริง เพื่อส่งรายการไปยังครัวได้ถูกโต๊ะ'),
              ),
              ...tables.map((table) => ListTile(
                    leading: const Icon(Icons.table_restaurant_outlined, color: AppColors.orange),
                    title: Text('โต๊ะ ${table.tableNumber}'),
                    subtitle: Text('รองรับ ${table.capacity} คน'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pop(sheetContext, table),
                  )),
            ],
          ),
        ),
      );
      if (!mounted || selected == null) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => FoodMenuPage(
        walkInTableId: selected.id,
        reservationTable: 'โต๊ะ ${selected.tableNumber}',
      )));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('โหลดโต๊ะว่างไม่สำเร็จ: $e')));
    }
  }

  void _showReservationMessage() {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'กรุณาจองโต๊ะก่อนสั่งอาหาร',
        ),
        duration:
            Duration(seconds: 2),
      ),
    );
  }

  void _openReservation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const ReservationPage(),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          AppColors.background,

      body: SafeArea(
        child:
            CustomScrollView(
          slivers: [

            SliverToBoxAdapter(
              child: _Hero(
                bannerImage: _restaurantBannerImage,
                bannerTitle: _restaurantBannerTitle,
                onReserve:
                    _openReservation,

                onMenu:
                    _openFoodMenu,
                onWalkIn: _openWalkInOrder,
              ),
            ),

            SliverPadding(
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                10,
                20,
                0,
              ),

              sliver:
                  SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,

                  children: [
                    const SizedBox(),

                    AnimatedBuilder(
                      animation:
                          CartService
                              .instance,

                      builder:
                          (_, _) {
                        final count =
                            CartService
                                .instance
                                .itemCount;

                        return Badge(
                          isLabelVisible:
                              count > 0,

                          label:
                              Text(
                            '$count',
                          ),

                          child:
                              IconButton(
                            onPressed: () {

                              _showReservationMessage();
                            },

                            icon:
                                const Icon(
                              Icons
                                  .shopping_bag_outlined,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding:
                  const EdgeInsets.fromLTRB(
                35,
                18,
                20,
                0,
              ),

              sliver:
                  SliverToBoxAdapter(
                child:
                    AppSearchField(
                  hint:
                      'ค้นหาเมนู',

                  onChanged:
                      (value) {
                    setState(() {
                      search =
                          value;
                    });
                  },
                  onFilter: _openHomeCategoryFilter,
                ),
              ),
            ),

            SliverPadding(
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                18,
                20,
                0,
              ),

              sliver:
                  SliverToBoxAdapter(
                child:
                    _ReservationPreview(
                  onTap:
                      _openReservation,
                ),
              ),
            ),

            SliverPadding(
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                15,
                20,
                0,
              ),

              sliver:
                  SliverToBoxAdapter(
                child:
                    SectionHeader(
                  title:
                      'เมนูยอดนิยม',

                  action:
                      'ดูทั้งหมด',

                  onAction:
                      _openFoodMenu,
                ),
              ),
            ),

            SliverPadding(
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                0,
                20,
                30,
              ),

              sliver:
                  FutureBuilder<
                      List<Food>>(
                future:
                    _foodsFuture,

                builder:
                    (
                  context,
                  snapshot,
                ) {

                  if (snapshot
                          .connectionState ==
                      ConnectionState
                          .waiting) {
                    return const SliverToBoxAdapter(
                      child:
                          Padding(
                        padding:
                            EdgeInsets
                                .all(
                          40,
                        ),

                        child:
                            Center(
                          child:
                              CircularProgressIndicator(
                            color:
                                AppColors
                                    .orange,
                          ),
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return SliverToBoxAdapter(
                      child:
                          Padding(
                        padding:
                            const EdgeInsets
                                .all(
                          30,
                        ),

                        child:
                            Column(
                          children: [
                            const Icon(
                              Icons
                                  .error_outline,

                              size:
                                  45,

                              color:
                                  Colors.red,
                            ),

                            const SizedBox(
                              height:
                                  10,
                            ),

                            const Text(
                              'ไม่สามารถโหลดเมนูได้',

                              style:
                                  TextStyle(
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),

                            const SizedBox(
                              height:
                                  5,
                            ),

                            Text(
                              '${snapshot.error}',

                              textAlign:
                                  TextAlign
                                      .center,

                              style:
                                  const TextStyle(
                                fontSize:
                                    11,

                                color:
                                    AppColors
                                        .grey,
                              ),
                            ),

                            const SizedBox(
                              height:
                                  12,
                            ),

                            ElevatedButton(
                              onPressed:
                                  _reloadMenu,

                              child:
                                  const Text(
                                'ลองใหม่',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final allFoods =
                      snapshot.data ??
                          [];

                  final popular =
                      allFoods
                          .where(
                            (food) {
                              final matchesText = food.name.toLowerCase().contains(search.toLowerCase());
                              final matchesCategory = selectedCategory == 'ทั้งหมด' || _foodCategory(food) == selectedCategory;
                              return matchesText && matchesCategory;
                            },
                          )
                          .take(4)
                          .toList();

                  if (popular.isEmpty) {
                    return const SliverToBoxAdapter(
                      child:
                          Padding(
                        padding:
                            EdgeInsets
                                .all(
                          40,
                        ),

                        child:
                            Center(
                          child:
                              Text(
                            'ไม่พบเมนูที่ค้นหา',

                            style:
                                TextStyle(
                              color:
                                  AppColors
                                      .grey,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverGrid(
                    delegate:
                        SliverChildBuilderDelegate(
                      (
                        context,
                        index,
                      ) {
                        final food =
                            popular[index];

                        return FoodCard(
                          food:
                              food,

                          onTap: () {
                            _showReservationMessage();
                          },

                          onAdd: () {
                            _showReservationMessage();
                          },
                        );
                      },

                      childCount:
                          popular.length,
                    ),

                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          2,

                      crossAxisSpacing:
                          13,

                      mainAxisSpacing:
                          13,

                      childAspectRatio:
                          .72,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero
    extends StatelessWidget {
  final String? bannerImage;
  final String bannerTitle;

  final VoidCallback onReserve;

  final VoidCallback onMenu;
  final VoidCallback onWalkIn;

  const _Hero({
    required this.bannerImage,
    required this.bannerTitle,
    required this.onReserve,
    required this.onMenu,
    required this.onWalkIn,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.all(
        12,
      ),

      child:
          ClipRRect(
        borderRadius:
            BorderRadius.circular(
          24,
        ),

        child:
            SizedBox(
          height:
              245,

          child:
              Stack(
            fit:
                StackFit.expand,

            children: [

              bannerImage == null
                  ? Image.asset('assets/restaurant.jpg', fit: BoxFit.cover)
                  : Image.network(
                      ApiService.restaurantBannerImageUrl(bannerImage!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Image.asset('assets/restaurant.jpg', fit: BoxFit.cover),
                    ),

              Container(
                decoration:
                    const BoxDecoration(
                  gradient:
                      LinearGradient(
                    begin:
                        Alignment
                            .topCenter,

                    end:
                        Alignment
                            .bottomCenter,

                    colors: [
                      Color(
                        0x77000000,
                      ),

                      Color(
                        0x00000000,
                      ),

                      Color(
                        0x88000000,
                      ),
                    ],
                  ),
                ),
              ),

              Positioned(
                left:
                    24,

                top:
                    24,

                child:
                    Text(
                  bannerTitle,

                  style:
                      TextStyle(
                    color:
                        Colors.white,

                    fontSize:
                        26,

                    fontWeight:
                        FontWeight
                            .w600,
                  ),
                ),
              ),

              Positioned(
                left: 20,
                right: 20,
                top: 76,

                child:
                    Row(
                  children: [

                    Expanded(
                      child:
                          ElevatedButton(
                        onPressed:
                            onReserve,

                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              AppColors
                                  .orange,

                          foregroundColor:
                              Colors.white,

                          minimumSize:
                              const Size(
                            0,
                            48,
                          ),

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              14,
                            ),
                          ),
                        ),

                        child:
                            const Text(
                          'จองโต๊ะ',
                        ),
                      ),
                    ),

                    const SizedBox(
                      width:
                          10,
                    ),

                    Expanded(
                      child:
                          OutlinedButton(
                        onPressed:
                            onMenu,

                        style:
                            OutlinedButton
                                .styleFrom(
                          backgroundColor:
                              Colors
                                  .white
                                  .withValues(alpha: .92),

                          foregroundColor:
                              AppColors
                                  .text,

                          minimumSize:
                              const Size(
                            0,
                            48,
                          ),

                          side:
                              BorderSide
                                  .none,

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              14,
                            ),
                          ),
                        ),

                        child:
                            const Text(
                          'ดูเมนู',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Positioned(
                left: 20,
                right: 20,
                top: 136,
                child: OutlinedButton.icon(
                  onPressed: onWalkIn,
                  icon: const Icon(Icons.restaurant, size: 18),
                  label: const Text('สั่งอาหารที่ร้าน'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: .94),
                    foregroundColor: AppColors.orange,
                    minimumSize: const Size(0, 44),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReservationPreview
    extends StatelessWidget {
  final VoidCallback onTap;

  const _ReservationPreview({
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return InkWell(
      onTap:
          onTap,

      borderRadius:
          BorderRadius.circular(
        18,
      ),

      child:
          Container(
        padding:
            const EdgeInsets.all(
          15,
        ),

        decoration:
            BoxDecoration(
          color:
              Colors.white,

          borderRadius:
              BorderRadius.circular(
            18,
          ),

          boxShadow: const [
            BoxShadow(
              color:
                  Color(
                0x12000000,
              ),

              blurRadius:
                  8,

              offset:
                  Offset(
                0,
                3,
              ),
            ),
          ],
        ),

        child:
            Row(
          children: [

            Container(
              width:
                  48,

              height:
                  48,

              decoration:
                  BoxDecoration(
                color:
                    AppColors
                        .orangeLight,

                borderRadius:
                    BorderRadius
                        .circular(
                  14,
                ),
              ),

              child:
                  const Icon(
                Icons
                    .calendar_month,

                color:
                    AppColors
                        .orange,
              ),
            ),

            const SizedBox(
              width:
                  12,
            ),

            const Expanded(
              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [
                  Text(
                    'การจองโต๊ะ',

                    style:
                        TextStyle(
                      fontSize:
                          12,

                      color:
                          AppColors
                              .grey,
                    ),
                  ),

                  SizedBox(
                    height:
                        4,
                  ),

                  Text(
                    'ดูรายละเอียดการจองของคุณ',

                    style:
                        TextStyle(
                      fontSize:
                          14,

                      fontWeight:
                          FontWeight
                              .w600,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right,
            ),
          ],
        ),
      ),
    );
  }
}
