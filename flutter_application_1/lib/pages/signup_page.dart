import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_theme.dart';
import '../widgets/app_buttons.dart';
import '../services/api_service.dart';
import '../services/current_user_service.dart';
import '../services/notification_service.dart';
import '../models/user.dart' as app_user;
import 'home_shell.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final username = TextEditingController();
  final name = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  final email = TextEditingController();

  bool hidePassword = true;
  bool hideConfirm = true;
  bool loading = false;

  @override
  void dispose() {
    username.dispose();
    name.dispose();
    phone.dispose();
    password.dispose();
    confirm.dispose();
    email.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (username.text.trim().isEmpty ||
        name.text.trim().isEmpty ||
        phone.text.trim().isEmpty ||
        password.text.isEmpty ||
        confirm.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกข้อมูลให้ครบ'),
        ),
      );
      return;
    }

    if (password.text != confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('รหัสผ่านไม่ตรงกัน'),
        ),
      );
      return;
    }

    if (username.text.trim().length < 3 || password.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username ต้องมีอย่างน้อย 3 ตัว และรหัสผ่านอย่างน้อย 8 ตัว')),
      );
      return;
    }

    if (phone.text.trim().length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกเบอร์โทรศัพท์ให้ครบ 10 หลัก')),
      );
      return;
    }

    await _completeSignUp();
  }

  Future<void> _completeSignUp() async {
    setState(() {
      loading = true;
    });

    try {
      final result = await ApiService.register(
        username: username.text.trim(),
        fullname: name.text.trim(),
        phone: phone.text.trim(),
        password: password.text,
        email: email.text.trim().isEmpty ? null : email.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      final newUser = app_user.User.fromJson(
        Map<String, dynamic>.from(result['data'] as Map),
      );
      CurrentUserService.instance.setUser(newUser);
      await NotificationService.registerCurrentDevice();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeShell()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
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
              children: [
                const Text(
                  'Create account',
                  style: TextStyle(
                    color: AppColors.orange,
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 28),

                TextField(
                  controller: username,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    hintText: 'Username',
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    hintText: 'ชื่อ - นามสกุล',
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: phone,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 10,
                  decoration: const InputDecoration(
                    hintText: 'เบอร์โทรศัพท์',
                    counterText: '',
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'อีเมล (ไม่บังคับ)',
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: password,
                  obscureText: hidePassword,
                  decoration: InputDecoration(
                    hintText: 'รหัสผ่าน',
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          hidePassword = !hidePassword;
                        });
                      },
                      icon: Icon(
                        hidePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: confirm,
                  obscureText: hideConfirm,
                  decoration: InputDecoration(
                    hintText: 'ยืนยันรหัสผ่าน',
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          hideConfirm = !hideConfirm;
                        });
                      },
                      icon: Icon(
                        hideConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                PrimaryButton(
                  text: loading ? 'กำลังสมัครสมาชิก...' : 'สมัครสมาชิก',
                  onPressed: loading ? null : _signUp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
