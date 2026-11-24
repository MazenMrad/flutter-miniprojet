import 'package:absence_management/main.dart';
import 'package:absence_management/services/demo_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('demo login opens the student dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(AbsenceApp(repository: DemoAttendanceRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Assiduité'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'student@demo.school');
    await tester.enterText(find.byType(TextFormField).at(1), 'demo1234');
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    expect(find.text('Mon assiduité'), findsOneWidget);
    expect(find.text('Emploi du temps'), findsWidgets);
  });
}
