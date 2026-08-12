import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../widgets/app_buttons.dart';
import '../services/current_user_service.dart';

import 'welcome_page.dart';
import 'personal_information_page.dart';
import 'reservation_history_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = CurrentUserService.instance.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 25, 20, 30),
          children: [
            const Text(
              'Profile',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 43,
                    backgroundColor: AppColors.orangeLight,
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: AppColors.orange,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    user?.fullname ?? 'User',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    user?.username ?? '',
                    style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 11,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    user?.phone ?? 'ไม่พบเบอร์โทรศัพท์',
                    style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // Personal information
            _item(
              Icons.person_outline,
              'Personal information',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const PersonalInformationPage(),
                  ),
                );
              },
            ),

            // Booking history
            _item(
              Icons.history,
              'Booking history',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const ReservationHistoryPage(),
                  ),
                );
              },
            ),

            // Notifications
            _item(
              Icons.notifications_none,
              'Notifications',
            ),

            // Settings
            _item(
              Icons.settings_outlined,
              'Settings',
            ),

            const SizedBox(height: 15),

            // Log out
            SecondaryButton(
              text: 'Log out',
              onPressed: () {
                CurrentUserService.instance.clearUser();

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WelcomePage(),
                  ),
                  (_) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(
    IconData icon,
    String title, {
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: ListTile(
          onTap: onTap,
          leading: Icon(
            icon,
            color: AppColors.orange,
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}