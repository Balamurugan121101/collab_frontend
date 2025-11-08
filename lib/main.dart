import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/environment_config.dart';
import 'core/constants/app_colors.dart';
import 'services/grpc/auth_service.dart';
import 'services/storage/secure_storage_service.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EnvironmentConfig.load(Environment.dev);

  // Initialize services
  final storageService = SecureStorageService();
  final authService = AuthService();

  runApp(
    MultiProvider(
      providers: [
        Provider<SecureStorageService>.value(value: storageService),
        Provider<AuthService>.value(value: authService),
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(authService, storageService)..loadSavedAuth(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Collab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
