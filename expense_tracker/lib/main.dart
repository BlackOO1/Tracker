import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/transaction_model.dart';
import 'models/category_model.dart';
import 'state/budget_provider.dart';
import 'constants/app_theme.dart';

import 'package:firebase_core/firebase_core.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/pin_screen.dart';
import 'services/auth_service.dart';
import 'ui/screens/sms_suggestions_screen.dart';
import 'ui/screens/admin_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Try initializing Firebase (if google-services.json is missing, catch it so app doesn't crash)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase not configured: $e');
  }

  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(TransactionModelAdapter());
  Hive.registerAdapter(CategoryModelAdapter());

  // Open Hive boxes
  await Hive.openBox<TransactionModel>('transactions');
  await Hive.openBox<CategoryModel>('categories');
  await Hive.openBox('settings');

  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()..init()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()..init()),
      ],
      child: Consumer<AuthService>(
        builder: (context, auth, _) {
          Widget startScreen;
          if (!auth.isLoggedIn) {
            startScreen = const LoginScreen();
          } else if (auth.isPinSet) {
            startScreen = const PinScreen();
          } else {
            startScreen = const PinScreen(); // PinScreen handles setup if not set
          }

          return MaterialApp(
            title: 'Budget Planner',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            home: startScreen,
            routes: {
              '/sms': (context) => const SmsSuggestionsScreen(),
              '/admin': (context) => const AdminScreen(),
            },
          );
        },
      ),
    );
  }
}
