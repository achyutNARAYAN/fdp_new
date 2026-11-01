import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fdp/app.dart';

void main() {
  testWidgets('App initializes successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MithaiApp(),
      ),
    );

    // Initial frame renders login screen
    expect(find.text('Login or Register'), findsOneWidget);
    expect(find.textContaining('Mithai & More'), findsOneWidget);
  });
}
