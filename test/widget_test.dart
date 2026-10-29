import 'package:flutter_test/flutter_test.dart';
import 'package:kanban_workspace/app.dart';
import 'package:kanban_workspace/injection_container.dart';

void main() {
  setUpAll(configureDependencies);

  testWidgets('shows the collaborative roadmap board', (tester) async {
    await tester.pumpWidget(const KanbanApp());
    await tester.pumpAndSettle();

    expect(find.text('Product roadmap'), findsOneWidget);
    expect(find.text('Backlog'), findsOneWidget);
    expect(find.text('In progress'), findsOneWidget);
    expect(find.text('Design system refresh'), findsOneWidget);
    expect(find.text('New task'), findsOneWidget);
  });
}
