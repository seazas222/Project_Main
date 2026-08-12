import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../widgets/app_buttons.dart';
import '../services/api_service.dart';
import '../services/current_user_service.dart';
import 'signup_page.dart';
import 'home_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final username = TextEditingController();
  final password = TextEditingController();

  bool hide = true;

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (username.text.trim().isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอก Username และ Password')),
      );
      return;
    }

    try {
      final user = await ApiService.login(
        username: username.text.trim(),
        password: password.text,
      );

      CurrentUserService.instance.setUser(user);

      debugPrint('LOGIN USER => id=${user.userId}, username=${user.username}');

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login success')));

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeShell()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;

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

                PrimaryButton(text: 'Log in', onPressed: _login),

                const SizedBox(height: 22),

                Center(
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(color: AppColors.orange, fontSize: 12),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'OR',
                        style: TextStyle(color: Colors.grey, fontSize: 11),
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
                    label: const Text('Log in with Google'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
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
