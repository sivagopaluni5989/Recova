import 'package:flutter_test/flutter_test.dart';
import 'package:smart_media_recovery/app.dart';

void main() {

  testWidgets('Smart Media Recovery app loads',
      (WidgetTester tester) async {

    await tester.pumpWidget(
      const SmartMediaRecoveryApp(),
    );

    expect(
      find.text('Smart Media Recovery'),
      findsOneWidget,
    );

  });

}
