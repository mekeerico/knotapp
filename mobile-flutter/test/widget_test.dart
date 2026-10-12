import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knot_mobile/core/widgets/glass_card.dart';
import 'package:knot_mobile/core/widgets/gold_button.dart';

void main() {
  testWidgets('GlassCard and GoldButton render properly', (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GlassCard(
            child: GoldButton(
              text: 'Authenticate',
              onPressed: () {
                tapped = true;
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('Authenticate'), findsOneWidget);
    await tester.tap(find.text('Authenticate'));
    await tester.pump();
    expect(tapped, isTrue);
  });
}
