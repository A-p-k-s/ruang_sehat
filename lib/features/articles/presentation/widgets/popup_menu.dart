import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ruang_sehat/features/articles/data/articles_model.dart';
import 'package:ruang_sehat/features/articles/providers/articles_provider.dart';
import 'package:ruang_sehat/features/articles/presentation/screens/form_article_screen.dart';
import 'package:ruang_sehat/widgets/modal_bottom_sheet.dart';
import 'package:ruang_sehat/widgets/bottom_navbar.dart';
import 'package:ruang_sehat/utils/snackbar_helper.dart';

class PopupMenu extends StatelessWidget {
  final ArticlesModel article;
  final VoidCallback onDismiss;

  const PopupMenu({super.key, required this.article, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          width: 180,
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.3)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.white),
                title: const Text(
                  'Edit Article',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  onDismiss(); // tutup popup
                  Navigator.pushNamed(
                    context,
                    FormArticleScreen.routeName,
                    arguments: {'isEdit': true, 'article': article},
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete Article',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  onDismiss(); // tutup popup
                  
                  // Panggil ModalBottomSheet untuk delete
                  ModalBottomSheet.show(
                    context: context,
                    label: 'Are you sure you want to delete this article?',
                    isLogout: false,     // false karena ini delete
                    isDelete: true,      // true untuk menampilkan icon delete
                    onConfirm: () async {
                      final provider = Provider.of<ArticlesProvider>(
                        context,
                        listen: false,
                      );
                      
                      // Panggil method deleteArticle
                      final success = await provider.deleteArticle(article.id);
                      
                      if (context.mounted) {
                        if (success) {
                          // Jika berhasil hapus
                          SnackbarHelper.show(
                            context,
                            provider.succesMessage ?? 'Artikel berhasil dihapus',
                            isError: false,
                          );
                          
                          // Navigasi ke halaman My Articles (index 1)
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            BottomNavbar.routeName,
                            (route) => false,
                            arguments: 1, // args 1 untuk pindah ke tab My Articles
                          );
                        } else {
                          // Jika gagal hapus
                          SnackbarHelper.show(
                            context,
                            provider.errorMessage ?? 'Gagal menghapus artikel',
                            isError: true,
                          );
                        }
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}