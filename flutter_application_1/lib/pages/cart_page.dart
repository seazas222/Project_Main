import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/cart_service.dart';
import '../widgets/app_buttons.dart';
import 'payment_page.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CartService.instance,

      builder: (context, _) {
        final cart = CartService.instance;

        // ยอดรวมสินค้า
        
        final subtotal = cart.subtotal;
        final total = subtotal;

        return Scaffold(
          backgroundColor: AppColors.background,

          appBar: AppBar(
            title: const Text('Your Order'),

            actions: [
              if (cart.items.isNotEmpty)
                TextButton(
                  onPressed: cart.clear,
                  child: const Text(
                    'Clear',
                    style: TextStyle(
                      color: AppColors.orange,
                    ),
                  ),
                ),
            ],
          ),

          body: cart.items.isEmpty
              ? const _EmptyCart()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    10,
                    20,
                    30,
                  ),

                  children: [

                    
                    //  รายการอาหารในตะกร้า
                    
                    ...cart.items.map(
                      (item) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: 12),

                        child: Container(
                          padding:
                              const EdgeInsets.all(10),

                          decoration:
                              BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(16),
                          ),

                          child: Row(
                            children: [

                              //  รูปอาหาร
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(12),

                                child: Image.asset(
                                  item.food.imageAsset,
                                  width: 78,
                                  height: 78,
                                  fit: BoxFit.cover,
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,

                                  children: [

                                    //  ชื่ออาหาร
                                    Text(
                                      item.food.name,
                                      maxLines: 2,
                                      overflow:
                                          TextOverflow.ellipsis,

                                      style:
                                          const TextStyle(
                                        fontSize: 13,
                                        fontWeight:
                                            FontWeight.w500,
                                      ),
                                    ),

                                    const SizedBox(height: 5),

                                    //  ราคาอาหาร
                                    Text(
                                      item.food.price,

                                      style:
                                          const TextStyle(
                                        color:
                                            AppColors.orange,
                                        fontWeight:
                                            FontWeight.w600,
                                      ),
                                    ),

                                    const SizedBox(height: 7),

                                    //  ปุ่มเพิ่ม ลดจำนวน
                                    Row(
                                      children: [

                                        _circle(
                                          icon:
                                              Icons.remove,

                                          onTap: () =>
                                              cart.decrement(
                                            item,
                                          ),
                                        ),

                                        Padding(
                                          padding:
                                              const EdgeInsets
                                                  .symmetric(
                                            horizontal: 10,
                                          ),

                                          child: Text(
                                            '${item.quantity}',
                                          ),
                                        ),

                                        _circle(
                                          icon:
                                              Icons.add,

                                          onTap: () =>
                                              cart.increment(
                                            item,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              //  ราคารวมของเมนูนั้น
                              Text(
                                '฿${item.total.toStringAsFixed(0)}',

                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),                    
                    
                    Container(
                      padding:
                          const EdgeInsets.all(16),

                      decoration:
                          BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(16),
                      ),

                      child: Column(
                        children: [

                          
                          _summary(
                            'ยอดรวมสินค้า',
                            '฿${subtotal.toStringAsFixed(0)}',
                          ),

                          const Divider(height: 22),

                          
                          _summary(
                            'ยอดรวมทั้งหมด',
                            '฿${total.toStringAsFixed(0)}',
                            bold: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    
                    // ไปหน้าชำระเงิน
                    
                    PrimaryButton(
                      text:
                          'ชำระเงิน • ฿${total.toStringAsFixed(0)}',

                      onPressed: () =>
                          Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder: (_) =>
                              PaymentPage(
                            amount: total,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}



// Widget แสดงยอดเงิน


Widget _summary(
  String label,
  String value, {
  bool bold = false,
}) {
  return Row(
    mainAxisAlignment:
        MainAxisAlignment.spaceBetween,

    children: [

      Text(
        label,

        style: TextStyle(
          fontSize: bold ? 16 : 13,
          fontWeight:
              bold
                  ? FontWeight.w600
                  : FontWeight.w400,
        ),
      ),

      Text(
        value,

        style: TextStyle(
          fontSize: bold ? 18 : 13,
          fontWeight:
              bold
                  ? FontWeight.w700
                  : FontWeight.w500,

          color:
              bold
                  ? AppColors.orange
                  : AppColors.text,
        ),
      ),
    ],
  );
}


//  ปุ่ม + / - จำนวนสินค้า

Widget _circle({
  required IconData icon,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,

    borderRadius:
        BorderRadius.circular(15),

    child: Container(
      width: 28,
      height: 28,

      decoration:
          const BoxDecoration(
        color: AppColors.orangeLight,
        shape: BoxShape.circle,
      ),

      child: Icon(
        icon,
        size: 15,
        color: AppColors.orange,
      ),
    ),
  );
}


// กรณีไม่มีสินค้าในตะกร้า


class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize:
            MainAxisSize.min,

        children: [

          Container(
            width: 80,
            height: 80,

            decoration:
                const BoxDecoration(
              color:
                  AppColors.orangeLight,
              shape:
                  BoxShape.circle,
            ),

            child: const Icon(
              Icons.shopping_bag_outlined,
              color:
                  AppColors.orange,
              size: 38,
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            'ยังไม่มีรายการอาหาร',

            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'กรุณาเพิ่มเมนูอาหารก่อน',

            style: TextStyle(
              color:
                  AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }
}