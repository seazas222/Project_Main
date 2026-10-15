import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../widgets/app_buttons.dart';
import '../services/current_user_service.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

import 'welcome_page.dart';
import 'personal_information_page.dart';
import 'reservation_history_page.dart';
import 'order_history_page.dart';
import 'restaurant_stats_page.dart';
import 'notification_inbox_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _imageFailed = false;
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CurrentUserService.instance,
      builder: (context, _) {
      final user = CurrentUserService.instance.user;
      final imagePath = user?.userImage;
      final imageUrl = imagePath == null || imagePath.isEmpty
          ? null
          : imagePath.startsWith('http')
              ? imagePath
              : '${ApiService.baseUrl}/users/${user!.userId}/profile-image?v=${Uri.encodeComponent(imagePath)}';
      return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 25, 20, 30),
          children: [
            const Text(
              'โปรไฟล์',
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
                  ClipOval(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: imageUrl != null && !_imageFailed
                          ? Image.network(
                              imageUrl,
                              key: ValueKey(imageUrl),
                              headers: imageUrl.startsWith(ApiService.baseUrl)
                                  ? ApiService.authHeaders
                                  : null,
                              width: 86,
                              height: 86,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted && !_imageFailed) {
                                    setState(() => _imageFailed = true);
                                  }
                                });
                                return _defaultAvatar();
                              },
                            )
                          : _defaultAvatar(),
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

            _item(
              Icons.person_outline,
              'ข้อมูลส่วนตัว',
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

            _item(
              Icons.history,
              'ประวัติการจอง',
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

            _item(
              Icons.notifications_none,
              'การแจ้งเตือน',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationInboxPage())),
            ),

            _item(
              Icons.receipt_long_outlined,
              'ประวัติการสั่งอาหาร',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryPage())),
            ),

            _item(
              Icons.bar_chart_outlined,
              'สถิติเมนูยอดนิยม',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RestaurantStatsPage())),
            ),

            const _NotificationPreferenceControl(),

            const SizedBox(height: 15),

            SecondaryButton(
              text: 'ออกจากระบบ',
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
      },
    );
  }

  Widget _defaultAvatar() => Container(
        key: const ValueKey('profile-avatar-placeholder'),
        width: 86,
        height: 86,
        color: AppColors.orangeLight,
        alignment: Alignment.center,
        child: const Icon(Icons.person, size: 50, color: AppColors.orange),
      );

  Widget _item(
    IconData icon,
    String title, {
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
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

class _NotificationPreferenceControl extends StatefulWidget {
  const _NotificationPreferenceControl();

  @override
  State<_NotificationPreferenceControl> createState() =>
      _NotificationPreferenceControlState();
}

class _NotificationPreferenceControlState
    extends State<_NotificationPreferenceControl> {
  bool enabled = true;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    try {
      final value = await ApiService.getNotificationPreference();
      if (mounted) setState(() { enabled = value; loading = false; });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _setEnabled(bool value) async {
    final previousValue = enabled;
    setState(() { enabled = value; loading = true; });
    try {
      final savedValue = await ApiService.setNotificationPreference(value);
      // Saving the preference is the switch's main action. Push setup can be
      // unavailable (for example on web), so it must not revert that setting.
      if (savedValue) {
        try {
          await NotificationService.registerCurrentDevice();
        } catch (_) {}
      }
      if (mounted) {
        setState(() { enabled = savedValue; loading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(savedValue ? 'เปิดการแจ้งเตือนแล้ว' : 'ปิดการแจ้งเตือนแล้ว')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() { enabled = previousValue; loading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          const Icon(Icons.notifications_none, color: AppColors.orange, size: 21),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('การแจ้งเตือน', style: TextStyle(fontSize: 13)),
              Text('เปิด/ปิดการแจ้งเตือนจากร้าน', style: TextStyle(fontSize: 10, color: AppColors.grey)),
            ]),
          ),
          if (loading)
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          else
            Switch.adaptive(
              value: enabled,
              onChanged: _setEnabled,
              activeThumbColor: AppColors.orange,
            ),
        ]),
      );
}
