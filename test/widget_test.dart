import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senai_ponto/screens/login_screen.dart';

void main() {
  testWidgets('exibe formulário de acesso do SENAI Ponto', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LoginScreen()),
    );

    expect(find.text('SENAI Ponto'), findsOneWidget);
    expect(find.text('NIF ou e-mail'), findsOneWidget);
    expect(find.text('ENTRAR'), findsOneWidget);
  });
}