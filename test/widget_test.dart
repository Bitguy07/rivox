import 'package:flutter_test/flutter_test.dart';
import 'package:rivox/app/app.dart';

void main() {
  testWidgets('App starts and shows splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const RivoxApp());
    expect(find.text('RIVOX'), findsOneWidget);
  });
}
