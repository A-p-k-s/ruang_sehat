import 'package:flutter/material.dart';
import 'package:ruang_sehat/features/themes/app_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ruang_sehat/features/articles/presentation/widgets/my_articles_card.dart';
import 'package:ruang_sehat/features/articles/providers/articles_provider.dart';
import 'package:provider/provider.dart';
import 'package:ruang_sehat/features/articles/presentation/screens/form_article_screen.dart';

class MyArticlesScreen extends StatefulWidget {
  const MyArticlesScreen({super.key});

  @override
  State<MyArticlesScreen> createState() => _MyArticlesScreenState();
}

class _MyArticlesScreenState extends State<MyArticlesScreen> {
  Future<void> _loadMyArticles() async {
    await context.read<ArticlesProvider>().getMyArticles();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMyArticles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadMyArticles,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Consumer<ArticlesProvider>(
              builder: (context, provider, _) {
                // Loading state
                if (provider.isLoading && provider.myArticles.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Error state
                if (provider.errorMessage != null && !provider.isLoading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          provider.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.error),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadMyArticles,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "My Articles",
                            style: TextStyle(
                              fontSize: 20,
                              color: AppColors.hintText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            "${provider.myArticles.length} items",
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.hintText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    SliverToBoxAdapter(child: MyArticlesCard()),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            FormArticleScreen.routeName,
            arguments: {'isEdit': false},
          );
          if (result == true) {
            _loadMyArticles();
          }
        },
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        child: const Icon(LucideIcons.plus, color: Colors.white, size: 30),
      ),
    );
  }
}
