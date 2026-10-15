import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../widgets/app_buttons.dart';
import '../services/api_service.dart';
import '../services/current_user_service.dart';
import '../services/notification_service.dart';
import 'signup_page.dart';
import 'home_shell.dart';
import 'admin_dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final username = TextEditingController();
  final password = TextEditingController();

  bool hide = true;
  bool loading = false;

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (loading) return;
    if (username.text.trim().isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอก Username และ Password')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      final user = await ApiService.login(
        username: username.text.trim(),
        password: password.text,
      );

      CurrentUserService.instance.setUser(user);
      await NotificationService.registerCurrentDevice();

      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login success')));

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => user.roleId == 1
              ? const AdminDashboardPage()
              : const HomeShell(),
        ),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(30, 5, 30, 30),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Log in',
                    style: TextStyle(
                      color: AppColors.orange,
                      fontSize: 31,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 35),

                const Text('Username', style: TextStyle(fontSize: 12)),

                const SizedBox(height: 7),

                TextField(
                  controller: username,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    hintText: 'กรุณาระบุ Username',
                  ),
                ),

                const SizedBox(height: 18),

                const Text('Password', style: TextStyle(fontSize: 12)),

                const SizedBox(height: 7),

                TextField(
                  controller: password,
                  obscureText: hide,
                  decoration: InputDecoration(
                    hintText: 'กรุณาระบุรหัสผ่าน',
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          hide = !hide;
                        });
                      },
                      icon: Icon(
                        hide
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                PrimaryButton(
                  text: loading ? 'กำลังเข้าสู่ระบบ...' : 'Log in',
                  onPressed: loading ? null : _login,
                ),

                const SizedBox(height: 22),

                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignUpPage()),
                      );
                    },
                    child: const Text.rich(
                      TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                        children: [
                          TextSpan(
                            text: 'Sign up',
                            style: TextStyle(
                              color: AppColors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
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
