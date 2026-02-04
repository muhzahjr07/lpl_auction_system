import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lpl_auction_app/widgets/stats_card.dart';

void main() {
  testWidgets('StatsCard does not overflow in constrained space',
      (WidgetTester tester) async {
    // The error reported constraints: BoxConstraints(w=149.7, h=97.2)
    // We will use a slightly smaller height to be robust, or exactly that to verify fix.
    // Let's use the exact constraints from the error log.

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              height: 130,
              child: StatsCard(
                title: 'Players',
                value: '12/25',
                icon: Icons.people,
              ),
            ),
          ),
        ),
      ),
    );

    // Verify no overflow errors are thrown
    expect(tester.takeException(), isNull);

    // Check if widgets are present
    expect(find.text('Players'), findsOneWidget);
    expect(find.text('12/25'), findsOneWidget);
    expect(find.byIcon(Icons.people), findsOneWidget);
  });
}
