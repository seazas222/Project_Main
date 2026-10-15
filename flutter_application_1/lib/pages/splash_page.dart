import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import 'welcome_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  void _goToWelcome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const WelcomePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _goToWelcome,

        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/restaurant.jpg',
              fit: BoxFit.cover,
            ),

            Container(
              color: Colors.black.withValues(alpha: .52),
            ),

            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.orange,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.restaurant_menu,
                      color: AppColors.orange,
                      size: 44,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'ร้านอาหาร',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 31,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const Text(
                    'Reserve • Order • Enjoy',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 28),

                  const SizedBox(height: 10),

                  const Icon(
                    Icons.touch_app_outlined,
                    color: AppColors.orange,
                    size: 25,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
