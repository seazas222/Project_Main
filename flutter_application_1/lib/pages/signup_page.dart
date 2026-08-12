import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../widgets/app_buttons.dart';
import '../services/api_service.dart';

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

    setState(() {
      loading = true;
    });

    try {
      final result = await ApiService.register(
        username: username.text.trim(),
        fullname: name.text.trim(),
        phone: phone.text.trim(),
        password: password.text,
      );

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ?? 'สมัครสมาชิกสำเร็จ',
          ),
        ),
      );

      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
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
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'เบอร์โทรศัพท์',
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
                  text: loading ? 'Creating...' : 'Create account',
                  onPressed: loading ? null : _signUp,
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: loading ? null : () {},
                    icon: Image.asset(
                      'assets/google_icon.webp',
                      width: 20,
                      height: 20,
                    ),
                    label: const Text('Continue with Google'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      side: const BorderSide(
                        color: AppColors.border,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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