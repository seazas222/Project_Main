import 'package:flutter/material.dart';
import '../widgets/app_bottom_nav.dart';
import 'home_page.dart';
import 'food_menu_page.dart';
import 'booking_page.dart';
import 'profile_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  final pages = const [
    HomePage(),
    FoodMenuPage(),
    BookingPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: pages,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: index,
        onChanged: (value) => setState(() => index = value),
      ),
    );
  }
}
