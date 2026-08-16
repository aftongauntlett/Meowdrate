import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meowdrate/app.dart';

void main() {
  testWidgets('Home screen shows the log-a-drink action', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: MeowdrateApp()));
    await tester.pump();

    expect(find.text('Meowdrate!'), findsOneWidget);
  });
}
