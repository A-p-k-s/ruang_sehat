import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:ruang_sehat/providers/auth_provider.dart';
import 'package:ruang_sehat/features/themes/app_colors.dart';
import 'package:ruang_sehat/utils/snackbar_helper.dart';
import 'package:ruang_sehat/widgets/bottom_navbar.dart';

class AuthForm extends StatefulWidget {
  final bool isLogin;
  final VoidCallback? onSwitchToLogin;

  const AuthForm({super.key, required this.isLogin, this.onSwitchToLogin});

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isObscure = true;
  bool _rememberMe = false;

  Future<void> handleSubmit(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final username = usernameController.text.trim();
    final password = passwordController.text;
    final name = nameController.text.trim();

    // Validasi input
    if (username.isEmpty) {
      SnackbarHelper.show(context, 'Username wajib diisi', isError: true);
      return;
    }

    // Validasi username: hanya huruf dan angka
    final usernameRegex = RegExp(r'^[a-zA-Z0-9]+$');
    if (!usernameRegex.hasMatch(username)) {
      SnackbarHelper.show(
        context,
        'Username hanya boleh huruf dan angka (tanpa spasi/simbol)',
        isError: true,
      );
      return;
    }

    if (password.isEmpty) {
      SnackbarHelper.show(context, 'Password wajib diisi', isError: true);
      return;
    }

    if (password.length < 6) {
      SnackbarHelper.show(
        context,
        'Password minimal 6 karakter',
        isError: true,
      );
      return;
    }

    if (!widget.isLogin && name.isEmpty) {
      SnackbarHelper.show(context, 'Nama wajib diisi', isError: true);
      return;
    }

    bool success = false;

    if (widget.isLogin) {
      success = await authProvider.login(username, password);
    } else {
      success = await authProvider.register(name, username, password);
    }

    if (!context.mounted) return;

    if (success) {
      SnackbarHelper.show(
        context,
        authProvider.successMessage ??
            (widget.isLogin ? 'Login berhasil!' : 'Registrasi berhasil!'),
      );

      if (widget.isLogin) {
        // Login sukses -> pindah ke HomeScreen
        Navigator.pushReplacementNamed(
          context,
          BottomNavbar.routeName,
          arguments: 0,
        );
      } else {
        // Register sukses -> pindah ke form login
        if (widget.onSwitchToLogin != null) {
          widget.onSwitchToLogin!();
        }
        // Kosongkan form
        nameController.clear();
        usernameController.clear();
        passwordController.clear();
      }
    } else {
      SnackbarHelper.show(
        context,
        authProvider.errorMessage ?? 'Terjadi kesalahan',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Field Name (hanya untuk register)
        if (!widget.isLogin) ...[
          const SizedBox(height: 18),
          const Text(
            'Name',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: nameController,
            enabled: !authProvider.isLoading,
            decoration: InputDecoration(
              hintText: 'Enter Your Name',
              hintStyle: TextStyle(color: AppColors.hintText),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 15.0,
                horizontal: 14.0,
              ),
            ),
          ),
        ],
        // Field Username
        const SizedBox(height: 18),
        const Text(
          'Username',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: usernameController,
          enabled: !authProvider.isLoading,
          decoration: InputDecoration(
            hintText: 'Enter Your Username',
            hintStyle: TextStyle(color: AppColors.hintText),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 15.0,
              horizontal: 14.0,
            ),
          ),
        ),
        // Field Password
        const SizedBox(height: 18),
        const Text(
          'Password',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: passwordController,
          obscureText: _isObscure,
          enabled: !authProvider.isLoading,
          decoration: InputDecoration(
            hintText: 'Enter Your Password',
            hintStyle: TextStyle(color: AppColors.hintText),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 15.0,
              horizontal: 14.0,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _isObscure ? Icons.visibility_off : Icons.visibility,
                color: AppColors.hintText,
              ),
              onPressed: () {
                setState(() {
                  _isObscure = !_isObscure;
                });
              },
            ),
          ),
        ),
        // Button Login/Register
        const SizedBox(height: 18),
        ElevatedButton(
          onPressed: authProvider.isLoading
              ? null
              : () => handleSubmit(context),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: authProvider.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  widget.isLogin ? 'Login' : 'Register',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        // Remember Me & Forgot Password (hanya untuk login)
        if (widget.isLogin) ...[
          const SizedBox(height: 18),
          Row(
            children: [
              Checkbox(
                value: _rememberMe,
                onChanged: authProvider.isLoading
                    ? null
                    : (value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                activeColor: AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                side: const BorderSide(color: AppColors.hintText, width: 2),
              ),
              const Text('Remember me', style: TextStyle(fontSize: 14)),
              const Spacer(),
              TextButton(
                onPressed: authProvider.isLoading
                    ? null
                    : () {
                        // Forgot Password functionality
                        SnackbarHelper.show(
                          context,
                          'Fitur akan segera hadir',
                          isError: false,
                        );
                      },
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(color: AppColors.primary, fontSize: 14),
                ),
              ),
            ],
          ),
          // Divider
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(child: Divider(thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Or Log in with',
                  style: TextStyle(color: AppColors.hintText, fontSize: 12),
                ),
              ),
              const Expanded(child: Divider(thickness: 1)),
            ],
          ),
          // Google Icon
          const SizedBox(height: 18),
          Center(
            child: GestureDetector(
              onTap: authProvider.isLoading
                  ? null
                  : () {
                      SnackbarHelper.show(
                        context,
                        'Fitur akan segera hadir',
                        isError: false,
                      );
                    },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SvgPicture.asset(
                  'assets/icons/google.svg',
                  height: 24,
                  width: 24,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],
      ],
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
