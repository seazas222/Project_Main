import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/current_user_service.dart';

class PersonalInformationPage extends StatefulWidget {
  const PersonalInformationPage({super.key});

  @override
  State<PersonalInformationPage> createState() =>
      _PersonalInformationPageState();
}

class _PersonalInformationPageState
    extends State<PersonalInformationPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullnameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final user = CurrentUserService.instance.user;

    _fullnameController = TextEditingController(
      text: user?.fullname ?? '',
    );

    _phoneController = TextEditingController(
      text: user?.phone ?? '',
    );

    _emailController = TextEditingController(
      text: user?.email ?? '',
    );
  }

  @override
  void dispose() {
    _fullnameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = CurrentUserService.instance.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่พบข้อมูลผู้ใช้งาน'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final User updatedUser = await ApiService.updateUser(
        userId: user.userId,
        fullname: _fullnameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
      );

      // อัปเดตข้อมูลผู้ใช้ที่เก็บไว้ในแอป
      CurrentUserService.instance.setUser(updatedUser);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('บันทึกข้อมูลสำเร็จ'),
        ),
      );

      // กลับไปหน้า Profile
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'บันทึกข้อมูลไม่สำเร็จ: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back),
        ),

        title: const Text(
          'Personal information',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: Form(
        key: _formKey,

        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            30,
          ),

          children: [
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

                  const SizedBox(height: 20),

                  _textField(
                    controller: _fullnameController,
                    icon: Icons.badge_outlined,
                    label: 'Full name',
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'กรุณากรอกชื่อ';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  _readOnlyField(
                    icon: Icons.person_outline,
                    label: 'Username',
                    value:
                        CurrentUserService.instance.user?.username ??
                            '',
                  ),

                  const SizedBox(height: 12),

                  _textField(
                    controller: _phoneController,
                    icon: Icons.phone_outlined,
                    label: 'Phone number',
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 12),

                  _textField(
                    controller: _emailController,
                    icon: Icons.email_outlined,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    height: 50,

                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,

                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,

                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                      ),

                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),

      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,

        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: AppColors.orange,
            size: 22,
          ),

          labelText: label,

          labelStyle: const TextStyle(
            fontSize: 12,
          ),

          border: InputBorder.none,

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _readOnlyField({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),

      child: TextFormField(
        initialValue: value,
        readOnly: true,

        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: AppColors.orange,
            size: 22,
          ),

          labelText: label,

          labelStyle: const TextStyle(
            fontSize: 12,
          ),

          border: InputBorder.none,

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}