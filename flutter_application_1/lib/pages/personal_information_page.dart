import 'dart:convert';
import 'package:image_picker/image_picker.dart';
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
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  bool _isSaving = false;
  bool _uploadingImage = false;
  bool _imageFailed = false;

  @override
  void initState() {
    super.initState();

    final user = CurrentUserService.instance.user;

    _fullnameController = TextEditingController(
      text: user?.fullname ?? '',
    );
    _usernameController = TextEditingController(text: user?.username ?? '');

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
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _changeProfileImage() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 1200,
      );
      if (image == null || !mounted) return;
      setState(() => _uploadingImage = true);
      final bytes = await image.readAsBytes();
      if (bytes.length > 3 * 1024 * 1024) {
        throw Exception('รูปโปรไฟล์ต้องมีขนาดไม่เกิน 3 MB');
      }
      final mime = image.name.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
      final user = CurrentUserService.instance.user;
      if (user == null) throw Exception('กรุณาเข้าสู่ระบบใหม่');
      final updated = await ApiService.updateProfileImage(
        userId: user.userId,
        imageData: 'data:image/$mime;base64,${base64Encode(bytes)}',
      );
      CurrentUserService.instance.setUser(updated);
      if (!mounted) return;
      setState(() {
        _uploadingImage = false;
        _imageFailed = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เปลี่ยนรูปโปรไฟล์แล้ว')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _uploadingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
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
        username: _usernameController.text.trim(),
        fullname: _fullnameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
      );

      CurrentUserService.instance.setUser(updatedUser);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('บันทึกข้อมูลสำเร็จ'),
        ),
      );

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
    final user = CurrentUserService.instance.user;
    final imagePath = user?.userImage;
    final imageUrl = imagePath == null || imagePath.isEmpty
        ? null
        : imagePath.startsWith('http')
            ? imagePath
            : '${ApiService.baseUrl}/users/${user!.userId}/profile-image?v=${Uri.encodeComponent(imagePath)}';
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
          'ข้อมูลส่วนตัว',
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
                  InkWell(
                    onTap: _uploadingImage ? null : _changeProfileImage,
                    customBorder: const CircleBorder(),
                    child: Stack(
                      alignment: Alignment.center,
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
                        if (_uploadingImage)
                          Container(
                            width: 86,
                            height: 86,
                            decoration: const BoxDecoration(
                              color: Color(0x88000000),
                              shape: BoxShape.circle,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(30),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        else
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: AppColors.orange,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit, color: Colors.white, size: 15),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 5),
                  const Text('แตะรูปเพื่อเปลี่ยน', style: TextStyle(fontSize: 10, color: AppColors.grey)),

                  const SizedBox(height: 20),

                  _textField(
                    controller: _fullnameController,
                    icon: Icons.badge_outlined,
                    label: 'ชื่อ-นามสกุล',
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'กรุณากรอกชื่อ';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  _textField(
                    controller: _usernameController,
                    icon: Icons.person_outline,
                    label: 'ชื่อผู้ใช้',
                    validator: (value) {
                      final username = value?.trim() ?? '';
                      if (!RegExp(r'^[A-Za-z0-9_.-]{3,50}$').hasMatch(username)) return 'ใช้ a-z, 0-9, _, ., - ความยาว 3–50 ตัว';
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  _textField(
                    controller: _phoneController,
                    icon: Icons.phone_outlined,
                    label: 'เบอร์โทรศัพท์',
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 12),

                  _textField(
                    controller: _emailController,
                    icon: Icons.email_outlined,
                    label: 'อีเมล',
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
                              'บันทึก',
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

  Widget _defaultAvatar() => Container(
        key: const ValueKey('personal-information-avatar-placeholder'),
        width: 86,
        height: 86,
        color: AppColors.orangeLight,
        alignment: Alignment.center,
        child: const Icon(Icons.person, size: 50, color: AppColors.orange),
      );

}
