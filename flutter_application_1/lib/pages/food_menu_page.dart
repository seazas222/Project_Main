import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/food.dart';
import '../services/api_service.dart';
import '../services/cart_service.dart';

import 'food_detail_page.dart';
import 'cart_page.dart';

class FoodMenuPage extends StatefulWidget {

  final int? reservationId;

  final String? reservationTable;
  final int? walkInTableId;
  final String initialCategory;
  final String initialSearch;

  const FoodMenuPage({
    super.key,
    this.reservationId,
    this.reservationTable,
    this.walkInTableId,
    this.initialCategory = 'ทั้งหมด',
    this.initialSearch = '',
  });

  @override
  State<FoodMenuPage> createState() =>
      _FoodMenuPageState();
}

class _FoodMenuPageState
    extends State<FoodMenuPage> {

  List<Food> foods = [];

  bool isLoading = true;

  String? errorMessage;

  late String search;
  late String selectedCategory;

  @override
  void initState() {
    super.initState();
    search = widget.initialSearch;
    selectedCategory = widget.initialCategory;

    _loadMenus();
  }

  Future<void> _loadMenus() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final result =
          await ApiService.getMenus();

      if (!mounted) return;

      setState(() {
        foods = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;

        errorMessage = e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  List<Food> get filteredFoods {
    final keyword =
        search.trim().toLowerCase();

    return foods.where((food) {
      final matchesSearch = keyword.isEmpty || food.name.toLowerCase().contains(keyword);
      final type = _foodCategory(food);
      final matchesCategory = selectedCategory == 'ทั้งหมด' || type == selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  String _foodCategory(Food food) {
    return food.category;
  }

  bool get hasReservation {
    return widget.reservationId != null &&
        widget.reservationTable != null;
  }

  bool get hasOrderContext => hasReservation || widget.walkInTableId != null;

  String get tableLabel => widget.reservationTable ?? 'โต๊ะหน้าร้าน';

  Future<void> _openCategoryPicker() async {
    const categories = ['ทั้งหมด', 'ข้าว', 'เส้น', 'น้ำดื่ม', 'อื่นๆ'];
    final category = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text('เลือกหมวดเมนู', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            ...categories.map((category) => ListTile(
                  leading: Icon(
                    selectedCategory == category ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: selectedCategory == category ? AppColors.orange : AppColors.grey,
                  ),
                  title: Text(category),
                  onTap: () => Navigator.pop(sheetContext, category),
                )),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (category != null && mounted) setState(() => selectedCategory = category);
  }

  void _openFoodDetail(
    Food food,
  ) {
    if (!hasOrderContext) {
      _showReservationMessage();

      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FoodDetailPage(
          food: food,

          reservationId: widget.reservationId,

          reservationTable: tableLabel,
          tableId: widget.walkInTableId,
        ),
      ),
    );
  }

  void _openCart() {
    if (!hasOrderContext) {
      _showReservationMessage();

      return;
    }

    if (CartService.instance.items.isEmpty) {
      ScaffoldMessenger.of(context)
          .hideCurrentSnackBar();

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'ยังไม่มีรายการอาหารในตะกร้า',
          ),
        ),
      );

      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartPage(
          reservationId: widget.reservationId,

          reservationTable: tableLabel,
          tableId: widget.walkInTableId,
        ),
      ),
    );
  }

  void _showReservationMessage() {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'กรุณาจองโต๊ะหรือเลือกโต๊ะสำหรับสั่งที่ร้านก่อน',
        ),
        duration:
            Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final filtered =
        filteredFoods;

    return Scaffold(
      backgroundColor:
          AppColors.background,

      appBar: AppBar(
        backgroundColor:
            AppColors.background,

        elevation: 0,

        title: const Text(
          'รายการอาหาร',

          style: TextStyle(
            fontWeight:
                FontWeight.w600,

            fontSize: 22,
          ),
        ),

      actions: [

          IconButton(
            tooltip: 'กรองหมวดเมนู',
            onPressed: _openCategoryPicker,
            icon: Icon(
              Icons.tune,
              color: selectedCategory == 'ทั้งหมด' ? AppColors.text : AppColors.orange,
            ),
          ),

          AnimatedBuilder(
            animation:
                CartService.instance,

            builder: (
              context,
              child,
            ) {
              final count =
                  CartService.instance
                      .itemCount;

              return Stack(
                children: [
                  IconButton(
                    onPressed:
                        _openCart,

                    icon:
                        const Icon(
                      Icons
                          .shopping_bag_outlined,
                    ),
                  ),

                  if (count > 0)
                    Positioned(
                      right: 4,
                      top: 5,

                      child:
                          Container(
                        padding:
                            const EdgeInsets
                                .all(
                          4,
                        ),

                        constraints:
                            const BoxConstraints(
                          minWidth:
                              18,

                          minHeight:
                              18,
                        ),

                        decoration:
                            const BoxDecoration(
                          color:
                              AppColors
                                  .orange,

                          shape:
                              BoxShape
                                  .circle,
                        ),

                        child:
                            Center(
                          child:
                              Text(
                            '$count',

                            style:
                                const TextStyle(
                              color:
                                  Colors.white,

                              fontSize:
                                  9,

                              fontWeight:
                                  FontWeight
                                      .w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [

            if (hasOrderContext)
              Padding(
                padding:
                    const EdgeInsets
                        .fromLTRB(
                  20,
                  5,
                  20,
                  10,
                ),

                child:
                    Container(
                  width:
                      double.infinity,

                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 15,
                    vertical: 12,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        Colors.white,

                    borderRadius:
                        BorderRadius
                            .circular(
                      14,
                    ),

                    border:
                        Border.all(
                      color:
                          AppColors
                              .border,
                    ),
                  ),

                  child:
                      Row(
                    children: [
                      const Icon(
                        Icons
                            .table_restaurant_outlined,

                        color:
                            AppColors
                                .orange,

                        size:
                            22,
                      ),

                      const SizedBox(
                        width:
                            10,
                      ),

                      const Text(
                        'โต๊ะ',

                        style:
                            TextStyle(
                          color:
                              AppColors
                                  .grey,

                          fontSize:
                              12,
                        ),
                      ),

                      const SizedBox(
                        width:
                            5,
                      ),

                      Text(
                        tableLabel,

                        style:
                            const TextStyle(
                          fontSize:
                              14,

                          fontWeight:
                              FontWeight
                                  .w700,
                        ),
                      ),

                      const Spacer(),

                      Text(
                        widget.reservationId == null ? 'สั่งที่ร้าน' : 'การจอง #${widget.reservationId}',

                        style:
                            const TextStyle(
                          color:
                              AppColors
                                  .grey,

                          fontSize:
                              10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            Padding(
              padding:
                  const EdgeInsets
                      .fromLTRB(
                20,
                5,
                20,
                12,
              ),

              child:
                  TextField(
                onChanged:
                    (value) {
                  setState(() {
                    search =
                        value;
                  });
                },

                decoration:
                    InputDecoration(
                  hintText:
                      'ค้นหาเมนูอาหารหรือเครื่องดื่ม',

                  prefixIcon:
                      const Icon(
                    Icons.search,
                  ),

                  filled:
                      true,

                  fillColor:
                      Colors.white,

                  contentPadding:
                      const EdgeInsets
                          .symmetric(
                    horizontal:
                        15,

                    vertical:
                        12,
                  ),

                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      14,
                    ),

                    borderSide:
                        BorderSide
                            .none,
                  ),

                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      14,
                    ),

                    borderSide:
                        BorderSide
                            .none,
                  ),

                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      14,
                    ),

                    borderSide:
                        const BorderSide(
                      color:
                          AppColors
                              .orange,

                      width:
                          1.2,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(
              height: 48,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                children: ['ทั้งหมด', 'ข้าว', 'เส้น', 'น้ำดื่ม', 'อื่นๆ'].map((category) {
                  final selected = selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: selected,
                      showCheckmark: false,
                      selectedColor: AppColors.orange,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : AppColors.text,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 13,
                      ),
                      side: BorderSide(color: selected ? AppColors.orange : AppColors.border),
                      onSelected: (_) => setState(() => selectedCategory = category),
                    ),
                  );
                }).toList(),
              ),
            ),

            Expanded(
              child:
                  _buildContent(
                filtered,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    List<Food> filtered,
  ) {

    if (isLoading) {
      return const Center(
        child:
            CircularProgressIndicator(
          color:
              AppColors.orange,
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child:
            Padding(
          padding:
              const EdgeInsets
                  .all(
            30,
          ),

          child:
              Column(
            mainAxisSize:
                MainAxisSize.min,

            children: [
              const Icon(
                Icons
                    .error_outline,

                size:
                    55,

                color:
                    Colors.grey,
              ),

              const SizedBox(
                height:
                    15,
              ),

              const Text(
                'ไม่สามารถโหลดรายการอาหารได้',

                textAlign:
                    TextAlign.center,

                style:
                    TextStyle(
                  fontSize:
                      17,

                  fontWeight:
                      FontWeight
                          .w600,
                ),
              ),

              const SizedBox(
                height:
                    8,
              ),

              Text(
                errorMessage ?? '',

                textAlign:
                    TextAlign.center,

                style:
                    const TextStyle(
                  color:
                      AppColors
                          .grey,

                  fontSize:
                      12,
                ),
              ),

              const SizedBox(
                height:
                    18,
              ),

              ElevatedButton(
                onPressed:
                    _loadMenus,

                child:
                    const Text(
                  'ลองอีกครั้ง',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (filtered.isEmpty) {
      return const Center(
        child:
            Column(
          mainAxisSize:
              MainAxisSize.min,

          children: [
            Icon(
              Icons
                  .search_off,

              size:
                  55,

              color:
                  Colors.grey,
            ),

            SizedBox(
              height:
                  12,
            ),

            Text(
              'ไม่พบเมนูอาหาร',

              style:
                  TextStyle(
                fontSize:
                    17,

                fontWeight:
                    FontWeight
                        .w600,
              ),
            ),

            SizedBox(
              height:
                  5,
            ),

            Text(
              'ลองค้นหาด้วยชื่อเมนูอื่น',

              style:
                  TextStyle(
                color:
                    AppColors
                        .grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color:
          AppColors.orange,

      onRefresh:
          _loadMenus,

      child:
          GridView.builder(
        padding:
            const EdgeInsets
                .fromLTRB(
          20,
          5,
          20,
          30,
        ),

        itemCount:
            filtered.length,

        gridDelegate:
            const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 280,
          crossAxisSpacing:
              12,

          mainAxisSpacing:
              12,

          childAspectRatio:
              0.72,
        ),

        itemBuilder:
            (context, index) {
          final food =
              filtered[index];

          return _FoodMenuCard(
            food:
                food,

            onTap:
                () {
              _openFoodDetail(
                food,
              );
            },

          );
        },
      ),
    );
  }
}

class _FoodMenuCard
    extends StatelessWidget {
  final Food food;

  final VoidCallback onTap;

  const _FoodMenuCard({
    required this.food,

    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color:
          Colors.white,

      borderRadius:
          BorderRadius.circular(
        16,
      ),

      child:
          InkWell(
        onTap:
            onTap,

        borderRadius:
            BorderRadius.circular(
          16,
        ),

        child:
            Container(
          decoration:
              BoxDecoration(
            color:
                Colors.white,

            borderRadius:
                BorderRadius
                    .circular(
              16,
            ),

            boxShadow: const [
              BoxShadow(
                color:
                    Color(
                  0x10000000,
                ),

                blurRadius:
                    5,

                offset:
                    Offset(
                  0,
                  2,
                ),
              ),
            ],
          ),

          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,

            children: [

              ClipRRect(
                borderRadius:
                    const BorderRadius
                        .vertical(
                  top:
                      Radius.circular(
                    16,
                  ),
                ),

                child: food.imageUrl != null
                    ? Image.network(food.imageUrl!, width: double.infinity, height: 145, fit: BoxFit.cover, errorBuilder: (_, _, _) => Image.asset(food.imageAsset, width: double.infinity, height: 145, fit: BoxFit.cover))
                    : Image.asset(
                  food.imageAsset,

                  width:
                      double.infinity,

                  height:
                      145,

                  fit:
                      BoxFit.cover,

                  errorBuilder:
                      (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return Container(
                      height:
                          145,

                      color:
                          AppColors
                              .background,

                      child:
                          const Icon(
                        Icons
                            .restaurant,

                        size:
                            45,

                        color:
                            AppColors
                                .grey,
                      ),
                    );
                  },
                ),
              ),

              Expanded(
                child:
                    Padding(
                  padding:
                      const EdgeInsets
                          .fromLTRB(
                    10,
                    9,
                    8,
                    7,
                  ),

                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [

                      Text(
                        food.name,

                        maxLines:
                            2,

                        overflow:
                            TextOverflow
                                .ellipsis,

                        style:
                            const TextStyle(
                          fontSize:
                              13,

                          fontWeight:
                              FontWeight
                                  .w600,
                        ),
                      ),

                      const SizedBox(
                        height:
                            4,
                      ),

                      Text(
                        food.startingPrice,
                        style: const TextStyle(
                          color: AppColors.orange,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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
