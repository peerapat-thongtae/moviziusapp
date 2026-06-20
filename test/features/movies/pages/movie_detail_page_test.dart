import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moviziusapp/features/movies/pages/movie_detail_page.dart';

void main() {
  testWidgets('shows the title and movie id', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MovieDetailPage(movieId: 27205, title: 'Inception'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Inception'), findsExactly(2)); // AppBar + body heading
    expect(find.text('Movie ID: 27205'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
  });

  testWidgets('falls back to a generic title when none is given', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: MovieDetailPage(movieId: 1)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Movie Details'), findsOneWidget);
    expect(find.text('Untitled'), findsOneWidget);
  });
}
