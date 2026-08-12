import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../widgets/app_buttons.dart';
import 'login_page.dart';
import 'signup_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const SizedBox(height: 35),
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.orangeLight,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.orange,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu,
                    color: AppColors.orange,
                    size: 45,
                  ),
                ),
                const SizedBox(height: 25),
                const Text(
                  'Welcome to',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Restaurant App',
                  style: TextStyle(
                    color: AppColors.orange,
                    fontSize: 31,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'จองโต๊ะ • สั่งอาหารล่วงหน้า • ชำระเงิน\nได้ง่ายในแอปเดียว',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.grey,
                    height: 1.5,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 42),
                PrimaryButton(
                  text: 'Log in',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginPage(),
                    ),
                  ),
                ),
                const SizedBox(height: 13),
                SecondaryButton(
                  text: 'Sign up',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SignUpPage(),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: Image.asset(
                      'assets/google_icon.webp',
                      width: 20,
                      height: 20,
                    ),
                    label: const Text('Continue with Google'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 55),
                const Text(
                  'Reserve your table • Pre-order your meal',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
