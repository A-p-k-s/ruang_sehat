import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ruang_sehat/features/auth/presentation/screens/auth_screens.dart';
import 'package:ruang_sehat/features/splash/splashs_screen.dart';
import 'package:ruang_sehat/home/screens/home_screens.dart';
import 'package:ruang_sehat/providers/auth_provider.dart';
import 'package:ruang_sehat/widgets/bottom_navbar.dart';
import 'package:ruang_sehat/features/articles/providers/articles_provider.dart';
import 'package:ruang_sehat/features/articles/presentation/screens/detail_screen.dart';
import 'package:ruang_sehat/features/articles/presentation/screens/form_article_screen.dart';

/// Global navigator key untuk navigasi dari provider / service tanpa BuildContext.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: "assets/.env");
  } catch (e) {
    debugPrint('GAGAL LOAD .env: $e');
  }
  final apiUrl = dotenv.env['API_BASE_URL'] ?? '';
  if (apiUrl.isEmpty) {
    debugPrint('ERROR: API_BASE_URL kosong setelah load .env');
    debugPrint(
      'Pastikan file assets/.env berisi: API_BASE_URL=https://your-url.com',
    );
    debugPrint('Jalankan: flutter clean && flutter pub get && flutter run');
  } else {
    debugPrint('SUCCESS: API_BASE_URL = $apiUrl');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ArticlesProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Ruang Sehat',
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
        fontFamily: GoogleFonts.poppins().fontFamily,
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (context) => const SplashScreen(),
        AuthScreen.routeName: (context) => const AuthScreen(),
        HomeScreen.routeName: (context) => const HomeScreen(),
        BottomNavbar.routeName: (context) => const BottomNavbar(),
        DetailScreen.routeName: (context) => const DetailScreen(),
        FormArticleScreen.routeName: (context) => const FormArticleScreen(),
      },
    );
  }
}
