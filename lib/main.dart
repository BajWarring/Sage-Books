import 'package:firebase_core/firebase_core.dart'; 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sage/providers/theme_provider.dart';
import 'package:sage/screens/auth_wrapper.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sage/models/cashbook.dart';
import 'package:sage/models/entry.dart';

late SharedPreferences prefs;

// --- NEW: Color Palette ---
const Color foxOrange = Color(0xFFF15A24);
const Color foxOrangeDark = Color(0xFFD6450E);
const Color foxOrangeLight = Color(0xFFF57F42);
const Color peachBg = Color(0xFFFFF3EC);
const Color peachLight = Color(0xFFFFF0E6);
const Color cashGreen = Color(0xFF2EB872);
const Color cashGreenDark = Color(0xFF259A5E);
const Color cashRed = Color(0xFFE53935);
const Color textPrimary = Color(0xFF2C2C2C);
const Color textSecondary = Color(0xFF6E6E6E);

const MaterialColor foxOrangeSwatch = MaterialColor(
  0xFFF15A24,
  <int, Color>{
    50: Color(0xFFFDEAE3),
    100: Color(0xFFFCCDBD),
    200: Color(0xFFFAAD93),
    300: Color(0xFFF78E6A),
    400: Color(0xFFF5764A),
    500: foxOrange,
    600: Color(0xFFED5320),
    700: Color(0xFFE84A1B),
    800: Color(0xFFE44116),
    900: Color(0xFFDD300D),
  },
);

const MaterialColor sagePrimaryOrange = foxOrangeSwatch;
const Color sageAccentGreen = cashGreen;
const Color sageAccentRed = cashRed;
const Color sageScaffoldBg = peachBg;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- SAFE FIREBASE INIT ---
  try {
    await Firebase.initializeApp();
    debugPrint("Firebase Initialized");
  } catch (e) {
    debugPrint("Firebase failed to init (Check google-services.json): $e");
  }
  // --------------------------

  await Hive.initFlutter();
  Hive.registerAdapter(CashbookAdapter());
  Hive.registerAdapter(EntryAdapter());
  await Hive.openBox<Cashbook>('cashbooks');
  await Hive.openBox<Entry>('entries');

  prefs = await SharedPreferences.getInstance();
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider()..loadTheme(),
      child: const SageApp(),
    ),
  );
}

class SageApp extends StatelessWidget {
  const SageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Sage',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(seedColor: foxOrange),
            primarySwatch: foxOrangeSwatch,
            scaffoldBackgroundColor: sageScaffoldBg,
            appBarTheme: const AppBarTheme(
              backgroundColor: sageScaffoldBg,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              titleTextStyle: TextStyle(
                color: textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              iconTheme: IconThemeData(color: textPrimary),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                side: BorderSide(color: Colors.orange.shade100),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: peachLight,
              hintStyle: TextStyle(
                  color: foxOrangeLight.withAlpha((0.8 * 255).round()),
                  fontWeight: FontWeight.w500),
              prefixIconColor: foxOrange,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(99),
                borderSide: BorderSide(color: Colors.orange.shade100, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(99),
                borderSide: BorderSide(color: Colors.orange.shade100, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(99),
                borderSide: const BorderSide(color: foxOrange, width: 2),
              ),
            ),
            textTheme: Theme.of(context).textTheme.apply(
                  fontFamily: 'Inter',
                  bodyColor: textPrimary,
                  displayColor: textPrimary,
                ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: foxOrange,
              brightness: Brightness.dark,
            ),
            primarySwatch: foxOrangeSwatch,
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                side: BorderSide(color: Colors.grey.shade800),
              ),
            ),
          ),
          themeMode: themeProvider.themeMode,
          home: const AuthWrapper(),
        );
      },
    );
  }
}