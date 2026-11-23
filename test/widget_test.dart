import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aula10_apis_crud/main.dart';

void main() {
  testWidgets('Renderiza AppBar e alterna barra de busca por titulo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const Aula10CrudRestApp());

    expect(find.text('CRUD API REST - Aula 10'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.search));
    await tester.pump();

    expect(find.byType(TextField), findsOneWidget);
  });
}
