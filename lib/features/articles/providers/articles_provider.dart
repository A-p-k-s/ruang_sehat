import 'package:flutter/material.dart';
import 'package:ruang_sehat/features/articles/data/articles_model.dart';
import 'package:ruang_sehat/features/articles/data/articles_services.dart';
import 'dart:io';

class ArticlesProvider with ChangeNotifier {
  List<ArticlesModel> _articles = [];
  List<ArticlesModel> _myArticles = [];
  ArticlesModel? _detailArticle;
  List<ArticlesModel> _featuredArticles = [];

  bool _isLoading = false;
  String? _errorMessage;
  String? _succesMessage;
  bool _isFetchingMore = false;
  int _currentPage = 1;
  bool _hasNextPage = true;

  // Getters
  List<ArticlesModel> get articles => _articles;
  List<ArticlesModel> get myArticles => _myArticles;
  ArticlesModel? get detailArticle => _detailArticle;
  List<ArticlesModel> get featuredArticles => _featuredArticles;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get succesMessage => _succesMessage;
  bool get isFetchingMore => _isFetchingMore;
  bool get hasNextPage => _hasNextPage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _resetMessage() {
    _errorMessage = null;
    _succesMessage = null;
  }

  void _setFetchingMore(bool value) {
    _isFetchingMore = value;
    notifyListeners();
  }

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('FormatException')) {
      return 'Response server tidak valid (bukan JSON)';
    }
    return msg.replaceAll('Exception: ', '').replaceAll('Exception :', "");
  }

  Future<void> getArticles({bool isRefresh = true}) async {
    if (isRefresh) {
      _currentPage = 1;
      _hasNextPage = true;
      _setLoading(true);
    } else {
      if (!_hasNextPage || _isFetchingMore) return;
      _setFetchingMore(true);
    }
    
    _resetMessage();

    try {
      final result = await ArticlesServices.getArticles(
        page: _currentPage,
        limit: 5,
      );
      
      final List<ArticlesModel> data = result['articles'];
      final int totalPages = result['totalPages'];

      if (isRefresh) {
        _articles = data;
        
        // Set featured articles dari halaman terakhir
        if (totalPages > 1) {
          final lastPageData = await ArticlesServices.getArticles(
            page: totalPages,
            limit: 5,
          );
          final List<ArticlesModel> lastPageArticles = lastPageData['articles'];
          _featuredArticles = lastPageArticles;
        } else {
          _featuredArticles = data.length > 5 
              ? data.sublist(data.length - 5) 
              : List.from(data);
        }
      } else {
        _articles.addAll(data);
      }
      
      // Update pagination status
      if (data.isEmpty || data.length < 5) {
        _hasNextPage = false;
      } else {
        _currentPage++;
      }
      
      if (data.isEmpty && isRefresh) {
        _errorMessage = "Data artikel kosong";
      }
    } catch (err) {
      debugPrint('GET ARTICLES ERROR: $err');
      _errorMessage = _parseError(err);
      if (isRefresh) _articles = [];
    } finally {
      if (isRefresh) {
        _setLoading(false);
      } else {
        _setFetchingMore(false);
      }
    }
  }

  Future<void> getMyArticles() async {
    _setLoading(true);
    _resetMessage();

    try {
      final result = await ArticlesServices.getMyArticles();
      _myArticles = result;

      if (result.isEmpty) {
        _succesMessage = "Belum ada artikel";
      }
    } catch (err) {
      debugPrint('GET MY ARTICLES ERROR: $err');
      _errorMessage = _parseError(err);
      _myArticles = [];
    } finally {
      _setLoading(false);
    }
  }

  Future<void> getDetailArticle(String id) async {
    _setLoading(true);
    _resetMessage();

    try {
      final result = await ArticlesServices.getDetailArticle(id);
      _detailArticle = result;
    } catch (e) {
      debugPrint('GET DETAIL ERROR: $e');
      _errorMessage = _parseError(e);
      _detailArticle = null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createArticle({
    required String title,
    required String category,
    required String description,
    required String imagePath,
  }) async {
    _setLoading(true);
    _resetMessage();

    if (imagePath.isEmpty) {
      _errorMessage = 'Gambar tidak boleh kosong';
      _setLoading(false);
      notifyListeners();
      return false;
    }

    final File imageFile = File(imagePath);
    if (!await imageFile.exists()) {
      _errorMessage = 'File gambar tidak ditemukan';
      _setLoading(false);
      notifyListeners();
      return false;
    }

    try {
      await ArticlesServices.createArtikel(
        image: imageFile,
        title: title,
        description: description,
        category: category,
      );
      
      _succesMessage = 'Artikel berhasil dibuat';
      await getMyArticles();
      await getArticles();
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('CREATE ERROR: $e');
      _errorMessage = _parseError(e);
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateArticle(
    String id, {
    required String title,
    required String category,
    required String description,
    String? imagePath,
  }) async {
    _setLoading(true);
    _resetMessage();

    try {
      ArticlesModel result;
      
      if (imagePath != null && imagePath.isNotEmpty && !imagePath.startsWith('http')) {
        final File imageFile = File(imagePath);
        if (!await imageFile.exists()) {
          _errorMessage = 'File gambar tidak ditemukan';
          _setLoading(false);
          notifyListeners();
          return false;
        }
        
        result = await ArticlesServices.updateArticleWithImage(
          id,
          image: imageFile,
          title: title,
          description: description,
          category: category,
        );
      } else {
        result = await ArticlesServices.updateArticle(
          id,
          title: title,
          category: category,
          description: description,
        );
      }
      
      _succesMessage = 'Artikel berhasil diupdate';

      final articleIndex = _articles.indexWhere((a) => a.id == id);
      if (articleIndex != -1) _articles[articleIndex] = result;

      final myArticleIndex = _myArticles.indexWhere((a) => a.id == id);
      if (myArticleIndex != -1) _myArticles[myArticleIndex] = result;

      if (_detailArticle?.id == id) {
        _detailArticle = result;
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('UPDATE ERROR: $e');
      _errorMessage = _parseError(e);
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteArticle(String id) async {
    _setLoading(true);
    _resetMessage();

    try {
      await ArticlesServices.deleteArticle(id);
      _succesMessage = 'Artikel berhasil dihapus';
      _articles.removeWhere((a) => a.id == id);
      _myArticles.removeWhere((a) => a.id == id);
      if (_detailArticle?.id == id) _detailArticle = null;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('DELETE ERROR: $e');
      _errorMessage = _parseError(e);
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }
}