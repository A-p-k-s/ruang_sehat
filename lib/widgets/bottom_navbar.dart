// lib/bottom_navbar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ruang_sehat/home/screens/home_screens.dart';
import 'package:ruang_sehat/features/articles/presentation/screens/my_articles_screen.dart';
import 'package:ruang_sehat/features/auth/presentation/screens/edit_profile_screen.dart';
import 'package:ruang_sehat/features/themes/app_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ruang_sehat/features/articles/providers/articles_provider.dart';
import 'package:ruang_sehat/features/articles/data/articles_services.dart';
import 'package:ruang_sehat/providers/auth_provider.dart';

class BottomNavbar extends StatefulWidget {
  const BottomNavbar({super.key});

  static const routeName = "/bottom-navbar";

  @override
  State<BottomNavbar> createState() => _BottomNavbarState();
}

class _BottomNavbarState extends State<BottomNavbar> {
  int _selectedIndex = 0;
  bool _isFirstLoad = true;

  final List<Widget> _pages = const [
    HomeScreen(),
    MyArticlesScreen(),
    EditProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Wire callback untuk auto-logout saat token invalid
      ArticlesServices.onTokenInvalid = () {
        context.read<AuthProvider>().handleTokenInvalid();
      };

      // Load data
      context.read<ArticlesProvider>().getArticles();
      context.read<ArticlesProvider>().getMyArticles();
      context.read<AuthProvider>().getProfile();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_isFirstLoad) {
      _isFirstLoad = false;

      final arguments = ModalRoute.of(context)?.settings.arguments;

      if (arguments != null && arguments is int) {
        setState(() {
          _selectedIndex = arguments;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.secondary,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.hintText,
        currentIndex: _selectedIndex,
        iconSize: 20,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.house),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.newspaper),
            label: "My Articles",
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.user),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}