import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ruang_sehat/features/themes/app_colors.dart';
import 'package:ruang_sehat/home/widgets/featured_card.dart';
import 'package:ruang_sehat/home/widgets/recomended_card.dart';
import 'package:ruang_sehat/features/articles/providers/articles_provider.dart';
import 'package:ruang_sehat/providers/auth_provider.dart';
import 'package:ruang_sehat/features/auth/presentation/screens/auth_screens.dart';
import 'package:ruang_sehat/utils/snackbar_helper.dart';
import 'package:ruang_sehat/widgets/modal_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const String routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ArticlesProvider>().getArticles();
      context.read<AuthProvider>().getProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userName = authProvider.user?.name ?? 'User';

    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 40,
                  height: 40,
                  color: Colors.grey[300],
                  child: const Icon(Icons.person, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi, $userName',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const Text(
                    'How are you feeling today?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const Spacer(),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, size: 28),
                offset: const Offset(0, 50),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                color: AppColors.secondary,
                onSelected: (value) {
                  ModalBottomSheet.show(
                    context: context,
                    label: 'Are you sure want to log out?',
                    isLogout: true,
                    onConfirm: () async {
                      final authProvider = context.read<AuthProvider>();
                      await authProvider.logout();

                      if (authProvider.errorMessage == null) {
                        SnackbarHelper.show(
                          context,
                          authProvider.successMessage ?? 'Logout success',
                          isError: false,
                        );
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            AuthScreen.routeName,
                            (route) => false,
                          );
                        }
                      } else {
                        SnackbarHelper.show(
                          context,
                          authProvider.errorMessage ?? 'Logout failed',
                          isError: true,
                        );
                      }
                    },
                  );
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'log out',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: AppColors.error),
                        SizedBox(width: 8),
                        Text(
                          'Log out',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      // PERBAIKAN: Gunakan CustomScrollView agar semua card muncul
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsetsGeometry.fromLTRB(24, 8, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Featured",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'See More > ',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.hintText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 24, bottom: 16),
                  child: FeaturedCard(),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Recommended for you",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "See more > ",
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.hintText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
          // Recommended section - menggunakan SliverToBoxAdapter agar semua card muncul
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(
              child: RecomendedCard(),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ),
    );
  }
}