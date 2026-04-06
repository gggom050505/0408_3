import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gggom_tarot/widgets/making_notes_screen.dart';

void main() {
  testWidgets('메이킹 노트 화면이 에셋 문서를 불러와 표시', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await tester.pumpWidget(
      const MaterialApp(
        home: MakingNotesScreen(),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('공공곰타로덱'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
