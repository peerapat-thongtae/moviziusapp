import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moviziusapp/core/router/widgets/animated_bottom_nav_bar.dart';

Widget _wrap(int currentIndex, ValueChanged<int> onTap) {
  return MaterialApp(
    home: Scaffold(
      bottomNavigationBar: AnimatedBottomNavBar(
        currentIndex: currentIndex,
        onTap: onTap,
      ),
    ),
  );
}

void main() {
  testWidgets('renders all four tab icons', (tester) async {
    await tester.pumpWidget(_wrap(0, (_) {}));

    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.search_outlined), findsOneWidget);
    expect(find.byIcon(Icons.explore_outlined), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
  });

  testWidgets('shows the filled icon only for the selected tab', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(2, (_) {}));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.explore), findsOneWidget);
    expect(find.byIcon(Icons.explore_outlined), findsNothing);
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
  });

  testWidgets('tapping a tab calls onTap with its index', (tester) async {
    int? tapped;
    await tester.pumpWidget(_wrap(0, (index) => tapped = index));

    await tester.tap(find.byIcon(Icons.explore_outlined));
    await tester.pump();

    expect(tapped, 2);
  });

  testWidgets('switching tabs animates without throwing', (tester) async {
    int currentIndex = 0;
    late StateSetter setState;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setter) {
          setState = setter;
          return _wrap(currentIndex, (index) => currentIndex = index);
        },
      ),
    );

    setState(() => currentIndex = 3);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
