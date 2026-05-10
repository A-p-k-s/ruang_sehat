import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ruang_sehat/features/articles/data/articles_model.dart';
import 'package:ruang_sehat/features/articles/providers/articles_provider.dart';
import 'package:ruang_sehat/features/themes/app_colors.dart';
import 'package:ruang_sehat/utils/snackbar_helper.dart';
import 'package:ruang_sehat/features/articles/presentation/widgets/image_input.dart';
import 'package:image_picker/image_picker.dart';

class FormArticleScreen extends StatefulWidget {
  const FormArticleScreen({super.key});

  static const routeName = '/form-articles';

  @override
  State<FormArticleScreen> createState() => _FormArticleScreenState();
}

class _FormArticleScreenState extends State<FormArticleScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  bool _isLoading = false;
  String? imagePath;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        imagePath = pickedFile.path;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ?? {};
    final isEdit = args['isEdit'] ?? false;
    final article = args['article'] as ArticlesModel?;

    if (isEdit && article != null) {
      titleController.text = article.title;
      categoryController.text = article.category;
      descriptionController.text = article.description;
      // Set imagePath untuk menampilkan gambar yang sudah ada
      if (article.image.isNotEmpty) {
        imagePath = article.image;
      }
    }
  }

  Future<void> _handleSubmit(bool isEdit, String? articleId) async {
    // Validasi form
    if (titleController.text.trim().isEmpty) {
      SnackbarHelper.show(context, 'Title wajib diisi', isError: true);
      return;
    }
    if (categoryController.text.trim().isEmpty) {
      SnackbarHelper.show(context, 'Category wajib diisi', isError: true);
      return;
    }
    if (descriptionController.text.trim().isEmpty) {
      SnackbarHelper.show(context, 'Description wajib diisi', isError: true);
      return;
    }

    // Validasi gambar hanya untuk create artikel
    if (!isEdit && (imagePath == null || imagePath!.isEmpty)) {
      SnackbarHelper.show(context, 'Gambar wajib dipilih', isError: true);
      return;
    }

    final provider = Provider.of<ArticlesProvider>(context, listen: false);
    bool success;

    setState(() => _isLoading = true);

    if (isEdit && articleId != null) {
      // Update artikel dengan imagePath (bisa null jika tidak mengubah gambar)
      success = await provider.updateArticle(
        articleId,
        title: titleController.text.trim(),
        category: categoryController.text.trim(),
        description: descriptionController.text.trim(),
        imagePath: imagePath,
      );
    } else {
      // Create artikel baru dengan imagePath yang wajib ada
      success = await provider.createArticle(
        title: titleController.text.trim(),
        category: categoryController.text.trim(),
        description: descriptionController.text.trim(),
        imagePath: imagePath!,
      );
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      SnackbarHelper.show(
        context,
        provider.succesMessage ?? 'Operasi berhasil',
      );
      Navigator.pop(context);
    } else {
      SnackbarHelper.show(
        context,
        provider.errorMessage ?? 'Terjadi kesalahan',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ?? {};
    final isEdit = args['isEdit'] ?? false;
    final article = args['article'] as ArticlesModel?;
    final articleId = article?.id;

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.backgroundGrey,
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            isEdit ? 'Update Artikel' : 'Create Artikel',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.backgroundGrey,
          leading: IconButton(
            padding: const EdgeInsets.only(left: 20),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              //image input
              ImageInput(
                onTap: _pickImage, 
                imagePath: imagePath,
              ),
              const SizedBox(height: 20),
              // Label Form Title
              const Text(
                'Title',
                style: TextStyle(
                  color: Color(0XFF4D4637),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              TextFormField(
                controller: titleController,
                decoration: _inputDecoration('Enter the article Title'),
              ),
              const SizedBox(height: 16),
              // Label Form Category
              const Text(
                'Category',
                style: TextStyle(
                  color: Color(0XFF4D4637),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              TextFormField(
                controller: categoryController,
                decoration: _inputDecoration('Enter the Article Category'),
              ),
              const SizedBox(height: 16),
              // Label Form Description
              const Text(
                'Description',
                style: TextStyle(
                  color: Color(0XFF4D4637),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              TextFormField(
                maxLines: 8,
                minLines: 8,
                keyboardType: TextInputType.multiline,
                controller: descriptionController,
                decoration: _inputDecoration('Enter the Article Description'),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : () => _handleSubmit(isEdit, articleId),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    isEdit ? "Update" : "Create",
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      fillColor: AppColors.secondary,
      filled: true,
      hintText: hint,
      isDense: true,
      hintStyle: const TextStyle(
        color: AppColors.hintText,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    categoryController.dispose();
    super.dispose();
  }
}