import 'package:flutter/material.dart';
import 'package:ruang_sehat/features/themes/app_colors.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:ruang_sehat/features/articles/providers/articles_provider.dart';
import 'package:ruang_sehat/features/articles/presentation/widgets/container_detail.dart';
import 'package:ruang_sehat/features/articles/presentation/widgets/popup_menu.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key});

  static const routeName = 'detail-article';

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  static final String? _baseUrl = dotenv.env['API_BASE_URL'];
  bool isMenuOpen = false;
  bool isMe = false;
  String? articleId;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      if (args == null) return;

      setState(() {
        isMe = args['isMe'] ?? false;
        articleId = args['id']?.toString();
      });

      if (articleId != null) {
        context.read<ArticlesProvider>().getDetailArticle(articleId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ArticlesProvider>();

    if (provider.isLoading && provider.detailArticle == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (provider.detailArticle == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundGrey,
        body: SafeArea(
          child: Column(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios),
              ),
              const Expanded(child: Center(child: Text("Tidak ada artikel"))),
            ],
          ),
        ),
      );
    }

    final article = provider.detailArticle!;
    final imageUrl = article.image.startsWith('http')
        ? article.image
        : (_baseUrl != null ? '$_baseUrl/${article.image}' : article.image);

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      body: SafeArea(
        child: Stack(
          children: [
            // image article
            Image(
              image: NetworkImage(imageUrl),
              width: double.infinity,
              height: 500,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: double.infinity,
                height: 500,
                color: Colors.grey[300],
                child: const Icon(Icons.image_not_supported),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                height: 500,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [
                      AppColors.backgroundGrey.withOpacity(1.0),
                      AppColors.backgroundGrey.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            // back button
            Positioned(
              left: 20,
              right: 20,
              top: 0,
              bottom: 0,
              child: ContainerDetail(article: article),
            ),
            Positioned(
              top: 25,
              left: 25,
              right: 25,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.text.withOpacity(0.3),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 7),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: AppColors.secondary,
                          size: 25,
                        ),
                      ),
                    ),
                  ),
                  if (isMe && articleId != null)
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.text.withOpacity(0.3),
                      ),
                      child: IconButton(
                        onPressed: () {
                          setState(() => isMenuOpen = !isMenuOpen);
                        },
                        icon: const Icon(
                          Icons.more_horiz,
                          color: AppColors.secondary,
                          size: 25,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (isMenuOpen) ...[
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isMenuOpen = false;
                    });
                  },
                  child: Container(color: Colors.transparent),
                ),
              ),
              Positioned(
                top: 80,
                right: 20,
                child: PopupMenu(
                  article: article,
                  onDismiss: () => setState(() => isMenuOpen = false),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
