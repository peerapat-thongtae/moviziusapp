import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moviziusapp/core/widgets/tag.dart';

void main() {
  testWidgets('renders its label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Tag(label: 'Action'))),
    );

    expect(find.text('Action'), findsOneWidget);
  });

  testWidgets('uses the provided background and foreground colors', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Tag(
            label: 'Drama',
            backgroundColor: Colors.red,
            foregroundColor: Colors.yellow,
          ),
        ),
      ),
    );

    final container = tester.widget<Container>(find.byType(Container));
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, Colors.red);

    final text = tester.widget<Text>(find.text('Drama'));
    expect(text.style?.color, Colors.yellow);
  });
}
