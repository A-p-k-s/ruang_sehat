import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:ruang_sehat/features/auth/presentation/screens/auth_screens.dart';
import 'package:ruang_sehat/features/themes/app_colors.dart';
import 'package:ruang_sehat/providers/auth_provider.dart';
import 'package:ruang_sehat/widgets/bottom_navbar.dart';

class SplashScreen extends StatefulWidget {
  static const routeName = '/splash';
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _textController;
  late Animation<double> _textAnimation;

  @override
  void initState() {
    super.initState();

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(0, -10),
          end: const Offset(0, -0.5),
        ).animate(
          CurvedAnimation(parent: _iconController, curve: Curves.bounceOut),
        );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _textAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeInOut),
    );

    // Navigasi setelah animasi selesai
    _iconController.forward().then((_) {
      _textController.forward().then((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _checkAuthAndNavigate();
        });
      });
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    await authProvider.loadUser();
    final isLoggedIn = await authProvider.isLoggedIn();

    if (!mounted) return;

    if (isLoggedIn) {
      Navigator.pushReplacementNamed(context, BottomNavbar.routeName);
    } else {
      Navigator.pushReplacementNamed(context, AuthScreen.routeName);
    }
  }

  @override
  void dispose() {
    _iconController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SlideTransition(
                position: _slideAnimation,
                child: SvgPicture.asset(
                  'assets/icons/logo.svg',
                  height: 100,
                  width: 100,
                ),
              ),
              const SizedBox(height: 20),
              AnimatedBuilder(
                animation: _textAnimation,
                builder: (context, child) {
                  return ClipRect(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: _textAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: const Text(
                  'Ruang Sehat',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
