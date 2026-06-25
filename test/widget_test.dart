import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zumabox/main.dart';
import 'package:zumabox/game/game_controller.dart';
import 'package:zumabox/utils/storage_service.dart';

void main() {
  testWidgets('ZumaBox main menu loads successfully', (WidgetTester tester) async {
    // Initialize SharedPreferences mock
    SharedPreferences.setMockInitialValues({});
    
    final storage = await StorageService.init();
    final controller = GameController(storageService: storage);

    await tester.pumpWidget(
      ChangeNotifierProvider<GameController>(
        create: (_) => controller,
        child: const ZumaBoxApp(),
      ),
    );

    // Wait for the UI layout frame
    await tester.pump();

    // Verify main menu elements exist
    expect(find.text('ZUMA'), findsOneWidget);
    expect(find.text('BOX'), findsOneWidget);
    expect(find.text('START GAME'), findsOneWidget);
    expect(find.text('SELECT LEVEL'), findsOneWidget);
  });
}
