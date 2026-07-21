import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'game/game_controller.dart';
import 'screens/menu_screen.dart';
import 'utils/storage_service.dart';

void main() async {
  // Ensure Flutter engine is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation and full-screen immersive mode for arcade feel
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Initialize Storage Service
  final storageService = await StorageService.init();

  // Instantiate Game Controller
  final gameController = GameController(storageService: storageService);

  runApp(
    ChangeNotifierProvider<GameController>(
      create: (_) => gameController,
      child: const ZumaBoxApp(),
    ),
  );
}

class ZumaBoxApp extends StatelessWidget {
  const ZumaBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZumaBox',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.cyan,
        fontFamily: 'Inter', // Default fallback is clean sans-serif
        scaffoldBackgroundColor: const Color(0xFF0D0E15),
      ),
      home: const MenuScreen(),
    );
  }
}
